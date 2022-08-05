#!/bin/bash

###############################   MISC   ###################################

gut() {
	git clone --depth=1 -q $@
}

############################################################################


############################# Setup Toolchains #############################

mkdir toolchains

#gut https://github.com/cyberknight777/gcc-arm64.git -b master toolchains/gcc64
gut https://github.com/cyberknight777/gcc-arm.git -b master toolchains/gcc32
gut https://gitlab.com/dakkshesh07/neutron-clang.git -b Neutron-16 toolchains/clang

############################################################################

############################## Setup AnyKernel #############################

gut https://github.com/Tashar02/AnyKernel3.git AnyKernel3

############################################################################

############################### Setup Kernel ###############################

gut https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet.git -b default-QTI Kernel

############################################################################

############################## Setup Scripts ###############################

mv scarlet.sh Kernel/scarlet.sh
cd Kernel
bash scarlet.sh clang

############################################################################