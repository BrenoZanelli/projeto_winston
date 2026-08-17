# --- ETAPA 1: Builder para compilar o llama-server com CUDA ---
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Faz o shallow clone da última versão
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git .

# Configura e compila o binário do llama-server com suporte a CUDA
RUN cmake -B build -DGGML_CUDA=ON
RUN cmake --build build --config Release --target llama-server -j$(nproc)


# --- ETAPA 2: Imagem Final de Execução (Monolítica) ---
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instala Python, pip, certificados e bibliotecas de runtime necessárias
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copia o executável compilado da etapa 1 direto para os binários do sistema
COPY --from=builder /build/build/bin/llama-server /usr/local/bin/llama-server
RUN chmod +x /usr/local/bin/llama-server

WORKDIR /app

# Instala as dependências Python
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copia a aplicação e o script de entrada
COPY . .
RUN chmod +x entrypoint.sh

EXPOSE 8501 8080

ENTRYPOINT ["./entrypoint.sh"]