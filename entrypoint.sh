#!/bin/bash

# 1. Inicia o llama-server escutando em 0.0.0.0 e direciona a saída para o terminal
echo "Iniciando llama-server..."
llama-server \
  -m /models/llama-3.2-3b.gguf \
  --gpu-layers 99 \
  --ctx-size 4096 \
  --host 0.0.0.0 \
  --port 8080 &

# 2. Aguarda até o endpoint responder
echo "Aguardando llama-server responder..."
until curl -s http://127.0.0.1:8080/health > /dev/null || curl -s http://127.0.0.1:8080/v1/models > /dev/null; do
    sleep 2
done

echo "llama-server ativo! Iniciando Streamlit..."

# 3. Inicia o Streamlit
exec streamlit run app/main.py --server.port=8501 --server.address=0.0.0.0