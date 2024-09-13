FROM debian:bookworm-20240904-slim

RUN apt-get update && \
    apt-get install -y \
        python3 cmake pkg-config \
        autoconf libtool git wget unzip nasm  \
        build-essential mingw-w64 mingw-w64-tools \
        libdrm-dev libsdl2-dev
