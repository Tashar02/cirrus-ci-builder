#!/usr/bin/env bash

# Helper function for cloning
gut() {
	git clone --depth=1 -q $@
}

# Install zstd
wget https://github.com/dakkshesh07/zstd-pkgbuild/releases/download/1.5.2-8/zstd-1.5.2-8-x86_64.pkg.tar.zst
pacman -U --noconfirm zstd-1.5.2-8-x86_64.pkg.tar.zst

# Toolchains directory
mkdir toolchains

# Clone GCC
#gut https://github.com/cyberknight777/gcc-arm64.git -b master toolchains/gcc64
gut https://github.com/mvaisakh/gcc-arm.git -b gcc-master toolchains/gcc32

# Clone CLANG
gut https://gitlab.com/Tashar02/neutron-clang.git -b Neutron-16 toolchains/clang

# Clone AnyKernel3
gut https://github.com/Tashar02/AnyKernel3.git AnyKernel3

# Clone Kernel Source
gut https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b test Kernel

# Setup Scripts
mv scarlet.sh Kernel/scarlet.sh
cd Kernel

# Compile the kernel using CLANG
bash scarlet.sh clang
