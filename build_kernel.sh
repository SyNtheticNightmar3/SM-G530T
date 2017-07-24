#!/bin/bash

export USE_CCACHE=1
export CCACHE_DIR=$HOME/.ccache
export PATH=/usr/lib/ccache:$PATH
ccache -M 2G

# Add toolchain to path & allow caching from CodeBench (much faster than ccache!).
# export PATH=$HOME/gcc/scb_arm-eabi-2014.05/bin/cache:$HOME/gcc/scb_arm-eabi-2014.05/bin:$PATH

# For CodeBench caching, arm-none-*eabi- must be called explicitly from $PATH.
export ARCH=arm
export CROSS_COMPILE="ccache arm-linux-gnueabi-"

while getopts ":c" opt #:p for packaging
do
case "$opt" in
        c)
             CLEAN=true;;
#        p)
#             PACKAGE=true;;
        *)
             break;;
    esac
done

if [ "$CLEAN" = "true" ]; then
    echo "Making clean..."
    make clean
    echo "Removing build log..."
    rm -rf build.log
    echo "Cleaning out dir..."
    rm -rf output
else
    mkdir output
    make -C $(pwd) O=output msm8916_sec_defconfig VARIANT_DEFCONFIG=msm8916_sec_fortuna_tmo_defconfig SELINUX_DEFCONFIG=selinux_defconfig;

    time logsave build.log make -C $(pwd) O=output -j4;

#    if [ "$PACKAGE" = "true" ]; then
#        echo ""
#        if [ -e arch/arm/boot/zImage ]; then
#            echo "Copying packaging components..."
#           mkdir -p out/system/lib/modules/
#           cp -a $(find . -name *.ko -print) out/system/lib/modules/
#            mkdir out
#            cp -R package/* out/
#            cp arch/arm/boot/zImage out/kernel/
#            echo "Packaging..."
#            cd out
#            cdate=`date "+%Y-%m-%d"`
#            zfile=ED-E-kernel-flo-$cdate.zip
#            zip -r $zfile . -x *.zip
#            rm -rf kernel META-INF
#            cd ..
#            echo " ZIPFILE: out/$zfile"
#        else
#            echo "Something went wrong. zImage not found."
#        fi
#    fi
fi

