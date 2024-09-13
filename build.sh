#!/bin/bash

# Common
BASE_DIR=$(realpath $(dirname $0))
WORK_DIR="$BASE_DIR/work"
NJOBS=$(grep -c ^processor /proc/cpuinfo)

# Win32
WIN32_WORKDIR="$WORK_DIR/x86_64-w64-mingw32"
WIN32_ROOTFS="$BASE_DIR/rootfs-win32"
WIN32_CROSS_PREFIX="x86_64-w64-mingw32"

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

    mkdir -p "$WIN32_WORKDIR/x264" && cd "$WIN32_WORKDIR/x264"

    wget https://code.videolan.org/videolan/x264/-/archive/e0fee7b2ff057bf1823e50c458d76d6964ab7b21/x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip
    test_sha256 "x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip" "ed111d6a85d2e264b90d732d6399e6bd2369d3ac807a697ba04819082c135fb3"
    unzip x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21.zip
    cd x264-e0fee7b2ff057bf1823e50c458d76d6964ab7b21

    ./configure \
        --prefix=$WIN32_ROOTFS \
        --host=$WIN32_CROSS_PREFIX --cross-prefix=$WIN32_CROSS_PREFIX- \
        --enable-shared \
        --disable-cli

    make -j $NJOBS
    make install

    # nvcodecheaders
    echo "Build nvcodecheaders"

    git clone --depth 1 --branch n12.1.14.0 https://github.com/FFmpeg/nv-codec-headers.git "$WIN32_WORKDIR/nvcodecheaders"
    cd "$WIN32_WORKDIR/nvcodecheaders"

    make install PREFIX=$WIN32_ROOTFS

    # lcevceil
    echo "Install lcevceil"

    cp \
        $LCEVC_SDK/include/lcevc_eil.h \
        $LCEVC_SDK/include/lcevc.h \
        $LCEVC_SDK/include/lcevc_version.h \
        $WIN32_ROOTFS/include

    cp \
        $LCEVC_SDK/lib/lcevc_eil.lib \
        $WIN32_ROOTFS/lib

    cp \
        $LCEVC_SDK/lcevc_eil.dll \
        $LCEVC_SDK/lcevc_eilp_nvenc_av1.dll \
        $LCEVC_SDK/lcevc_eilp_nvenc_h264.dll \
        $LCEVC_SDK/lcevc_eilp_nvenc_hevc.dll \
        $LCEVC_SDK/lcevc_epi.dll \
        $WIN32_ROOTFS/bin

    # Vulkan-Headers
    echo "Build Vulkan-Headers"

    mkdir -p "$WIN32_WORKDIR/Vulkan-Headers" && cd "$WIN32_WORKDIR/Vulkan-Headers"

    wget https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.3.295.tar.gz
    test_sha256 "v1.3.295.tar.gz" "b4568b984be4b8a317343cc14d854669e258705079a16cabef3fb92302f55561"
    tar xf v1.3.295.tar.gz
    cd Vulkan-Headers-1.3.295

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/mingw-w64-toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$WIN32_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # Vulkan-Loader
    echo "Build Vulkan-Loader"

    mkdir -p "$WIN32_WORKDIR/Vulkan-Loader" && cd "$WIN32_WORKDIR/Vulkan-Loader"
    wget https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/v1.3.295.tar.gz

    test_sha256 "v1.3.295.tar.gz" "9241b99fb70c6e172cdb8cb4c3d291c129e9499126cfe4c12aa854b71e035518"
    tar xf v1.3.295.tar.gz
    cd Vulkan-Loader-1.3.295

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE=$BASE_DIR/mingw-w64-toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$WIN32_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # FFmpeg
    echo "Build FFmpeg"

    git clone --depth 1 --branch lcevceil.0 https://github.com/rofferom/FFmpeg.git "$WIN32_WORKDIR/ffmpeg"
    cd "$WIN32_WORKDIR/ffmpeg"

    ./configure --prefix=$WIN32_ROOTFS \
        --arch=x86_64 --target-os=mingw32 --cross-prefix=$WIN32_CROSS_PREFIX- --pkg-config=pkg-config \
        --extra-ldflags=-L$WIN32_ROOTFS/bin \
        --enable-shared \
        --disable-doc \
        --enable-vulkan \
        --enable-gpl --enable-libx264 \
        --enable-nonfree --enable-nvenc \
        --enable-lcevc_encoder

    make -j $NJOBS
    make install

    # Add missing mingw32 dlls
    cp \
        /usr/lib/gcc/x86_64-w64-mingw32/12-posix/libgcc_s_seh-1.dll \
        /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll \
        $WIN32_ROOTFS/bin
}

build_decoder() {
    # libfmt
    echo "Build libfmt"

    mkdir -p "$LINUX_WORKDIR/fmt" && cd "$LINUX_WORKDIR/fmt"

    wget https://github.com/fmtlib/fmt/releases/download/8.0.1/fmt-8.0.1.zip
    test_sha256 "fmt-8.0.1.zip" "a627a56eab9554fc1e5dd9a623d0768583b3a383ff70a4312ba68f94c9d415bf"
    unzip fmt-8.0.1.zip
    cd fmt-8.0.1

    mkdir build && cd build

    cmake \
        -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
        -DBUILD_SHARED_LIBS=TRUE \
        -DFMT_TEST=OFF \
        -DFMT_FUZZ=OFF \
        -DFMT_DOC=OFF \
        -DCMAKE_INSTALL_PREFIX="$LINUX_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # lcevcdec
    echo "Build lcevcdec"

    git clone --branch build-hack.0 https://github.com/rofferom/LCEVCdec.git "$LINUX_WORKDIR/LCEVCdec"
    cd "$LINUX_WORKDIR/LCEVCdec"

    mkdir build && cd build

    cmake \
        -DBUILD_SHARED_LIBS=ON \
        -DVN_SDK_EXECUTABLES=OFF \
        -DVN_SDK_JSON_CONFIG=OFF \
        -DVN_SDK_SAMPLE_SOURCE=OFF \
        -DVN_SDK_UNIT_TESTS=OFF \
        -DVN_SDK_DOCS=OFF \
        -DCMAKE_INSTALL_PREFIX="$LINUX_ROOTFS" \
        ..

    make -j $NJOBS
    make install

    # FFmpeg
    echo "Build FFmpeg"

    git clone --depth 1 --branch lcevc_generic.0 https://github.com/rofferom/FFmpeg.git "$LINUX_WORKDIR/ffmpeg"
    cd "$LINUX_WORKDIR/ffmpeg"

    ./configure --prefix=$LINUX_ROOTFS \
        --enable-shared \
        --disable-doc \
        --enable-libdrm \
        --enable-gpl \
        --disable-vulkan \
        --enable-liblcevc-dec

    make -j $NJOBS
    make install
}

export PKG_CONFIG_PATH="$WIN32_ROOTFS/lib/pkgconfig"
build_encoder
unset PKG_CONFIG_PATH

export PKG_CONFIG_PATH="$LINUX_ROOTFS/lib/pkgconfig"
export LD_LIBRARY_PATH="$LINUX_ROOTFS/lib"
build_decoder
unset LD_LIBRARY_PATH
unset PKG_CONFIG_PATH
