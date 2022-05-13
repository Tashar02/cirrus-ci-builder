#!/bin/bash

###############################   MISC   ###################################

gut() {
	git clone --depth=1 -q $@
}

############################################################################


############################# Setup Toolchains #############################

mkdir toolchains

#gut https://github.com/mvaisakh/gcc-arm64 -b gcc-master toolchains/gcc-arm64
gut https://github.com/mvaisakh/gcc-arm -b gcc-master toolchains/gcc-arm
gut https://gitlab.com/dakkshesh07/neutron-clang toolchains/clang

############################################################################

############################## Setup AnyKernel #############################

gut https://github.com/Tashar02/AnyKernel3 AnyKernel3

############################################################################

############################### Setup Kernel ###############################

gut https://github.com/Atom-X-Devs/android_kernel_xiaomi_scarlet -b rebase Kernel

############################################################################


############################ Setup Telegram API ############################

sed -i s/demo1/${token}/g telegram-send.conf
sed -i s/demo2/${chat_id}/g telegram-send.conf
mkdir .config
mv telegram-send.conf .config/telegram-send.conf

############################################################################

############################## Setup Scripts ###############################

mv scarlet.sh Kernel/scarlet.sh
cd Kernel
bash scarlet.sh --compiler=clang --device=wayne

############################################################################