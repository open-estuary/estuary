#!/bin/bash
###################################################################################
# ./estuary/build.sh --help
# ./estuary/build.sh --file=./estuary/estuarycfg.json --builddir=build
# ./estuary/build.sh clean --file=./estuary/estuarycfg.json --builddir=build
# ./estuary/build.sh --builddir=./workspace --pkg=armor,docker --platform=D03,D05,HiKey --distro=Ubuntu,OpenSuse
# ./estuary/build.sh --builddir=./workspace --pkg=armor,docker --platform=D03,D05,HiKey --distro=Ubuntu,OpenSuse --deploy=pxe --mac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 --deploy=usb:/dev/sdb --deploy=iso --capacity=50,50
###################################################################################
DEFAULT_ESTUARYCFG="./estuary/estuarycfg.json"
SUPPORT_PLATFORMS=(`sed -n '/^\"system\":\[/,/^\]/p' $DEFAULT_ESTUARYCFG 2>/dev/null | sed 's/\"//g' | grep -Po "(?<=platform:)(.*?)(?=,)" | sort`)
SUPPORT_DISTROS=(`sed -n '/^\"distros\":\[/,/^\]/p' $DEFAULT_ESTUARYCFG 2>/dev/null | sed 's/\"//g' | grep -Po "(?<=name:)(.*?)(?=,)" | sort`)
SUPPORT_PACKAGES=(`sed -n '/^\"packages\":\[/,/^\]/p' $DEFAULT_ESTUARYCFG 2>/dev/null | sed 's/\"//g' | grep -Po "(?<=name:)(.*?)(?=,)" | sort`)

###################################################################################
# Const Variables, PATH
###################################################################################
LOCALARCH=`uname -m`
CURDIR=`pwd`
TOPDIR=$(cd `dirname $0` ; pwd)
if [ x"$CURDIR" = x"$TOPDIR" ]; then
	echo "---------------------------------------------------------------"
	echo "- Please execute build.sh in open-estuary project root directory!"
	echo "- Example:"
	echo "-     ./estuary/build.sh --file=./estuary/estuarycfg.json --builddir=build"
	echo "---------------------------------------------------------------"
	exit 1
fi

DOWNLOAD_FTP_ADDR=`grep -Po "(?<=estuary_interal_ftp: )(.*)" $TOPDIR/estuary.txt`
CHINA_INTERAL_FTP_ADDR=`grep -Po "(?<=china_interal_ftp: )(.*)" $TOPDIR/estuary.txt`

export PATH=$TOPDIR:$TOPDIR/include:$TOPDIR/submodules:$TOPDIR/deploy:$PATH

export LC_ALL=C
export LANG=C

###################################################################################
# Includes
###################################################################################
. $TOPDIR/Include.sh

###################################################################################
# Global Variables
###################################################################################
CLEAN= # Clean binary files
ESTUARY_FTP_CFGFILE= # Estuary FTP configuration file
CFG_FILE= # JSON configuration file
BUILD_DIR= # Build output directory
CROSS_COMPILE= # Cross compile

TOOLCHAIN= # Toolchain file name
TOOLCHAIN_DIR= # Toolchain directory

PLATFORMS= # Platforms to build
DISTROS= # Distros to build
PACKAGES= # Pakcages to build and install

DEPLOY=() # Deploy
CAPACITY=
BOARDS_MAC=

INSTALL= # toolchain/caliper

