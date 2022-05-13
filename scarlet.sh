#!/bin/bash
# SPDX-License-Identifier: GPL-3.0
# Copyright © 2022,
# Author(s): Divyanshu-Modi <divyan.m05@gmail.com>, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>
# Revision: 13-05-2022

#########################    CONFIGURATION    ##############################

# User details
KBUILD_USER="Tashar"
KBUILD_HOST="Cirrus"

# Build type (Fresh build: clean | incremental build: dirty)
# (default: dirty | modes: clean, dirty)
BUILD='clean'

############################################################################

########################    DIRECTOR PATHS   ###############################

# Kernel Directory
KERNEL_DIR=`pwd`

# Propriatary Directory (default paths may not work!)
PRO_PATH="$KERNEL_DIR/.."
COMPILER=$1

# Anykernel Directories
AK3_DIR="$PRO_PATH/AnyKernel3"
AKSH="$AK3_DIR/anykernel.sh"

# Toolchain Directory
TLDR="$PRO_PATH/toolchains"

############################################################################

###############################   MISC   #################################

# functions
error() {
	telegram-send "Error⚠️: $@"
	exit 1
}

success() {
	telegram-send "Success: $@"
	exit 0
}

inform() {
	telegram-send --format html "$@"
}

muke() {
	if [[ "$SILENCE" == "1" ]]; then
		KERN_MAKE_ARGS="-s $KERN_MAKE_ARGS"
	fi

	make $@ $KERN_MAKE_ARGS
}

usage() {
	inform " ./scarlet.sh <arg>
		--compiler   sets the compiler to be used
		--device     sets the device for kernel build
		--silence    Silence shell output of Kbuild"
	exit 2
}

############################################################################

compiler_setup() {
############################  COMPILER SETUP  ##############################
	case $COMPILER in
		clang)
			C_PATH="$TLDR/clang"
			KERN_MAKE_ARGS="                            \
					CC='clang'                          \
					HOSTCC=$CC                          \
					HOSTCXX=$CC                         \
					CROSS_COMPILE='aarch64-linux-gnu-'"
		;;
		gcc)
			KERN_MAKE_ARGS="                      \
					C_PATH="$TLDR/gcc-arm64"      \
					CC='aarch64-elf-gcc'          \
					HOSTCC='gcc'                  \
					HOSTCXX='aarch64-elf-g++'     \
					CROSS_COMPILE='aarch64-elf-'"
		;;
	esac
	CC_32="$TLDR/gcc-arm/bin/arm-eabi-"
	CC_COMPAT="$TLDR/gcc-arm/bin/arm-eabi-gcc"

	KERN_MAKE_ARGS="$KERN_MAKE_ARGS      \
		O=work ARCH=arm64                \
		LLVM=1                           \
		LLVM_IAS=1                       \
		AS=llvm-as                       \
		AR=llvm-ar                       \
		NM=llvm-nm                       \
		LD=ld.lld                        \
		STRIP=llvm-strip                 \
		OBJCOPY=llvm-objcopy             \
		OBJDUMP=llvm-objdump             \
		OBJSIZE=llvm-objsize             \
		HOSTLD=ld.lld                    \
		HOSTCC=$HOSTCC                   \
		HOSTCXX=$HOSTCXX                 \
		HOSTAR=llvm-ar                   \
		KBUILD_BUILD_USER=$KBUILD_USER   \
		KBUILD_BUILD_HOST=$KBUILD_HOST   \
		PATH=$C_PATH/bin:$PATH           \
		CC_COMPAT=$CC_COMPAT             \
		CROSS_COMPILE_COMPAT=$CC_32      \
		LD_LIBRARY_PATH=$C_PATH/lib:$LD_LIBRARY_PATH"
############################################################################
}

