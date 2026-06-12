# MobileSharing_demo

[![GitHub Action Workflow Status](https://img.shields.io/github/actions/workflow/status/emericg/MobileSharing_demo/ci_builds.yml?style=flat-square)](https://github.com/emericg/MobileSharing_demo/actions/workflows/ci_builds.yml)

A Qt6 / QML demo application for the [MobileSharing](https://github.com/emericg/MobileSharing) module.  


## Goals

- Handle the Android/iOS specific features about sharing / recieving files, links, text between applications
- A very important goal is to be a drag and drop module
- Build it, link it, use it. Minimal disruption on the host project using it


## About

### Dependencies

You will need a C++17 compiler and Qt 6.8 LTS to run this demo.  
For macOS and iOS builds, you'll need Xcode (15+) installed.  
For Android builds, you'll need the appropriates JDK (17) SDK (23+) and NDK (26+). You can customize Android build environment using the `assets/android/gradle.properties` file.  

#### Building

```bash
$ git clone https://github.com/emericg/MobileSharing_demo.git --recursive
$ cd MobileSharing_demo/
$ cmake -B build/ -G Ninja -DCMAKE_BUILD_TYPE=Release
$ cmake --build build/ --config Release
```

## License

The MobileSharing_demo project, just like the MobileSharing module, is licensed under the [MIT license](LICENSE).

> Emeric Grange <emeric.grange@gmail.com>
