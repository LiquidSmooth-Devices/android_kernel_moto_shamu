#!/bin/bash

SOURCE="/home/teamliquid/Brock/liquid/kernel/moto/shamu"
RAMDISK="/home/teamliquid/Brock/ramdisk"
OUT="/home/teamliquid/Brock/liquid/out/target/product/shamu"
ZIP="/home/teamliquid/Brock/utils/zip"
UTILS="/home/teamliquid/Brock/utils"
export ARCH=arm
export CROSS_COMPILE=/home/teamliquid/Brock/liquid/prebuilts/gcc/linux-x86/arm/arm-eabi-6.0/bin/arm-eabi-
export curdate=`date "+%m-%d-%Y"`

# Start Time
res1=$(date +%s.%N)

# Colorize and add text parameters
red=$(tput setaf 1) # red
grn=$(tput setaf 2) # green
cya=$(tput setaf 6) # cyan
txtbld=$(tput bold) # Bold
bldred=${txtbld}$(tput setaf 1) # red
bldgrn=${txtbld}$(tput setaf 2) # green
bldblu=${txtbld}$(tput setaf 4) # blue
bldcya=${txtbld}$(tput setaf 6) # cyan
txtrst=$(tput sgr0) # Reset

echo ""

echo -e "${bldred} Use Defconfig Settings ${txtrst}"
cd $SOURCE
cp arch/arm/configs/shamu_defconfig .config

echo ""

echo -e "${bldred} Compiling zImage.. ${txtrst}"
script -q /home/teamliquid/Brock/Compile.log -c "
make -j12 "
mv arch/arm/boot/zImage-dtb $OUT/kernel

echo ""

echo -e "${bldred} Compiling ramdisk.. ${txtrst}"
cd $RAMDISK
chmod 750 init* sbin/adbd* sbin/healthd
chmod 644 default* uevent* res/images/charger/*
chmod 755 res res/images res/images/charger
chmod 640 fstab.shamu
find . | cpio -o -H newc | gzip > $OUT/ramdisk.gz

echo ""

echo -e "${bldred} Creating boot.img.. ${txtrst}"
cd $OUT
mkbootimg --kernel kernel --ramdisk ramdisk.gz --cmdline "console=ttyHSL0,115200,n8 androidboot.selinux=permissive androidboot.console=ttyHSL0 androidboot.hardware=shamu msm_rtb.filter=0x37 ehci-hcd.park=3 utags.blkdev=/dev/block/platform/msm_sdcc.1/by-name/utags utags.backup=/dev/block/platform/msm_sdcc.1/by-name/utagsBackup coherent_pool=8M" -o boot.img

echo ""

echo -e "${bldblu} Creating zip.. ${txtrst}"
cp $OUT/boot.img $ZIP/boot.img
cd $ZIP
zip -r $OUT/LiquidKernel-shamu-Nightly.zip .

echo " "

echo "${bldblu}Signing Zip ${txtrst}"
cd $OUT
java -jar $UTILS/signapk.jar $UTILS/testkey.x509.pem $UTILS/testkey.pk8 LiquidKernel-shamu-Nightly.zip LiquidKernel-5.1-shamu-$curdate.zip
rm LiquidKernel-shamu-Nightly.zip
rm $ZIP/boot.img

echo ""

echo "${bldblu}Uploading to DrDevs ${txtrst}"
mv LiquidKernel-5.1-shamu-*.zip /www/devs/teamliquid/Kernels/shamu/

echo -e "${bldgrn} Done! ${txtrst}"

echo ""

echo -e "${bldred} Cleaning up ${txtrst}"
rm $OUT/kernel
rm $OUT/boot.img
rm $SOURCE/arch/arm/boot/zImage
rm $OUT/ramdisk.gz
cd $SOURCE
make mrproper

echo ""

# Show Elapsed Time
res2=$(date +%s.%N)
echo "${bldgrn}Total elapsed time: ${txtrst}${grn}$(echo "($res2 - $res1) / 60"|bc ) minutes ($(echo "$res2 - $res1"|bc ) seconds) ${txtrst}"

