#!/bin/bash

###############################   MISC   ###################################

gut() {
	git clone --depth=1 -q $@
}

############################################################################

wget https://github.com/dakkshesh07/zstd-pkgbuild/releases/download/1.5.2-8/zstd-1.5.2-8-x86_64.pkg.tar.zst
pacman -U --noconfirm zstd-1.5.2-8-x86_64.pkg.tar.zst

############################# Setup Toolchains #############################

mkdir toolchains

#gut https://github.com/cyberknight777/gcc-arm64.git -b master toolchains/gcc64
gut https://github.com/mvaisakh/gcc-arm.git -b gcc-master toolchains/gcc32

mkdir toolchains/clang && cd toolchains/clang
bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S=latest
cd ../..

############################################################################

############################## Setup AnyKernel #############################

gut https://github.com/Tashar02/AnyKernel3.git AnyKernel3

############################################################################

############################### Setup Kernel ###############################

gut https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b test Kernel

############################################################################

############################## Setup Scripts ###############################

mv scarlet.sh Kernel/scarlet.sh
cd Kernel
bash scarlet.sh clang

############################################################################
