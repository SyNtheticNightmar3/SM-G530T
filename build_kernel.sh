#!/bin/bash

export USE_CCACHE=1
export CCACHE_DIR=$HOME/.ccache
export PATH=/usr/lib/ccache:$PATH
ccache -M 2G

# Add toolchain to path & allow caching from CodeBench (much faster than ccache!).
# export PATH=$HOME/gcc/scb_arm-eabi-2014.05/bin/cache:$HOME/gcc/scb_arm-eabi-2014.05/bin:$PATH

# For CodeBench caching, arm-none-*eabi- must be called explicitly from $PATH.
export ARCH=arm
export CROSS_COMPILE="ccache $HOME/tc/arm-eabi-4.8/bin/arm-eabi-"

FUNC_RM_DTB()
{
	if ! [ -d output/arch/arm/boot/dts ] ; then
		echo "no directory : "output/arch/arm/boot/dts""
	else
		echo "rm files in : "output/arch/arm/boot/dts/*.dtb""
		rm output/arch/arm/boot/dts/*.dtb
	fi
}

INSTALLED_DTIMAGE_TARGET=output/arch/arm/boot/dt.img
DTBTOOL=tools/dtbTool
BOARD_KERNEL_BASE=0x80000000
BOARD_KERNEL_PAGESIZE=2048
BOARD_KERNEL_TAGS_OFFSET=0x01E00000
BOARD_RAMDISK_OFFSET=0x02000000
BOARD_KERNEL_CMDLINE="console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci"
KERNEL_ZIMG=output/arch/arm/boot/zImage
CDATE=`date "+%Y-%m-%d"`

FUNC_BUILD_DTIMAGE_TARGET()
{
	echo ""
	echo "================================="
	echo "START : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
	echo "DT image target : $INSTALLED_DTIMAGE_TARGET"

	echo "$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p output/scripts/dtc/ output/arch/arm/boot/dts/"
		$DTBTOOL -o $INSTALLED_DTIMAGE_TARGET -s $BOARD_KERNEL_PAGESIZE \
		-p output/scripts/dtc/ output/arch/arm/boot/dts/

	chmod a+r $INSTALLED_DTIMAGE_TARGET

	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_DTIMAGE_TARGET"
	echo "================================="
	echo ""
}

FUNC_MKBOOTIMG()
{
	echo ""
	echo "==================================="
	echo "START : FUNC_MKBOOTIMG"
	echo "==================================="
	echo ""
	MKBOOTIMGTOOL=tools/mkbootimg
	MKRAMDISKTOOL=tools/repack_ramdisk

	echo "Making ramdisk ..."
	echo "	$MKRAMDISKTOOL tools/ramdisk ../output/initramfs.cpio.gz"

	$MKRAMDISKTOOL tools/ramdisk ../output/initramfs.cpio.gz

	echo "Making boot.img ..."
	echo "	$MKBOOTIMGTOOL --kernel $KERNEL_ZIMG \
			--ramdisk output/initramfs.cpio.gz \
			--output output/boot.img \
			--cmdline "$BOARD_KERNEL_CMDLINE" \
			--base $BOARD_KERNEL_BASE \
			--pagesize $BOARD_KERNEL_PAGESIZE \
			--ramdisk_offset $BOARD_RAMDISK_OFFSET \
			--tags_offset $BOARD_KERNEL_TAGS_OFFSET \
			--dt $INSTALLED_DTIMAGE_TARGET"

	$MKBOOTIMGTOOL --kernel $KERNEL_ZIMG \
			--ramdisk output/initramfs.cpio.gz \
			--output output/boot.img \
			--cmdline "$BOARD_KERNEL_CMDLINE" \
			--base $BOARD_KERNEL_BASE \
			--pagesize $BOARD_KERNEL_PAGESIZE \
			--ramdisk_offset $BOARD_RAMDISK_OFFSET \
			--tags_offset $BOARD_KERNEL_TAGS_OFFSET \
			--dt $INSTALLED_DTIMAGE_TARGET

        echo -n "SEANDROIDENFORCE" >> output/boot.img

	cd output
	tar -H ustar -c boot.img > boot_fortuna-tmo_$CDATE.tar
	md5sum -t boot_fortuna-tmo_$CDATE.tar >> boot_fortuna-tmo_$CDATE.tar
	mv boot_fortuna-tmo_$CDATE.tar boot_fortuna-tmo_$CDATE.tar.md5
	cd ..

	echo ""
	echo "==================================="
	echo "END   : FUNC_MKBOOTIMG"
	echo "==================================="
	echo ""
}

if [ "$1" = "-c" ]; then
    echo "Making clean..."
    make clean
    echo "Removing build log..."
    rm -rf build.log
    echo "Cleaning out dir..."
    rm -rf output
elif [ "$1" = "-pc" ]; then
    echo "Clearing packaged content..."
    rm -rf $INSTALLED_DTIMAGE_TARGET
    rm -rf output/initramfs.cpio.gz
    rm -rf output/boot.img
    rm -rf output/boot_fortuna-tmo*.tar.md5
else
    mkdir output
    FUNC_RM_DTB
    make -C $(pwd) O=output msm8916_sec_defconfig VARIANT_DEFCONFIG=msm8916_sec_fortuna_tmo_defconfig SELINUX_DEFCONFIG=selinux_defconfig;

    BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
    time logsave build.log make -C $(pwd) O=output -j$BUILD_JOB_NUMBER;

    if [ "$1" = "-p" ]; then
        echo ""
        if [ -e output/arch/arm/boot/zImage ]; then
            FUNC_BUILD_DTIMAGE_TARGET
            FUNC_MKBOOTIMG
            echo "Done: output/boot_fortuna-tmo_$CDATE.tar.md5"
        else
            echo "Something went wrong. zImage not found."
        fi
    fi
fi

