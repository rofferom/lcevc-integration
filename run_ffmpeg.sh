#!/bin/bash

BASE_DIR=$(realpath $(dirname $0))

export LD_LIBRARY_PATH=$BASE_DIR/rootfs-linux/lib
./rootfs-linux/bin/ffmpeg "$@"