###################################################################################
# Usage
###################################################################################
Usage()
{
	local platforms=`echo ${SUPPORT_PLATFORMS[*]} | sed 's/ /, /g'`
	local distros=`echo ${SUPPORT_DISTROS[*]} | sed 's/ /, /g'`
	local packages=`echo ${SUPPORT_PACKAGES[*]} | sed 's/ /, /g'`

cat << EOF
Usage: ./estuary/build.sh [options]
Options:
	-h, --help: Display this information
	-v, --version: print estuary version
	clean: Clean all binary files

	-i: Insall Caliper, toolchain
	-f, --file: JSON configuration file
	-p, --platform: the target platform, the -d must be specified if platform is QEMU
		* support platforms: $platforms
	-d, --distro: the distribuations, the -p must be specified if -d is specified
		* support distros: $distros
	--pkg: packages to install, the -d/--distros must be specified if --pkgs is specified
		* support packages: $packages

	--builddir: Build output directory, default is build

	--deploy: quick deploy type and target device
		* for example: --deploy=usb:/dev/sdb, --deploy=iso, --deploy=pxe
	--capacity: target distro partition size, default unit is GB
	--mac: target board mac address, --mac must be specified if deploy type is pxe

	-a: download address, China or Estuary(default Estuary)

Example:
	./estuary/build.sh --help

	./estuary/build.sh -f ./estuary/estuarycfg.json
	./estuary/build.sh -f ./estuary/estuarycfg.json -a Estuary
	./estuary/build.sh -f ./estuary/estuarycfg.json -a China

	./estuary/build.sh -p QEMU -d Ubuntu
	./estuary/build.sh -f ./estuary/estuarycfg.json --builddir=./workspace
	./estuary/build.sh --file=./estuary/estuarycfg.json --builddir=./workspace
	./estuary/build.sh clean --file=./estuary/estuarycfg.json --builddir=./workspace

	./estuary/build.sh --builddir=./workspace --platform=D03,D05,HiKey --distro=Ubuntu,OpenSuse
	./estuary/build.sh --builddir=./workspace \\
		--platform=D03,D05,HiKey --distro=Ubuntu,OpenSuse --pkg=armor,docker \\
		--deploy=pxe --mac=01-00-18-82-05-00-7f,01-00-18-82-05-00-68 \\
		--deploy=usb:/dev/sdb --deploy=iso --capacity=50,50

EOF
}

###################################################################################
# Get all args
###################################################################################
while test $# != 0
do
        case $1 in
        	--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=: ;;
        	-*) ac_option=$1 ; ac_optarg=$2; ac_shift=shift ;;
        	*) ac_option=$1 ; ac_shift=: ;;
        esac

        case $ac_option in
                clean) CLEAN=yes ;;
                -h | --help) Usage ; exit 0 ;;
                -i) INSTALL=$ac_optarg ;;
                -v | --version) print_version ./estuary ; exit 0 ;;
                -f | --file) eval CFG_FILE=$ac_optarg ;;
                -p | --platform) PLATFORMS=$ac_optarg ;;
                -d | --distro) DISTROS=$ac_optarg ;;
                --pkg) PACKAGES=$ac_optarg ;;
                --builddir) eval BUILD_DIR=$ac_optarg ;;
                --deploy) DEPLOY[${#DEPLOY[@]}]=$ac_optarg ;;
                --capacity) CAPACITY=$ac_optarg ;;
                --mac) BOARDS_MAC=$ac_optarg ;;
                -a) if [ x"$ac_optarg" = x"China" ]; then DOWNLOAD_FTP_ADDR=$CHINA_INTERAL_FTP_ADDR; fi ;;
                *) Usage ; echo "Unknown option $1" ; exit 1 ;;
        esac
	
        $ac_shift
        shift
done

###################################################################################
# Default values
###################################################################################
BUILD_DIR=${BUILD_DIR:-build}

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
if [ x"$CFG_FILE" != x"" ]; then
	PLATFORMS=$(get_install_platforms $CFG_FILE | tr ' ' ',')
	DISTROS=$(get_install_distros $CFG_FILE | tr ' ' ',')

	DEPLOY=($(get_deploy_info $CFG_FILE))
	CAPACITY=`get_install_capacity $CFG_FILE | tr ' ' ','`
	BOARDS_MAC=`get_boards_mac $CFG_FILE | tr ' ' ','`
