# LCEVC encoder/decoder integration example

## Build environment

Everything is built from Linux. Windows build is using MinGW-w64.

`Dockerfile` can be used to generate the build environment, or get the list of
required packages to install to be able to run the build script.

## Target environment

* Encoder environment: Windows + NVENC
* Decoder environment: Debian 12

## Prerequisites to build ffmpeg with LCEVC encoding support

`LCEVC_SDK` environment variable must be set to point to LCECV SDK version `b2cca36c` that contains:
```
├── include
│   ├── lcevc_eil.h
│   ├── lcevc.h
│   └── lcevc_version.h
├── lcevc_eil.dll
├── lcevc_eilp_nvenc_av1.dll
├── lcevc_eilp_nvenc_h264.dll
├── lcevc_eilp_nvenc_hevc.dll
├── lcevc_epi.dll
├── lib
│   └── lcevc_eil.lib
├── licenses
│   ├── Header Files License.txt
│   ├── Notice.txt
│   ├── rapidjson
│   │   └── license.txt
│   ├── vulkan-loader
│   │   └── LICENSE.txt
│   └── xxhash
│       └── license.txt
├── package_info.txt
└── vulkan-1.dll
```

## Build

Just run:
```bash
./build.sh
```

It will output two folders
* `rootfs-win32`: Contains a Windows ffmpeg build with LCEVC h264 with nvenc as base encoder
* `rootfs-linux`: Contains a Linux ffmpeg build with LCEVC h264 decoder

## Run tests

### Encode

Put `rootfs-win32/bin` content on a Windows PC and transcode a video with command:
```
ffmpeg.exe -i BigBuckBunny.mp4 -c:v lcevc_h264 -b:v 10M BigBuckBunny-lcevc.mp4
```

### Play

```
./run_ffplay.sh -flags low_delay BigBuckBunny-lcevc.mp4
```

### Some metadata of the input file

```
$ mediainfo BigBuckBunny.mp4
General
Complete name                            : BigBuckBunny.mp4
Format                                   : MPEG-4
Format profile                           : Base Media / Version 2
Codec ID                                 : mp42 (isom/avc1/mp42)
File size                                : 151 MiB
Duration                                 : 9 min 56 s
Overall bit rate mode                    : Variable
Overall bit rate                         : 2 119 kb/s
Frame rate                               : 24.000 FPS
Encoded date                             : 2010-01-10 08:29:06 UTC
Tagged date                              : 2010-01-10 08:29:06 UTC
gsst                                     : 0
gstd                                     : 596961
gssd                                     : BADC219C2HH1385162467077729
gshh                                     : r8---sn-o097zned.googlevideo.com

Video
ID                                       : 2
Format                                   : AVC
Format/Info                              : Advanced Video Codec
Format profile                           : High@L3.1
Format settings                          : CABAC / 3 Ref Frames
Format settings, CABAC                   : Yes
Format settings, Reference frames        : 3 frames
Format settings, GOP                     : M=1, N=30
Codec ID                                 : avc1
Codec ID/Info                            : Advanced Video Coding
Duration                                 : 9 min 56 s
Bit rate                                 : 1 991 kb/s
Maximum bit rate                         : 5 373 kb/s
Width                                    : 1 280 pixels
Height                                   : 720 pixels
Display aspect ratio                     : 16:9
Frame rate mode                          : Constant
Frame rate                               : 24.000 FPS
Color space                              : YUV
Chroma subsampling                       : 4:2:0
Bit depth                                : 8 bits
Scan type                                : Progressive
Bits/(Pixel*Frame)                       : 0.090
Stream size                              : 142 MiB (94%)
Title                                    : (C) 2007 Google Inc. v08.13.2007.
Encoded date                             : 2010-01-10 08:29:06 UTC
Tagged date                              : 2010-01-10 08:29:20 UTC
Codec configuration box                  : avcC

Audio
ID                                       : 1
Format                                   : AAC LC
Format/Info                              : Advanced Audio Codec Low Complexity
Codec ID                                 : mp4a-40-2
Duration                                 : 9 min 56 s
Bit rate mode                            : Variable
Bit rate                                 : 125 kb/s
Maximum bit rate                         : 169 kb/s
Channel(s)                               : 2 channels
Channel layout                           : L R
Sampling rate                            : 44.1 kHz
Frame rate                               : 43.066 FPS (1024 SPF)
Compression mode                         : Lossy
Stream size                              : 8.93 MiB (6%)
Title                                    : (C) 2007 Google Inc. v08.13.2007.
Encoded date                             : 2010-01-10 08:29:06 UTC
Tagged date                              : 2010-01-10 08:29:20 UTC
```

```
$ sha1sum BigBuckBunny.mp4
b29ae9b33d33304b3b966f2921cc5bfb3cb3c3ce  BigBuckBunny.mp4
```
