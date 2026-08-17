# --- ETAPA 1: Compilação com suporte a CUDA Stubs ---
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configura o stub do driver CUDA para linkagem
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf \
    && ldconfig

WORKDIR /build

RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git .

RUN cmake -B build -DGGML_CUDA=ON -DCMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs
RUN cmake --build build --config Release --target llama-server -j$(nproc)


# --- ETAPA 2: Imagem Final de Execução Unificada ---
FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl \
    ca-certificates \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copia o executável e TODAS as bibliotecas .so compiladas
COPY --from=builder /build/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=builder /build/build/bin/*.so /usr/local/lib/
RUN ldconfig && chmod +x /usr/local/bin/llama-server

WORKDIR /app

# Instala as dependências Python
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copia os arquivos do projeto e define a entrada
COPY . .
RUN chmod +x entrypoint.sh

EXPOSE 8501 8080

ENTRYPOINT ["./entrypoint.sh"]