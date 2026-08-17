#!/bin/bash

# 1. Inicia o llama-server em segundo plano
echo "Iniciando o llama-server..."
llama-server -m /models/llama-3.2-3b.gguf --gpu-layers 99 --ctx-size 4096 --host 127.0.0.1 --port 8080 &

# 2. Aguarda até 30 segundos pela inicialização da API (com timeout para não travar o container)
echo "Aguardando o llama-server carregar na VRAM..."
count=0
while ! curl -s http://127.0.0.1:8080/v1/models > /dev/null; do
    sleep 2
    count=$((count+1))
    if [ $count -gt 15 ]; then
        echo "Aviso: llama-server está demorando para iniciar, subindo o Streamlit mesmo assim..."
        break
    fi
done

# 3. Identifica onde está o main.py e inicia o Streamlit
if [ -f "app/main.py" ]; then
    APP_PATH="app/main.py"
elif [ -f "main.py" ]; then
    APP_PATH="main.py"
else
    APP_PATH="app/app/main.py"
fi

echo "Iniciando Streamlit em $APP_PATH..."
exec streamlit run "$APP_PATH" --server.port=8501 --server.address=0.0.0.0