kernel_builder() {
##################################  BUILD  #################################
	if [[ -z $CODENAME ]]; then
		error 'Device not mentioned'
		exit 1
	fi

	case $BUILD in
		clean)
			rm -rf work || mkdir work
		;;
		*)
			muke clean mrproper distclean
		;;
	esac

	# Build Start
	BUILD_START=$(date +"%s")

	DFCF="vendor/${CODENAME}-${SUFFIX}_defconfig"

	inform "
		========Build Triggered========
		Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
		Build Number: <code>$DRONE_BUILD_NUMBER</code>
		Device: <code>$DEVICENAME</code>
		Codename: <code>$CODENAME</code>
		Compiler: <code>$($C_PATH/bin/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')</code>
		Compiler_32: <code>$($CC_COMPAT --version | head -n 1)</code>
	"

	# Make .config
	muke $DFCF

	# Compile
	muke -j$(nproc)

	# Build End
	BUILD_END=$(date +"%s")

	DIFF=$(($BUILD_END - $BUILD_START))

	if [[ -f $KERNEL_DIR/work/arch/arm64/boot/$TARGET ]]; then
		zipper
	else
		error 'Kernel image not found'
	fi
############################################################################
}

zipper() {
####################################  ZIP  #################################
	source work/.config

	VERSION=`echo $CONFIG_LOCALVERSION | cut -c 8-`
	KERNEL_VERSION=$(make kernelversion)
	LAST_COMMIT=$(git show -s --format=%s)
	LAST_HASH=$(git rev-parse --short HEAD)

	if [[ ! -d $AK3_DIR ]]; then
		error 'Anykernel not present cannot zip'
	fi
	if [[ ! -d "$KERNEL_DIR/out" ]]; then
		mkdir $KERNEL_DIR/out
	fi

	cp $KERNEL_DIR/work/arch/arm64/boot/$TARGET $AK3_DIR

	cd $AK3_DIR

	make zip VERSION=$VERSION

	inform "
		========Scarlet-X Kernel========
		Linux Version: <code>$KERNEL_VERSION</code>
		Scarlet-Version: <code>$VERSION</code>
		CI: <code>$KBUILD_HOST</code>
		Core count: <code>$(nproc)</code>
		Compiler: <code>$($C_PATH/bin/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')</code>
		Compiler_32: <code>$($CC_COMPAT --version | head -n 1)</code>
		Device: <code>$DEVICENAME</code>
		Codename: <code>$CODENAME</code>
		Cam lib: <code>$CAM</code>
		Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
		Build Type: <code>$BUILD_TYPE</code>

		-----------last commit details-----------
		Last commit (name): <code>$LAST_COMMIT</code>

		Last commit (hash): <code>$LAST_HASH</code>
	"

	telegram-send --file *-signed.zip

	make clean

	cd $KERNEL_DIR

	success "build completed in $(($DIFF / 60)).$(($DIFF % 60)) mins"

############################################################################
}

###############################  COMMAND_MODE  ##############################
if [[ -z $* ]]; then
	usage
fi

for arg in "$@"; do
	case "${arg}" in
		"--compiler="*)
			COMPILER=${arg#*=}
			case ${COMPILER} in
				clang)
					COMPILER="clang"
				;;
				gcc)
					COMPILER="gcc"
				;;
				*)
					usage
				;;
			esac
		;;
		"--device="*)
			CODENAME=${arg#*=}
			case $CODENAME in
				wayne)
					DEVICENAME='Mi A2 / 6X'
					CODENAME='wayne'
					SUFFIX='perf'
					MODULES='0'
					TARGET='Image.gz-dtb'
				;;
				*)
					error 'device not supported'
				;;
			esac
		;;
		"--camlib="*)
			CAM_LIB=${arg#*=}
			case $CAM_LIB in
				1)
				   CAM="NEW-CAM"
				;;
				2)
				   CAM="OLD-CAM"
				;;
				*)
				   CAM="OSS-CAM"
				;;
			esac
		;;
		"--silence")
			SILENCE='1'
		;;
		*)
			usage
		;;
	esac
done
############################################################################

# Remove testing of System.map as test always fails to check for file
# DO NOT MODIFY!!!!
sed -i '13d;14d;15d;16d;17d' $KERNEL_DIR/scripts/depmod.sh

compiler_setup
kernel_builder
