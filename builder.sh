#!/usr/bin/env bash

# Global Variables
AOSP_CLANG_VER='clang-r498229'

# Helper function for cloning: gsc = git shallow clone
gsc() {
	git clone --depth=1 -q $@
}

# Toolchains directory
mkdir toolchains

# Clone GCC
#gsc https://github.com/cyberknight777/gcc-arm64.git -b master toolchains/gcc64
#gsc https://github.com/mvaisakh/gcc-arm.git -b gcc-master toolchains/gcc32

# Clone CLANG
mkdir toolchains/clang && cd toolchains/clang
#bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/${AOSP_CLANG_VER}.tgz
tar -xf ${AOSP_CLANG_VER}.tgz
cd ../..

# Clone AnyKernel3
gsc https://github.com/Tashar02/AnyKernel3.git AnyKernel3

# Clone Kernel Source
gsc https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b test Kernel

# Setup Scripts
mv scarlet.sh Kernel/scarlet.sh
cd Kernel

# Compile the kernel using CLANG
bash scarlet.sh --clang --osscam --qti --non-dynamic --full-lto
