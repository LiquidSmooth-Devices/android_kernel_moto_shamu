#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="zImage"
DTBIMAGE="dtb"
DEFCONFIG="shamu_defconfig"

# Kernel Details
BASE_AK_VER="LiquidKernel"
VER=".v2.1.2_"
CURDATE=$(date "+%m-%d-%Y")
AK_VER="$BASE_AK_VER$VER$CURDATE"

# Vars
export CROSS_COMPILE=/home/teamliquid/Brock/liquid/prebuilts/gcc/linux-x86/arm/arm-eabi-6.0/bin/arm-eabi-
export ARCH=arm
export SUBARCH=arm

# Paths
KERNEL_DIR="/home/teamliquid/Brock/liquid/kernel/moto/shamu"
REPACK_DIR="/home/teamliquid/Brock/liquid/kernel/moto/shamu/utils/AnyKernel2"
MODULES_DIR="/home/teamliquid/Brock/liquid/kernel/moto/shamu/utils/AnyKernel2/modules"
ZIP_MOVE="/www/devs/teamliquid/Kernels/shamu/"
ZIMAGE_DIR="/home/teamliquid/Brock/liquid/kernel/moto/shamu/arch/arm/boot"
ZIP_DIR="/home/teamliquid/Brock/liquid/kernel/moto/shamu/utils/zip"
UTILS="/home/teamliquid/Brock/liquid/kernel/moto/shamu/utils"

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		cd $ZIP_DIR/kernel
		rm -rf $DTBIMAGE
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		script -q /home/teamliquid/Brock/Compile-$CURDATE.log -c "
		make $THREAD "
}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$REPACK_DIR/tools/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm/boot/
}

function make_boot {
		cp -vr $ZIMAGE_DIR/zImage-dtb $ZIP_DIR/kernel/zImage
}


function make_zip {
		cd $ZIP_DIR
		zip -r9 kernel.zip *
		mv  kernel.zip $ZIP_MOVE
		rm $ZIP_DIR/kernel/zImage
}

function sign_zip {
		cd $ZIP_MOVE
		java -jar $UTILS/signapk.jar $UTILS/testkey.x509.pem $UTILS/testkey.pk8 kernel.zip `echo $AK_VER`.zip
		rm kernel.zip
		cd $KERNEL_DIR
}

DATE_START=$(date +"%s")


echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$AK_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making LiquidKernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_boot
		make_zip
		sign_zip
		clean_all
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