fi

cat << EOF
##############################################################################
# PLAT:     $PLATFORMS
# DISTRO:   $DISTROS
# PKG:      $PACKAGES
# BUILDDIR: $BUILD_DIR
# DEPLOY:   ${DEPLOY[@]}
# CAPACITY: $CAPACITY
# MAC:      $BOARDS_MAC
# INSTALL:  $INSTALL
##############################################################################

EOF

###################################################################################
# Check args
###################################################################################
if [ x"$INSTALL" = x"" ]; then
	if [ x"$PLATFORMS" = x"" ] || [ x"$DISTROS" = x"" ]; then
		Usage
		echo -e "\033[31mError! Platform and distro must be specified!\033[0m" ; exit 1
	fi
fi

if [ ${#DEPLOY[@]} -ge 1 ]; then
	if echo "${DEPLOY[@]}" | grep -w pxe >/dev/null && [ -z $BOARDS_MAC ]; then
		echo -e "\033[31mError! Target board mac must be specified for pxe deploy!\033[0m" ; exit 1
	fi

	capacity=(`echo $CAPACITY | tr ',' ' '`)
	distros=(`echo $DISTROS | tr ',' ' '`)
	if [ ${#capacity[@]} -eq 0 ] || [ ${#capacity[@]} -ne ${#distros[@]} ]; then
		echo -e "\033[31mError! Capacity for each distro must be specified!\033[0m" ; exit 1
	fi
fi

###################################################################################
# Update Estuary FTP configuration file
###################################################################################
estuary_version=`get_estuary_version ./estuary`
ESTUARY_FTP_CFGFILE="${estuary_version}.xml"
if ! check_ftp_update $estuary_version ./estuary; then
	echo "##############################################################################"
	echo "# Update estuary configuration file"
	echo "##############################################################################"
	if ! update_ftp_cfgfile $estuary_version $DOWNLOAD_FTP_ADDR ./estuary; then
		echo -e "\033[31mError! Update Estuary FTP configuration file failed!\033[0m" ; exit 1
	fi
	rm -f distro/.*.sum distro/*.sum 2>/dev/null
	rm -f prebuild/.*.sum prebuild/*.sum 2>/dev/null
	rm -f toolchain/.*.sum toolchain/*.sum 2>/dev/null
fi

###################################################################################
# Download/uncompress toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
	echo "##############################################################################"
	echo "# Download/Uncompress toolchain"
	echo "##############################################################################"
	mkdir -p toolchain
	download_toolchains $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR toolchain
	if [[ $? != 0 ]]; then
		echo -e "\033[31mError! Download toolchains failed!\033[0m" >&2 ; exit 1
	fi

	if ! uncompress_toolchains $ESTUARY_FTP_CFGFILE toolchain; then
		echo -e "\033[31mError! Uncompress toolchains failed!\033[0m" >&2 ; exit 1
	fi
	
	toolchain=`get_toolchain $ESTUARY_FTP_CFGFILE arm`
	toolchain_dir=`get_compress_file_prefix $toolchain`
	export PATH=`pwd`/toolchain/$toolchain_dir/bin:$PATH

	toolchain=`get_toolchain $ESTUARY_FTP_CFGFILE aarch64`
	toolchain_dir=`get_compress_file_prefix $toolchain`

	TOOLCHAIN=$toolchain
	TOOLCHAIN_DIR=`cd toolchain/$toolchain_dir; pwd`
	CROSS_COMPILE=`get_cross_compile $LOCALARCH $TOOLCHAIN_DIR`
	export PATH=$TOOLCHAIN_DIR/bin:$PATH
fi

###################################################################################
# Install toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ] && [ x"$INSTALL" = x"toolchain" ]; then
	echo "##############################################################################"
	echo "# Install toolchain"
	echo "##############################################################################"
	if ! install_toolchain $ESTUARY_FTP_CFGFILE toolchain; then
		echo -e "\033[31mError! Install toolchains failed!\033[0m" ; exit 1 
	fi
	echo "Install toolchain done."
	echo ""
fi

###################################################################################
# Install Caliper for Estuary
###################################################################################
if [ x"$INSTALL" = x"Caliper" ]; then
	echo "##############################################################################"
	echo "# Install caliper"
	echo "##############################################################################"
	pushd caliper >/dev/null
	echo "Installing Caliper..."
	if ! sudo python setup.py install; then
		echo -e "\033[31mError! Installing Caliper failed!\033[0m" ; exit 1
	fi
	popd >/dev/null
	echo "Install Caliper done."
	echo ""
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
	
	rm -f $BUILD_DIR/binary/arm64/Estuary.iso 2>/dev/null
	echo "Clean binary files done!"
	exit 0
fi

###################################################################################
# Download/uncompress distros
###################################################################################
if [ x"$DISTROS" != x"" ]; then
	echo "##############################################################################"
	echo "# Download distros (distros: $DISTROS)"
	echo "##############################################################################"
	mkdir -p distro
	download_distros $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR distro $DISTROS
	if [[ $? != 0 ]]; then
		echo -e "\033[31mError! Download distros failed!\033[0m" ; exit 1
	fi
	echo ""

	echo "##############################################################################"
	echo "# Uncompress distros (distros: $DISTROS)"
	echo "##############################################################################"

	if ! uncompress_distros $DISTROS distro $BUILD_DIR/distro; then
		echo -e "\033[31mError! Uncompress distro files failed!\033[0m" ; exit 1
	fi
	echo ""
fi

###################################################################################
# Download binaries
###################################################################################
if [ x"$PLATFORMS" != x"" ]; then
	echo "##############################################################################"
	echo "# Download binaries"
	echo "##############################################################################"
	mkdir -p prebuild
	download_binaries $ESTUARY_FTP_CFGFILE $DOWNLOAD_FTP_ADDR prebuild
	if [[ $? != 0 ]]; then
		echo -e "\033[31mError! Download binaries failed!\033[0m" ; exit 1
	fi
fi
echo ""

###################################################################################
# Copy toolchains
###################################################################################
if [ x"$LOCALARCH" = x"x86_64" ]; then
	echo "##############################################################################"
	echo "# Copy toolchains"
	echo "##############################################################################"
	mkdir -p $BUILD_DIR/binary/arm64 2>/dev/null
	if ! copy_toolchains $ESTUARY_FTP_CFGFILE toolchain $BUILD_DIR/binary/arm64; then
		echo -e "\033[31mError! Copy toolchains failed!\033[0m" ; exit 1
	fi
fi

###################################################################################
# Copy binaries/docs ...
###################################################################################
if [ x"$PLATFORMS" != x"" ]; then
	echo "##############################################################################"
	echo "# Copy binaries/docs"
	echo "##############################################################################"
	platfroms=`echo $PLATFORMS | tr ',' ' '`
	binary_src_dir="./prebuild"
	doc_src_dir="./estuary/doc"

	mkdir -p $BUILD_DIR/binary
	mkdir -p $BUILD_DIR/doc

	if ! Copy_deploy_utils $binary_src_dir/deploy-utils.tar.bz2 estuary/deploy/setup.sh $BUILD_DIR/binary/arm64; then
		echo -e "\033[31mError! Copy deploy utils failed!\033[0m" ; exit 1
	fi

	if ! copy_all_binaries $PLATFORMS $binary_src_dir $BUILD_DIR/binary; then
		echo -e "\033[31mError! Copy binaries failed!\033[0m" ; exit 1
	fi

	if ! copy_all_docs $PLATFORMS $doc_src_dir $BUILD_DIR/doc; then
		echo -e "\033[31mError! Copy docs failed!\033[0m" ; exit 1
	fi
fi

###################################################################################
# Build project
###################################################################################
if [ x"$PLATFORMS" != x"" ]; then
	echo "##############################################################################"
	echo "# Build platforms"
	echo "##############################################################################"
	platfroms=`echo $PLATFORMS | tr ',' ' '`
	for plat in ${platfroms[*]}; do
		echo "/*---------------------------------------------------------------"
		echo "- build platform (platform: $plat, distros: $DISTROS, builddir: $BUILD_DIR, cfgfile: ${CFG_FILE})"
		echo "---------------------------------------------------------------*/"
		build-platform.sh --cross=$CROSS_COMPILE --platform=$plat --distros=$DISTROS --output=$BUILD_DIR  --file=${CFG_FILE}
		if [ $? -ne 0 ]; then
			exit 1
		fi
		echo ""
	done

	echo "/*---------------------------------------------------------------"
	echo "- create distros (distros: $DISTROS, distro dir: $BUILD_DIR/distro)"
	echo "---------------------------------------------------------------*/"
	if ! create_distros $DISTROS $BUILD_DIR/distro; then
		echo -e "\033[31mError! Create distro files failed!\033[0m" ; exit 1
	fi

	echo "Build platfroms done!"
	echo ""
fi

###################################################################################
# Quick Deployment
###################################################################################
if [ ${#DEPLOY[@]} -ne 0 ]; then
	echo "##############################################################################"
	echo "# Quick deployment"
	echo "##############################################################################"
	if [ x"$PLATFORMS" != x"" ] && [ x"$DISTROS" != x"" ]; then
		for dep in ${DEPLOY[*]}; do
			deploy_type=`get_deploy_type $dep`
			deploy_device=`get_deploy_device $dep`
			echo "/*---------------------------------------------------------------"
			echo "- deploy type: $deploy_type, target device: $deploy_device, boards mac: $BOARDS_MAC"
			echo "- platform: $PLATFORMS, distros: $DISTROS, capacity: $CAPACITY"
			echo "- binary directory: $BUILD_DIR/binary/arm64"
			echo "---------------------------------------------------------------*/"
			quick-deploy.sh --target=$deploy_type:$deploy_device --boardmac=$BOARDS_MAC --platform=$PLATFORMS \
				--distros=$DISTROS --capacity=$CAPACITY --binary=$BUILD_DIR/binary/arm64
			if [[ $? -ne 0 ]]; then
				echo "Deploy of $deploy_type failed!" >&2 ; exit 1
			fi
			echo ""
		done

		echo ""
		echo "Create quick deploy done!"
	fi

	echo ""
fi

###################################################################################
# Build and run QEMU
###################################################################################
if echo $PLATFORMS | tr ',' ' ' | grep -w QEMU >/dev/null 2>&1; then
	echo "##############################################################################"
	echo "# Build and run QEMU"
	echo "##############################################################################"
	build-qemu.sh --output=$BUILD_DIR --distros=$DISTROS
fi
echo ""

###################################################################################
# Create binary softlink
###################################################################################
echo "##############################################################################"
echo "# Create binary/distro softlink"
echo "##############################################################################"
# Please note that the platform directory must be in the same level directory with arm64!
# We'll not check the softlink under arm64 (copy it directly).
platforms=`echo $PLATFORMS | tr ',' ' '`
distros=`echo $DISTROS | tr ',' ' '`
for plat in ${platforms[*]}; do
	plat_dir=$BUILD_DIR/binary/$plat
	mkdir -p $plat_dir 2>/dev/null
	pushd $plat_dir >/dev/null
	find . -maxdepth 1 -type l -print | xargs rm -f
	find ../arm64/ -maxdepth 1 -type f | xargs -i ln -s {}
	find ../arm64 -type l | xargs -i cp -a {} ./
	popd >/dev/null
done

echo "Create binary/distro softlink done!"
echo ""

###################################################################################
#
###################################################################################
echo "Build Estuary done!"

