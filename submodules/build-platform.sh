#!/bin/bash

LOCALARCH=`uname -m`
TOPDIR=$(cd `dirname $0` ; pwd)
export PATH=$TOPDIR:$TOPDIR/../includes:$PATH
. $TOPDIR/../Include.sh

###################################################################################
# build arguments
###################################################################################
CROSS_COMPILE=
CLEAN=
PLATFORMS=
DISTROS=
PACKAGES=
OUTPUT=
CFG_FILE=
###################################################################################
# build_platform_usage
###################################################################################
build_platform_usage()
{
cat << EOF
Usage: build-platform.sh [clean] --cross=xxx --platform=xxx,xxx --distros=xxx,xxx --packages=xxx,xxx --output=xxx --file=./estuary/estuarycfg.json
    clean: clean the platform binary files
    --cross: cross compile prefix (if the host is not arm architecture, it must be specified.)
    --platform: which platform to build (D03, D05, HiKey)
    --distros: which distros to install (Ubuntu, CentOS, Fedora, Debian)
    --output: target binary output directory

Example:
    build-platform.sh --cross=aarch64-linux-gnu- --platform=D03 --distros=Ubuntu --output=workspace
    build-platform.sh --cross=aarch64-linux-gnu- --platform=D03 --distros=Ubuntu --output=workspace --file=./estuary/estuarycfg.json
    build-platform.sh --cross=aarch64-linux-gnu- --platform=D03,D05,HiKey --distros=Ubuntu --output=workspace

EOF
}

###################################################################################
# get args
###################################################################################
while test $# != 0
do
    case $1 in
        --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        *) ac_option=$1 ;;
    esac

    case $ac_option in
    clean) CLEAN="yes" ;;
    --cross) CROSS_COMPILE=$ac_optarg ;;
    --platform) PLATFORMS=$ac_optarg;;
    --distros) DISTROS=$ac_optarg ;;
    --output) OUTPUT=$ac_optarg ;;
    --file) CFG_FILE=$ac_optarg ;;
    *) echo "Unknown option $ac_option!"
        build_platform_usage ; exit 1 ;;
    esac

    shift
done

###################################################################################
# Parameter check
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ] && [ x"$CROSS_COMPILE" = x"" ]; then
    build_platform_usage
    echo -e "\033[31mError! --cross must be specified!\033[0m" ; exit 1
fi

if [ -z $PLATFORMS ] || [ -z $DISTROS ]; then
    echo -e "\033[31mError! --platform, --distros must be specified!\033[0m"
    build_platform_usage ; exit 1
fi

###################################################################################
# Clean platform
###################################################################################
if [ x"$CLEAN" = x"yes" ]; then
    # clean modules
    platforms=`echo $PLATFORMS | tr ',' ' '`
    for plat in ${platforms[*]}; do
        build-uefi.sh clean --platform=$plat --output=$OUTPUT
        build-grub.sh clean --output=$OUTPUT
        build-kernel.sh clean --platform=$plat --cross=$CROSS_COMPILE --output=$OUTPUT
        if [ x"$plat" = x"QEMU" ]; then
            build-qemu.sh clean --output=$OUTPUT --distros=$DISTROS
        fi
    done

    # clean distros
    distros=`echo $DISTROS | tr ',' ' '`
    for distro in ${distros[*]}; do
        sudo rm -rf $OUTPUT/distro/${distro} 2>/dev/null
        sudo rm -f $OUTPUT/distro/${distro}_ARM64.tar.gz 2>/dev/null
    done

    exit 0
fi

###################################################################################
# Build platform
###################################################################################
platforms=`echo $PLATFORMS | tr ',' ' '`
for plat in ${platforms[*]}; do
    echo "---------------------------------------------------------------"
    echo "- Build UEFI (platform: $plat, output: $OUTPUT)"
    echo "---------------------------------------------------------------"
    build-uefi.sh --platform=$plat --output=$OUTPUT || exit 1
    echo "- Build UEFI done!"
    echo ""

    echo "---------------------------------------------------------------"
    echo "- Build GRUB (output: $OUTPUT)"
    echo "---------------------------------------------------------------"
    build-grub.sh --output=$OUTPUT || exit 1
    echo "- Build GRUB done!"
    echo ""

    echo "---------------------------------------------------------------"
    echo "- Build Kernel (platform: $plat, cross: $CROSS_COMPILE, output: $OUTPUT)"
    echo "---------------------------------------------------------------"
    build-kernel.sh --platform=$plat --cross=$CROSS_COMPILE --output=$OUTPUT || exit 1
    echo "- Build Kernel done!"
    echo ""
done

###################################################################################
# Install modules
###################################################################################
distros=`echo $DISTROS | tr ',' ' '`
for distro in ${distros[*]}; do
    echo "---------------------------------------------------------------"
    echo "- Build modules (kerneldir: $OUTPUT/kernel, rootfs: $OUTPUT/distro/$distro, cross: $CROSS_COMPILE)"
    echo "---------------------------------------------------------------"
    build-modules.sh --kerneldir=$OUTPUT/kernel --rootfs=$OUTPUT/distro/$distro --cross=$CROSS_COMPILE || exit 1
    echo "- Build modules done!"
    echo ""
done

###################################################################################
# Build packages
###################################################################################
distros=`echo $DISTROS | tr ',' ' '`
for distro in ${distros[*]}; do
    echo "---------------------------------------------------------------"
    echo "- Build packages (kerneldir: $OUTPUT/kernel, distro: $distro, rootfs: $OUTPUT/distro/$distro, cross: $CROSS_COMPILE, cfgfile: $CFG_FILE)"
    echo "---------------------------------------------------------------"
    build-packages.sh --output=$OUTPUT --kernel=$OUTPUT/kernel --distro=$distro --rootfs=$OUTPUT/distro/$distro --cross=$CROSS_COMPILE --file=${CFG_FILE}
    echo "- Build packages done!"
    echo ""
done

###################################################################################
# End
###################################################################################
exit 0


