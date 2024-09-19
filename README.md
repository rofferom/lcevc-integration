# LCEVC encoder integration example

## Build environment

Everything is built for Linux.

## Target environment

* Encoder environment: Linux + NVENC

## Prerequisites to build ffmpeg with LCEVC encoding support

`LCEVC_SDK` environment variable must be set to point to LCECV SDK version `b2cca36c` that contains:
```
├── docs
│   ├── nvenc_h264_properties.md
│   └── nvenc_hevc_properties.md
├── include
│   ├── lcevc_eil.h
│   ├── lcevc.h
│   └── lcevc_version.h
├── liblcevc_eilp_nvenc_h264.so
├── liblcevc_eilp_nvenc_hevc.so
├── liblcevc_eil.so
├── liblcevc_epi.so
├── libvulkan.so -> libvulkan.so.1
├── libvulkan.so.1 -> libvulkan.so.1.2.158
├── libvulkan.so.1.2.158
├── licenses
│   ├── Header Files License.txt
│   ├── Notice.txt
│   ├── rapidjson
│   │   └── license.txt
│   ├── vulkan-loader
│   │   └── LICENSE.txt
│   └── xxhash
│       └── license.txt
└── package_info.txt
```

## Build

Just run:
```bash
./build.sh
```

It will output one folders
* `rootfs-linux`: Contains a Linux ffmpeg build with LCEVC h264 encoder

## Run tests

### Encode

```
./run_ffmpeg.sh -i BigBuckBunny.mp4 -init_hw_device vulkan -vf hwupload=derive_device=vulkan -c:v lcevc_h264 -c:a copy -b:v 10M BigBuckBunny-lcevc.mp4
```
