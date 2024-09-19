#!/bin/bash

# Common
BASE_DIR=$(realpath $(dirname $0))
WORK_DIR="$BASE_DIR/work"
NJOBS=$(grep -c ^processor /proc/cpuinfo)

# Linux
LINUX_WORKDIR="$WORK_DIR/x86_64-linux-gnu"
LINUX_ROOTFS="$BASE_DIR/rootfs-linux"

test_sha256() {
    local local_path=$1
    local expected_hash=$2

    local real_hash=$(sha256sum $local_path | awk '{print $1}')

    if [[ $real_hash -ne $expected_hash ]]; then
        echo "Invalid hash"
        exit 1
    fi
}

build_encoder() {
    # x264
    echo "Build x264"

    mkdir -p "$LINUX_WORKDIR/x264" && cd "$LINUX_WORKDIR/x264"

    wget https://code.videolan.org/videolan/x264/-/archive/e0fee7b2ff057bf1823e50c458d76d6964ab7b21/x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip
    test_sha256 "x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip" "ed111d6a85d2e264b90d732d6399e6bd2369d3ac807a697ba04819082c135fb3"
    unzip x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip
    cd x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21

    ./configure \
        --prefix=$LINUX_ROOTFS \
        --enable-shared \
        --disable-cli

    make -j $NJOBS
    make install

    # nvcodecheaders
    echo "Build nvcodecheaders"

    git clone --depth 1 --branch n12.1.14.0 https://github.com/FFmpeg/nv-codec-headers.git "$LINUX_WORKDIR/nvcodecheaders"
    cd "$LINUX_WORKDIR/nvcodecheaders"

    make install PREFIX=$LINUX_ROOTFS

    # lcevceil
    echo "Install lcevceil"

    cp \
        $LCEVC_SDK/include/lcevc_eil.h \
        $LCEVC_SDK/include/lcevc.h \
        $LCEVC_SDK/include/lcevc_version.h \
        $LINUX_ROOTFS/include

    cp \
        $LCEVC_SDK/liblcevc_eil.so \
        $LCEVC_SDK/liblcevc_epi.so \
        $LCEVC_SDK/liblcevc_eilp_nvenc_h264.so \
        $LCEVC_SDK/liblcevc_eilp_nvenc_hevc.so \
        $LINUX_ROOTFS/lib

    # Vulkan-Headers
    echo "Build Vulkan-Headers"

    mkdir -p "$LINUX_WORKDIR/Vulkan-Headers" && cd "$LINUX_WORKDIR/Vulkan-Headers"

    wget https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.3.295.tar.gz
    test_sha256 "v1.3.295.tar.gz" "b4568b984be4b8a317343cc14d854669e258705079a16cabef3fb92302f55561"
    tar xf v1.3.295.tar.gz
    cd Vulkan-Headers-1.3.295

    mkdir build && cd build

    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$LINUX_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # Vulkan-Loader
    echo "Build Vulkan-Loader"

    mkdir -p "$LINUX_WORKDIR/Vulkan-Loader" && cd "$LINUX_WORKDIR/Vulkan-Loader"
    wget https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/v1.3.295.tar.gz

    test_sha256 "v1.3.295.tar.gz" "9241b99fb70c6e172cdb8cb4c3d291c129e9499126cfe4c12aa854b71e035518"
    tar xf v1.3.295.tar.gz
    cd Vulkan-Loader-1.3.295

    mkdir build && cd build

    cmake \
        -DVULKAN_HEADERS_INSTALL_DIR="$LINUX_ROOTFS" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$LINUX_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # FFmpeg
    echo "Build FFmpeg"

    git clone --depth 1 --branch lcevceil.1 https://github.com/rofferom/FFmpeg.git "$LINUX_WORKDIR/ffmpeg"
    cd "$LINUX_WORKDIR/ffmpeg"

    ./configure --prefix=$LINUX_ROOTFS \
        --extra-ldflags="-L$LINUX_ROOTFS/lib" \
        --enable-shared \
        --disable-doc \
        --enable-libdrm \
        --enable-gpl --enable-libx264 \
        --enable-nonfree --enable-nvenc \
        --enable-vulkan --enable-lcevc_encoder

    make -j $NJOBS
    make install
}

export PKG_CONFIG_PATH="$LINUX_ROOTFS/lib/pkgconfig"
export LD_LIBRARY_PATH="$LINUX_ROOTFS/lib"
build_encoder
unset LD_LIBRARY_PATH
unset PKG_CONFIG_PATH
