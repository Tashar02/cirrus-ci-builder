#!/bin/bash

# Copyright © 2021,
# Author(s): Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>, Navin Kumar <nk.whitehat@gmail.com>
# Revision: 27-11-2021 V1

# cd To An Absolute Path
cd /tmp/rom

# export sync start time
export TZ=$TZ

#Working Directory
WORK_DIR=$(pwd)

# Telegram Chat Id
ID=$CHAT_ID

# Bot Token
bottoken=$BOT_API_KEY

# Functions
msg() {
	curl -X POST "https://api.telegram.org/bot$bottoken/sendMessage" -d chat_id="$ID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}
file() {
	MD5=$(md5sum "$1" | cut -d' ' -f1)
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot$bottoken/sendDocument" \
	-F chat_id="$ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2 | <b>MD5 Checksum : </b><code>$MD5</code>"
}

#cloning
if [ -d $WORK_DIR/Anykernel ]
then
echo "Anykernel Directory Already Exists"
else
git clone --depth=1 https://github.com/Tashar02/AnyKernel3-4.19.git $WORK_DIR/Anykernel
fi
if [ -d $WORK_DIR/kernel ]
then
echo "Kernel directory already exists"
echo "Pulling recent changes"
cd $WORK_DIR/kernel && git pull origin pelt-v2
cd ../
else
git clone --depth=1 https://github.com/Atom-X-Devs/kernel_sdm660_scarlet.git -b pelt-v2 $WORK_DIR/kernel
fi
if [ -d $WORK_DIR/toolchains/clang ]
then
echo "Clang directory already exists"
else
mkdir $WORK_DIR/toolchains && cd $WORK_DIR/toolchains
git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git clang
cd ../
fi
cd $WORK_DIR/kernel

# Info
DEVICE="Mi A2 / Mi 6X"
CAM_LIB=''
DATE=$(TZ=GMT-6:00 date +%d'-'%m'-'%y'_'%I':'%M)
VERSION=$(make kernelversion)
DISTRO=$(source /etc/os-release && echo $NAME)
CORES=$(nproc --all)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_LOG=$(git log --oneline -n 1)
COMPILER=$($WORK_DIR/toolchains/clang/bin/clang --version 2>/dev/null | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

#Starting Compilation
BUILD_START=$(date +"%s")
export PATH="$WORK_DIR/toolchains/clang/bin/:$PATH"
cd $WORK_DIR/kernel
make clean && make mrproper
make O=out -j$(nproc --all) vendor/wayne_defconfig	\
	ARCH=arm64					\
	CC=clang					\
	LLVM=1						\
	LLVM_IAS=1					\
	HOSTCC=clang					\
	HOSTCXX=clang++					\
	CROSS_COMPILE=aarch64-linux-gnu-		\
	PATH="$WORK_DIR/toolchains/clang/bin/:$PATH"	\
	KBUILD_BUILD_USER=Tashar			\
	KBUILD_BUILD_HOST=Alpha-α			\
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-		\
	CROSS_COMPILE_COMPAT=arm-linux-gnueabi-		\
	LD_LIBRARY_PATH=$WORK_DIR/toolchains/clang/lib:$LD_LIBRARY_PATH | tee log.txt

source out/.config
if [[ "$CONFIG_LTO_CLANG_THIN" != "y" && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
	VARIANT='FULL_LTO'
elif [[ "$CONFIG_LTO_CLANG_THIN" == "y" && "$CONFIG_LTO_CLANG_FULL" == "y" ]]; then
	VARIANT='THIN_LTO'
else
	VARIANT='NON_LTO'
fi

#Zipping Into Flashable Zip
if [[ -f $WORK_DIR/kernel/out/arch/arm64/boot/Image.gz-dtb ]];
	FDEVICE=${wayne^^}
	KNAME=$(echo "$CONFIG_LOCALVERSION" | cut -c 2-)
	
	if [[ "$CAM_LIB" == "" ]]; then
		CAM=NEW-CAM
	else
		CAM=OLD-LIB
	fi
then
cp $WORK_DIR/kernel/out/arch/arm64/boot/Image.gz-dtb $WORK_DIR/Anykernel
cd $WORK_DIR/Anykernel
FINAL_ZIP="$KNAME-$CAM-$FDEVICE-$VARIANT-`date +"%H%M"`"
zip -r9 "$FINAL_ZIP".zip * -x README.md *placeholder zipsigner* java -jar zipsigner* "$FINAL_ZIP.zip" "$FINAL_ZIP-signed.zip"
KERNEL_ZIP="$FINAL_ZIP-signed.zip"
cp $WORK_DIR/Anykernel/$KERNEL_ZIP $WORK_DIR/
rm $WORK_DIR/Anykernel/Image.gz-dtb
rm $WORK_DIR/Anykernel/$KERNEL_ZIP
BUILD_END=$(date +"%s")
DIFF=$((BUILD_END - BUILD_START))

#Upload Kernel

file "$WORK_DIR/$KERNEL_ZIP"

msg "<b>========Scarlet-X Kernel========</b>%0A<b>Device: </b><code>$DEVICE</code>%0A<b>Kernel Version: </b><code>$VERSION</code>%0A<b>Builder Version: </b><code>$VERSION</code>%0A<b>Date: </b><code>$DATE</code>%0A<b>Build Duration: </b><code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>%0A<b>Host Distro: </b><code>$DISTRO</code>%0A<b>Host Core Count: </b><code>$CORES</code>%0A<b>Compiler Used: </b><code>$COMPILER</code>%0A<b>Branch: </b><code>$BRANCH</code>%0A<b>Last Commit Name: </b><code>$(git show -s --format=%s)</code>%0A<b>Last Commit Hash: </b><code>$(git rev-parse --short HEAD)</code>"
else
file "$WORK_DIR/kernel/log.txt" "Build Failed ⚠️ and took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
fi
