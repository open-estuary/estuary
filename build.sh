#!/bin/bash
###################################################################################
# ./estuary/build.sh --help
# ./estuary/build.sh --cfgfile=./estuary/estuarycfg.json --builddir=build
# ./estuary/build.sh clean --cfgfile=./estuary/estuarycfg.json --builddir=build
###################################################################################

###################################################################################
# Const Variables, PATH
###################################################################################
LOCALARCH=`uname -m`
TOPDIR=$(cd `dirname $0` ; pwd)
ESTUARY_INTERAL_FTP=`grep -Po "(?<=download_address: )(.*)" $TOPDIR/estuary.txt`
export PATH=$TOPDIR:$TOPDIR/include:$TOPDIR/submodules:$TOPDIR/deploy:$PATH

###################################################################################
# Includes
###################################################################################
. $TOPDIR/Include.sh

###################################################################################
# Global Variables
###################################################################################
CLEAN= # Clean binary files
CFG_FILE= # JSON configuration file
BUILD_DIR= # Build output directory
CROSS_COMPILE= # Cross compile

TOOLCHAIN= # Toolchain file name
TOOLCHAIN_DIR= # Toolchain directory

PLATFORMS= # Platforms to build
DISTROS= # Distros to build
PACKAGES= # Pakcages to build and install

DISTRO_FILES= # Distro files (distro files with version)
BINARY_FILES= # binary files (binary files with version)

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
Usage: ./estuary/build.sh [options]
Options:
	--help:     Display this information
	--cfgfile:  JSON configuration file
	--builddir: Build output directory
	clean:      Clean all binary files
	--version:  print estuary version

Example:
	./estuary/build.sh --help
	./estuary/build.sh --cfgfile=./estuary/estuarycfg.json --builddir=./workspace
	./estuary/build.sh clean --cfgfile=./estuary/estuarycfg.json --builddir=./workspace

EOF
}

###################################################################################
# Get all args
###################################################################################
while test $# != 0
do
        case $1 in
        	--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        	*) ac_option=$1 ;;
        esac

        case $ac_option in
                clean) CLEAN=yes ;;
                --help) Usage ; exit 0 ;;
		--version) print_version ./estuary ; exit 0 ;;
                --cfgfile) CFG_FILE=$ac_optarg ;;
                --builddir) BUILD_DIR=$ac_optarg ;;
                *) Usage ; exit 1 ;;
        esac

        shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$CFG_FILE" = x"" ] || [ x"$BUILD_DIR" = x"" ]; then
	Usage ; exit 1
fi

###################################################################################
# Install development tools
###################################################################################
if ! (install_dev_tools $LOCALARCH); then
	echo -e "\033[31mError! Install development tools failed!\033[0m" ; exit 1
fi

iasl_version=`iasl -v 2>/dev/null | grep -Po "(?<=version )(\d+)(?=.*)" 2>/dev/null`
if [[ x"$iasl_version" < x"20150214" ]]; then
	if ! update_acpica_tools; then
		echo -e "\033[31mError! Update iasl failed!\033[0m" ; exit 1
	fi
fi

###################################################################################
# Parse configuration file
###################################################################################
PLATFORMS=$(get_install_platforms $CFG_FILE | tr ' ' ',')
DISTROS=$(get_install_distros $CFG_FILE | tr ' ' ',')
PACKAGES=$(get_install_packages $CFG_FILE | tr ' ' ',')

cat << EOF
##############################################################################
# PLAT:   $PLATFORMS
# DISTRO: $DISTROS
# PKG:    $PACKAGES
##############################################################################

EOF

if [ -z "$PLATFORMS" ] || [ -z $DISTROS ]; then
	echo -e "\033[31mError! No platform or distro to build! Please check $CFG_FILE!\033[0m" ; exit 1
fi

###################################################################################
# Download/uncompress toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
	mkdir -p toolchain
	download_toolchain toolchain $TOPDIR/checksum/toolchain/toolchain.sum $ESTUARY_INTERAL_FTP/toolchain
	if [[ $? != 0 ]]; then
		echo -e "\033[31mError! Download toolchains failed!\033[0m" ; exit 1
	fi
	toolchain=`get_toolchain $TOPDIR/checksum/toolchain/toolchain.sum`
	toolchain_dir=`get_compress_file_prefix $toolchain`
	if [ ! -d toolchain/$toolchain_dir ]; then
		if ! uncompress_file toolchain/$toolchain toolchain; then
			echo -e "\033[31mError! Uncompress toolchain failed!\033[0m" ; exit 1
		fi
	fi
	TOOLCHAIN=$toolchain
	TOOLCHAIN_DIR=`cd toolchain/$toolchain_dir; pwd`
	CROSS_COMPILE=`get_cross_compile $LOCALARCH $TOOLCHAIN_DIR`
	export PATH=$TOOLCHAIN_DIR/bin:$PATH
fi

###################################################################################
# Clean project
###################################################################################
if [ x"$CLEAN" = x"yes" ]; then
	echo "##############################################################################"
	echo "# Clean project (platform: $PLATFORMS, distros: $DISTROS, builddir: $BUILD_DIR"
	echo "##############################################################################"
	platfroms=`echo $PLATFORMS | tr ',' ' '`
	for plat in ${platfroms[*]}; do
		build-platform.sh clean --cross=$CROSS_COMPILE --platform=$plat --distros=$DISTROS --output=$BUILD_DIR
	done
	echo "Clean binary files done!"
	exit 0
fi

###################################################################################
# Download/uncompress distros
###################################################################################
echo "##############################################################################"
echo "# Download distros (distros: $DISTROS)"
echo "##############################################################################"
mkdir -p distro
download_distros distro $TOPDIR/checksum/linux $ESTUARY_INTERAL_FTP/linux $DISTROS
if [[ $? != 0 ]]; then
	echo -e "\033[31mError! Download distros failed!\033[0m" ; exit 1
fi

echo "##############################################################################"
echo "# Uncompress distros (distros: $DISTROS)"
echo "##############################################################################"
if ! uncompress_distros $DISTROS distro $BUILD_DIR/distro; then
	echo -e "\033[31mError! Uncompress distro files failed!\033[0m" ; exit 1
fi

###################################################################################
# Download binaries
###################################################################################
echo "##############################################################################"
echo "# Download binaries"
echo "##############################################################################"
mkdir -p prebuild
download_binaries prebuild $TOPDIR/checksum/prebuild $ESTUARY_INTERAL_FTP
if [[ $? != 0 ]]; then
	echo -e "\033[31mError! Download binaries failed!\033[0m" ; exit 1
fi

###################################################################################
# Build project
###################################################################################
platfroms=`echo $PLATFORMS | tr ',' ' '`
for plat in ${platfroms[*]}; do
	echo "##############################################################################"
	echo "# Build platform (platform: $plat, distros: $DISTROS, pkgs: $PACKAGES, builddir: $BUILD_DIR)"
	echo "##############################################################################"
	build-platform.sh --cross=$CROSS_COMPILE --platform=$plat --distros=$DISTROS --packages=$PACKAGES --output=$BUILD_DIR
	if [ $? -ne 0 ]; then
		exit 1
	fi
done
echo "Build estuary done!"

###################################################################################
# Copy binaries ...
###################################################################################

###################################################################################
# Quick Deployment
###################################################################################
echo "##############################################################################"
echo "# Quick deployment"
echo "##############################################################################"


