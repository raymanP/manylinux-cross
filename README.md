# manylinux2014-cross-arm

[![Docker Image](https://img.shields.io/docker/pulls/messense/manylinux2014-cross.svg?maxAge=2592000)](https://hub.docker.com/r/messense/manylinux2014-cross/)
[![Build](https://github.com/messense/manylinux2014-cross-arm/workflows/Build/badge.svg)](https://github.com/messense/manylinux2014-cross-arm/actions?query=workflow%3ABuild)

manylinux2014 aarch64/armv7l cross compilation docker images

| Architecture |      OS      |       Tag       |          Target Python                    |       Host Python     |
| ------------ | ------------ | --------------- | ----------------------------------------- | --------------------- |
| aarch64      | Ubuntu 16.04 | aarch64         | Copied from manylinux2014_aarch64         | Python 3.6 - 3.9      |
| armv7l       | Ubuntu 16.04 | armv7l / armv7  | `/opt/python/cp3[6-9]`, built from source | Python 3.6 - 3.9      |

Target cross compilers and [maturin](https://github.com/PyO3/maturin) are installed in the image.

## Environment variables

Following list of environment variables are set:

* `TARGET_CC`
* `TARGET_CXX`
* `TARGET_AR`
* `TARGET_SYSROOT`
* `TARGET_C_INCLUDE_PATH`
* `CARGO_BUILD_TARGET`
* `CARGO_TARGET_${target}_LINKER`
