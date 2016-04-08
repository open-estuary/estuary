#!/bin/bash
#Description: download necessary files firstly, then build target system according to parameters indicated by user
#Use case:
#   ./build.sh -h:                  to get help information for this script
#   ./build.sh -p D02 -d Ubuntu:    to build Ubuntu distribution for D02 platform
#   ./build.sh -f estuarycfg.json:  to build target system according to estuarycfg.json
#   ./build.sh -p D02 -d Ubuntu -s usb:/dev/sdb:    to build Ubuntu distribution for D02 platform and create install disk on usb device /dev/sdb
#   ./build.sh -p D02 -d Ubuntu -s usb:    to build Ubuntu distribution for D02 platform and create install disk on first usb device
#   ./build.sh -p D02 -d Ubuntu -s iso:Estuary_D02.iso: to build Ubuntu distribution for D02 platform and create install iso image Estuary_D02.iso
#   ./build.sh -p D02 -d Ubuntu -s iso: to build Ubuntu distribution for D02 platform and create install iso image Estuary.iso (default iso image name is Estuary.iso)
#Author: Justin Zhao
#Date: August 7, 2015

###################################################################################
############################# Variables definition         ########################
###################################################################################
LOCALARCH=`uname -m`
#core number for building
corenum=36
distros=(Ubuntu OpenSuse Fedora Debian CentOS)
distros_arm32=(Ubuntu)
distros_arm64=(Ubuntu OpenSuse Fedora Debian CentOS)
platforms=(QEMU D01 D02 D03 HiKey)
installs=(Caliper toolchain)

#PATH_DISTRO=http://7xjz0v.com1.z0.glb.clouddn.com/dist
#arm64 distributions
#PATH_OPENSUSE64=http://download.opensuse.org/ports/aarch64/distribution/13.2/appliances/openSUSE-13.2-ARM-JeOS.aarch64-rootfs.aarch64-Current.tbz
#PATH_UBUNTU64=https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-arm64.tar.gz
#PATH_FEDORA64=http://dmarlin.fedorapeople.org/fedora-arm/aarch64/F21-20140407-foundation-v8.tar.xz
PATH_OPENSUSE64=default
PATH_UBUNTU64=default
PATH_FEDORA64=default
PATH_DEBIAN64=default
PATH_CENTOS64=default
#arm32 distributions
#PATH_OPENSUSE32=http://download.opensuse.org/ports/armv7hl/distribution/13.2/appliances/openSUSE-13.2-ARM-XFCE.armv7-rootfs.armv7l-1.12.1-Build33.7.tbz
#PATH_UBUNTU32=http://releases.linaro.org/15.02/ubuntu/lt-d01/linaro-utopic-server-20150220-698.tar.gz
#PATH_OPENSUSE32=default
PATH_UBUNTU32=default

DEPRECATED_PARAMETER=0

DEFAULT_ISO_FILE="Estuary.iso"
INSTALL_ISO_IMG=
INSTALL_UDISK_DEV=

###################################################################################
############################# Print help information       ########################
###################################################################################
usage()
{
	echo "usage:"
	echo -n "build.sh [ -f cfgfile.json ] [ -p "
	echo -n ${platforms[*]} | sed "s/ / | /g"
	echo -n " ] [ -c uefi|grub|kernel|distro "
	echo -n " ] [ -d "
	echo -n ${distros[*]} | sed "s/ / | /g"
	echo -n " ] [ -i "
	echo -n ${installs[*]} | sed "s/ / | /g"
	echo -n " ] "
	echo "[ -s usb[:/dev/sdx] ] [ -s iso[:Estuary.iso]]"

	echo -e "\n -h,--help: to print this message"
	echo " -f,--file: the config json file for Estuary building, all other parameters will be disabled if -f is set"
	echo " -p,--platform: the target platform, the -d must be specified if platform is QEMU"
	echo " -c,--clear: to clear the specified build target so that it'll be rebuilt for next building, the -p must be specified before it if the platform is specified"
	echo " -d,--distro: the distribuation, the -p must be specified if -d is specified"
	echo "		*for D01, only support Ubuntu"
	echo "		*for D02,D03,HiKey, support Ubuntu, OpenSuse, Fedora, Debian, CentOS"
    echo " -i,--install: to install target into local host machine"
	echo "		*for Caliper, to install Caliper as the benchmark tools"
	echo "		*for toolchain, to install ARM cross compiler"
	echo " -s,--setup: to create install usb disk or iso image"
	echo "		*only support D02, D03"
	echo "		*for usb device, you can use -s usb:/dev/sdx to create the install disk on /dev/sdx or -s usb to create install disk on the first usb device"
	echo "		*for iso, you can use -s iso:Estuary_D02.iso to create the install iso image Estuary_D02.iso or -s iso to create Estuary.iso by default"
	echo " -v,--version: to print the version of estuary project"
}

###################################################################################
############################# Print version #######################################
###################################################################################
print_version()
{
	version_regexp="(?<=<project name=\"estuary\" revision=\")([^\"]*)(?=\")"
	default_xml_file="`dirname $1`/default.xml"
	current_version=`grep -Po "$version_regexp" $default_xml_file 2>/dev/null | sed 's/.*\///g' 2>/dev/null`
	if [ x"$current_version" = x"" ]; then
		echo "This is a developing version."
	else
		echo "Estuary version is $current_version."
	fi
}

###################################################################################
############################# Check distribution parameter ########################
###################################################################################
check_distro()
{
	if [ x"D01" = x"$PLATFORM" ]; then
		for dis in ${distros_arm32[@]}; do
			if [ x"$dis" = x"$1" ]; then 
				DISTRO=$1
				return
			fi
		done
	elif [ x"" != x"$PLATFORM" ]; then
		for dis in ${distros_arm64[@]}; do
			if [ x"$dis" = x"$1" ]; then 
				DISTRO=$1
				return
			fi
		done
	fi

	if [ x"" = x"$PLATFORM" ]; then
		echo -e "\033[31mMust specify a platform(-p) before distribution(-d).\033[0m"
	else
		echo -e "\033[31mError distribution!\033[0m"
	fi
    usage
	exit 1
}

###################################################################################
############################# Check platform parameter  ###########################
###################################################################################
check_platform()
{
	for plat in ${platforms[@]}; do
		if [ x"$plat" = x"$1" ]; then 
			PLATFORM=$1
			return
		fi
	done

	echo -e "\033[31mError platform!\033[0m"
    usage
	exit 1
}

###################################################################################
############################# Check setup parameter ########################
###################################################################################
check_setup_param()
{
	if [ x"$INSTALL_ISO_IMG" != x"" ]; then
		if [ x"D02" != x"$PLATFORM" ] && [ x"D03" != x"$PLATFORM" ]; then
			return 1
		fi
	fi

	if [ x"$INSTALL_UDISK_DEV" != x"" ]; then
		if [ x"D02" != x"$PLATFORM" ] && [ x"D03" != x"$PLATFORM" ]; then
			return 1
		fi
	fi

	return 0
}

###################################################################################
############################# Clear build target  #################################
###################################################################################
clear_target()
{
	if [ x"" = x"$PLATFORM" ]; then
		sudo rm -rf $build_dir
		echo "Cleared all"
	else
		sudo rm -rf $build_dir/$PLATFORM/$1
		echo "Cleared $1"
	fi

	exit 0 
}

###################################################################################
########################### Check build log ######################################
###################################################################################
check_build_log()
{
	local module_src=$1
	local binary_output_dir=$2
	local module_build_dir=$3
	local last_build_commit=`cat "${binary_output_dir}/.${module_src}.bld" 2>/dev/null`
	pushd $module_src
	local current_commit=`git log -n 1 | grep -Po "^(commit ).*" | grep -Po "(?<=commit )(.*)"`
	popd
	if [ x"$current_commit" != x"$last_build_commit" ]; then
		sudo rm -rf $module_build_dir/*
		return 1
	fi

	return 0
}

###################################################################################
########################### Create build log ######################################
###################################################################################
create_build_log()
{
	local module_src=$1
	local binary_output_dir=$2
	pushd $module_src
	local current_commit=`git log -n 1 | grep -Po "^(commit ).*" | grep -Po "(?<=commit )(.*)"`
	popd
	echo "$current_commit" > ${binary_output_dir}/.${module_src}.bld
}

###################################################################################
############################# Check install parameter  ###########################
###################################################################################
check_install()
{
	for inst in ${installs[@]}; do
		if [ x"$inst" = x"$1" ]; then 
			INSTALL=$1
			return
		fi
	done

	echo -e "\033[31mError install target!\033[0m"
    usage
	exit 1
}

###################################################################################
############################# Check initilization status ##########################
###################################################################################
lastupdate="2015-10-15"
check_init()
{
    tmpfile=$1
    tmpdate=$2

    if [ -f "$tmpfile" ]; then
        inittime=`stat -c %Y $tmpfile`
        checktime=`date +%s -d $tmpdate`

        if [ $inittime -gt $checktime ]; then
            return 1
        fi
    fi

    return 0
}

###################################################################################
########################### Get setup iso/usb args ################################
###################################################################################
get_setup_args()
{
	local arg=$1
	local setup_type=`echo "$arg" | awk -F ':' '{print $1}'`
	local output_dev=`echo "$arg" | awk -F ':' '{print $2}'`
	if [ x"iso" = x"$setup_type" ]; then
		if [ x"$output_dev" != x"" ]; then
			INSTALL_ISO_IMG=$output_dev
		else
			INSTALL_ISO_IMG=$DEFAULT_ISO_FILE
		fi
	else
		if [ x"$output_dev" != x"" ]; then
			INSTALL_UDISK_DEV=$output_dev
			if [ ! -b "$INSTALL_UDISK_DEV" ]; then
				echo -e "\033[31mError! Device $INSTALL_UDISK_DEV is not exist!\033[0m" ; return 1
			fi

			sudo lshw | grep "bus info: usb" -A 12 | grep "logical name: $INSTALL_UDISK_DEV"
			if [ x"$?" != x"0" ]; then
				echo -e "\033[31mError! Device $INSTALL_UDISK_DEV is not an usb disk!\033[0m" ; return 1
			fi 
		else
			INSTALL_UDISK_DEV=`get_1st_usb_storage`
			if [ x"$INSTALL_UDISK_DEV" = x"" ]; then
				echo -e "\033[31mError! Can't find usb storage disk!\033[0m" ; return 1
			fi
		fi 
	fi

	return 0
}

###################################################################################
####################### Get first usb storage device ##############################
###################################################################################
get_1st_usb_storage()
{
	local root_dev=$(mount | grep " / " | grep  -Po "(/dev/sd[^ ]*)")
	if [ x"" = x"$root_dev" ]; then
		root_dev="/dev/sdx"
	fi
	
	local usb_devs=()
	read -a usb_devs <<< $(sudo lshw | grep "bus info: usb" -A 12 | grep "logical name: /dev/sd" | grep -v $root_dev | grep -Po "(/dev/sd.*)" | sort)
	echo ${usb_devs[0]}
}

###################################################################################
############################# Check the checksum file   ###########################
###################################################################################
FAILED_STR="FAILED"
check_sum()
{
    checksum_source=$1
    if [ x"$checksum_source" = x"" ]; then
        echo "Invalidate checksum file!"
        return 1
    fi

    checksum_file=${checksum_source##*/}

	touch $checksum_file
	diff $checksum_source $checksum_file >/dev/null
	if [ x"0" != x"$?" ]; then
		rm -rf ".$checksum_file" >/dev/null
		cp $checksum_source ./
	fi

    check_init ".$checksum_file" $lastupdate
	if [ x"$?" = x"1" ]; then
		return 0
	fi

	md5sum --quiet --check $checksum_file 2>/dev/null | grep "$FAILED_STR" >/dev/null
	if [ x"$?" = x"0" ]; then
        return 1
	else
		touch ".$checksum_file"
        return 0
	fi
}

###################################################################################
############################# Setup host environment ##############################
###################################################################################
install_development_tools()
{
	if [ x"$LOCALARCH" = x"x86_64" ]; then
		development_tools="wget automake1.11 make bc libncurses5-dev libtool libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex uuid-dev build-essential iasl jq genisoimage"
	else
		development_tools="wget automake1.11 make bc libncurses5-dev libtool libc6 libncurses5 libstdc++6 bison flex uuid-dev build-essential iasl acpica-tools jq genisoimage"
	fi

	sudo apt-get install -y --force-yes $development_tools
}

update_acpica_tools()
{
	if [ ! -d acpica ]; then
		git clone https://github.com/acpica/acpica.git
	fi

	(cd acpica/generate/unix && make -j${corenum} && sudo make install)
}

automake --version 2>/dev/null | grep 'automake (GNU automake) 1.11' >/dev/null
if [ x"$?" = x"1" ]; then
	sudo apt-get remove -y --purge automake*
    rm -rf ".initialized"
fi

check_init ".initialized" $lastupdate
if [ x"0" = x"$?" ]; then
	sudo apt-get update
	
	# Install development tools
	install_development_tools
	if [ x"$?" != x"0" ]; then
		echo -e "\033[31mError! Failed to install development tools!\033[0m"
		exit 1
	fi

	# Check if iasl needs to update
	iasl_version=`iasl -v 2>/dev/null | grep -Po "(?<=version )(\d+)(?=.*)" 2>/dev/null`
	if [[ x"$iasl_version" < x"20150214" ]]; then
		update_acpica_tools
		if [ x"$?" != x"0" ]; then
			echo -e "\033[31mError! Failed to update iasl!\033[0m"
			exit 1
		fi
	fi

	touch ".initialized"
fi

export LC_ALL=C
export LANG=C

TOOLS_DIR="`dirname $0`"
cd $TOOLS_DIR/../
PRJROOT=${PWD}
build_dir=build


###################################################################################
############################# Set download source server ##########################
###################################################################################
PATH_DISTRO=http://open-estuary.org/EstuaryDownloads/cleandistro/pre_release/linux/v2.2/rc1
TOOLCHAIN_SOURCE=http://open-estuary.org/EstuaryDownloads/toolchain
BINARY_SOURCE=http://open-estuary.org/EstuaryDownloads/prebuild/v2.2/rc1

###################################################################################
############################# Get setup parameter #################################
###################################################################################
get_setup_parameter()
{
	local cfg_file=$1
	local install_type=
	local iso_image=
	local idx=0
	local install=`jq -r ".setup[$idx].install" $cfg_file`
	while [ x"$install" != x"null" ];
	do
		if [ x"yes" = x"$install" ]; then
			install_type=`jq -r ".setup[$idx].type" $cfg_file`
			if [ x"iso" = x"$install_type" ]; then
				INSTALL_ISO_IMG=$DEFAULT_ISO_FILE
				iso_image=`jq -r ".setup[$idx].name" $cfg_file`
				if [ x"null" != x"$iso_image" ]; then
					INSTALL_ISO_IMG=$iso_image
				fi
			else
				INSTALL_UDISK_DEV=`jq -r ".setup[$idx].device" $cfg_file`
				if [ x"$INSTALL_UDISK_DEV" = x"/dev/sdx" ]; then
					INSTALL_UDISK_DEV=`get_1st_usb_storage`
					if [ x"$INSTALL_UDISK_DEV" = x"" ]; then
						echo -e "\033[31mError! Can't find available usb storage!\033[0m" ; return 1
					fi
				else
					if [ ! -b "$INSTALL_UDISK_DEV" ]; then
						echo -e "\033[31mError! Device $INSTALL_UDISK_DEV is not exist!\033[0m" ; return 1
					fi

					sudo lshw | grep "bus info: usb" -A 12 | grep "logical name: $INSTALL_UDISK_DEV"
					if [ x"$?" != x"0" ]; then
						echo -e "\033[31mError! Device $INSTALL_UDISK_DEV is not an usb disk!\033[0m" ; return 1
					fi
				fi
			fi
		fi
		let idx=$idx+1
		install=`jq -r ".setup[$idx].install" $cfg_file`
	done

	return 0
}

###################################################################################
############################# Parse config file        ############################
###################################################################################
PLATFORM=
DISTRO=
DISTROLS=()
INSTALL=
CFGFILE=
parse_cfg()
{
    if [ ! -f $CFGFILE ]; then
	    echo -e "\033[31m$CFGFILE does not exist!\033[0m"
        usage
        exit 1
    fi

    PLATFORM=`jq -r ".system.platform" $CFGFILE`

    if [ x"0" != x"$?" ]; then
	    echo -e "\033[31mDo not find the .system.platform in $CFGFILE!\033[0m"
        usage
		exit 1
    fi

	idx=0
    install=`jq -r ".distros[$idx].install" $CFGFILE`
	while [ x"$install" != x"null" ];
	do
		if [ x"yes" = x"$install" ]; then
    		DISTROLS[${#DISTROLS[@]}]=`jq -r ".distros[$idx].name" $CFGFILE`
		fi
		let idx=$idx+1
    	install=`jq -r ".distros[$idx].install" $CFGFILE`
	done

	check_platform $PLATFORM
	for tmp in "${DISTROLS[@]}"
	do
		check_distro $tmp
	done

	DISTRO=$DISTROLS

	get_setup_parameter $CFGFILE
	if [ x"$?" != x"0" ]; then
		exit 1
	fi
}

###################################################################################
############################# Check all parameters     ############################
###################################################################################
while [ x"$1" != x"" ]; do 
    case $1 in 
        "-h" | "--help" )
			usage
			exit
			;;
		"-v" | "--version" )
			print_version $0
			exit;
			;;
		"-p" | "--platform" )
			shift
			check_platform $1
			echo "Platform: $1"
			let DEPRECATED_PARAMETER=$DEPRECATED_PARAMETER+1
			;;
		"-c" | "--clear" )
			shift
			clear_target $1
			echo "Clear target: $1"
			;;
		"-d" | "--distro" )
			shift
			check_distro $1
			echo "Distro: $1"
			let DEPRECATED_PARAMETER=$DEPRECATED_PARAMETER+1
			;;
		"-i" | "--install" )
			shift
			check_install $1
			echo "Install: $1"
			;;
		"-f" | "--file" )
			shift
            CFGFILE="${PWD}/$1"
            parse_cfg
			echo "Install: $DISTRO"
            break
			;;
		"-s" | "--setup" )
			shift
			get_setup_args $1 || exit 1
			shift
			;;
		* )
			echo "unknown arg $1"
			usage
			exit 1
			;;
    esac
	shift
done

# Default to add $DISTRO into distro list if don't use config file
if [ x"" = x"$CFGFILE" ]; then
	DISTROLS[${#DISTROLS[@]}]=$DISTRO
fi

if [ x"$PLATFORM" = x"" -a x"$DISTRO" != x"" ]; then
	echo -e "\033[31m-p must be specified with a determined -d parameter.\033[0m"
    useage
    exit 1
fi

if [ x"$PLATFORM" = x"QEMU" -a x"$DISTRO" = x"" ]; then
	echo -e "\033[31m-d must be specified with QEMU as platform.\033[0m"
	usage
    exit 1
fi

if [ x"$PLATFORM" = x"" -a x"$DISTRO" = x"" -a x"$INSTALL" = x"" ]; then
    usage
    exit 1
fi

# Check if the install parameters are correct.
if !(check_setup_param); then
	exit 1
fi

# Detect and dertermine some environment variables
if [ x"$PLATFORM" = x"D01" ]; then
    TARGETARCH="ARM32"
else
    TARGETARCH="ARM64"
fi

build_dir=$build_dir/$PLATFORM
if [ ! -d "$build_dir" ] ; then
	mkdir -p "$build_dir" 2> /dev/null
fi

binary_dir=$build_dir/binary
if [ x"" != x"$PLATFORM" ] && [ ! -d "$binary_dir" ] ; then
	mkdir -p "$binary_dir" 2> /dev/null
fi

###################################################################################
###################### Download & uncompress toochain #############################
###################################################################################
TOOLCHAIN_DIR=toolchain
toolchain_dir=$build_dir/toolchain
GCC32=gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz
GCC64=gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz
toolchainsum_file="toolchain.sum"

if [[ $LOCALARCH != arm* && $LOCALARCH != aarch64 ]]; then
	if [ ! -d "$TOOLCHAIN_DIR" ] ; then
		mkdir -p "$TOOLCHAIN_DIR" 2> /dev/null
	fi
	
	# Download firstly
	# TOOLCHAIN_SOURCE=http://7xjz0v.com1.z0.glb.clouddn.com/tools
	cd $TOOLCHAIN_DIR
	echo "Checking the checksum for toolchain ..."
	check_sum "../estuary/checksum/$toolchainsum_file"
	if [ x"$?" != x"0" ]; then
		TEMPFILE=tempfile
		md5sum --quiet --check $toolchainsum_file 2>/dev/null | grep "$FAILED_STR" | cut -d : -f 1 > $TEMPFILE
		while read LINE
		do
		    if [ x"$LINE" != x"" ]; then
			echo "Downloading the toolchain ..."
				rm -rf $LINE 2>/dev/null
			    wget -c $TOOLCHAIN_SOURCE/$LINE
				if [ x"$?" != x"0" ]; then
					rm -rf $toolchainsum_file $LINE $TEMPFILE 2>/dev/null
					echo "Download toolchain $LINE failed!"
					exit 1
				fi
		    fi
		done  < $TEMPFILE
		rm $TEMPFILE
	fi
	cd -

	# Copy compiler to build target directory
	if [ x"" != x"$PLATFORM" ] && [ ! -d "$toolchain_dir" ] ; then
	    echo "Copying toolchain to 'build' directory ..."
		mkdir -p "$toolchain_dir" 2>/dev/null
	    if [ x"ARM32" = x"$TARGETARCH" ]; then
	    	cp $TOOLCHAIN_DIR/$GCC32 $toolchain_dir/
			ln -s ../../../$toolchain_dir/$GCC32 $binary_dir/$GCC32
		else
	    	cp $TOOLCHAIN_DIR/$GCC64 $toolchain_dir/
			ln -s ../../../$toolchain_dir/$GCC64 $binary_dir/$GCC64
		fi
	fi

	# Uncompress the toolchain
	for	cross_prefix in arm-linux-gnueabihf aarch64-linux-gnu
	do
		arm_gcc=`find $TOOLCHAIN_DIR -name $cross_prefix"-gcc" 2>/dev/null`
		if [ x"" = x"$arm_gcc" ]; then 
			package=`ls $TOOLCHAIN_DIR/*.xz | grep "$cross_prefix"`
			echo "Uncompressing the toolchain ..."
			tar Jxf $package -C $TOOLCHAIN_DIR
			arm_gcc=`find $TOOLCHAIN_DIR -name $cross_prefix"-gcc" 2>/dev/null`
		fi
	
		COMPILER_DIR=${PWD}/${arm_gcc%/*}
		export PATH=$COMPILER_DIR:$PATH

		if [ x"$TARGETARCH" = x"ARM32" ] && [ x"$cross_prefix" = x"arm-linux-gnueabihf" ]; then
			CROSS=${PWD}/${arm_gcc%g*}
		fi

		if [ x"$TARGETARCH" = x"ARM64" ] && [ x"$cross_prefix" = x"aarch64-linux-gnu" ]; then
			CROSS=${PWD}/${arm_gcc%g*}
		fi
	done

	if [[ $LOCALARCH != arm* && $LOCALARCH != aarch64 ]]; then
		export CROSS_COMPILE=$CROSS
	fi

	echo "Cross compiler is $CROSS"
fi

###################################################################################
######## Download distribution according to special PLATFORM and DISTRO ###########
###################################################################################
download_distro()
{
	DISTRO_DIR=distro
	if [ ! -d "$DISTRO_DIR" ] ; then
		mkdir -p "$DISTRO_DIR" 2> /dev/null
	fi

	# Determine the source file
	if [ x"$TARGETARCH" = x"ARM32" ] ; then
		case $1 in
	#		"OpenSuse" )
	#			DISTRO_SOURCE=$PATH_OPENSUSE32
	#			;;
			"Ubuntu" )
				DISTRO_SOURCE=$PATH_UBUNTU32
				;;	
				* )
				DISTRO_SOURCE="none"
				;;
		esac
	else
		case $1 in
			"OpenSuse" )
				DISTRO_SOURCE=$PATH_OPENSUSE64
				;;
			"Ubuntu" )
				DISTRO_SOURCE=$PATH_UBUNTU64
				;;	
	        "Fedora" )
				DISTRO_SOURCE=$PATH_FEDORA64
				;;	
	        "Debian" )
				DISTRO_SOURCE=$PATH_DEBIAN64
				;;
	        "CentOS" )
				DISTRO_SOURCE=$PATH_CENTOS64
				;;	
			* )
				DISTRO_SOURCE="none"
				;;
		esac
	fi
	#DISTRO_SOURCE="default"
	
	if [ x"$DISTRO_SOURCE" != x"none" ]; then
	
		if [ x"$DISTRO_SOURCE" = x"default" ]; then
		    DISTRO_SOURCE=$PATH_DISTRO/"$1"_"$TARGETARCH"."tar.gz"
		fi
		
		# Check the postfix name
		postfix=${DISTRO_SOURCE#*.tar} 
		if [ x"$postfix" = x"$DISTRO_SOURCE" ]; then
		    postfix=${DISTRO_SOURCE##*.} 
		else
			if [ x"$postfix" = x"" ]; then
				postfix=".tar"
			else
				postfix="tar"$postfix	
			fi
		fi
		
		cd $DISTRO_DIR
		# Download it based on md5 checksum file
		echo "Checking the checksum for distribution: "$1"_"$TARGETARCH" ..."
		check_sum "../estuary/checksum/${DISTRO_SOURCE##*/}.sum"
		if [ x"$?" != x"0" ]; then
		    echo "Checking the checksum for distribution ..."
			distrosum_file=${DISTRO_SOURCE##*/}".sum"
	#		md5sum --quiet --check $distrosum_file 2>/dev/null | grep "$FAILED_STR" >/dev/null
	#		if [ x"$?" = x"0" ]; then
			    echo "Downloading the distribution: "$1"_"$TARGETARCH" ..."
				rm -rf "$1"_"$TARGETARCH"."$postfix" 2>/dev/null
			    wget -c $DISTRO_SOURCE -O "$1"_"$TARGETARCH"."$postfix"
				if [ x"$?" != x"0" ]; then
					rm -rf $distrosum_file $1"_"$TARGETARCH"."$postfix 2>/dev/null
					echo "Download distributions "$1"_"$TARGETARCH"."$postfix" failed!"
					exit 1
				fi
			    chmod 777 "$1"_"$TARGETARCH".$postfix
	#		fi
		fi
		cd -
	fi
}

for tmp in "${DISTROLS[@]}"
do
	download_distro $tmp
done

###################################################################################
##########  Download prebuilt binaries based on md5 checksum file    ##############
###################################################################################
PREBUILD_DIR=prebuild
#BINARY_SOURCE=https://github.com/open-estuary/estuary/releases/download/bin-v2.0
#BINARY_SOURCE=http://7xjz0v.com1.z0.glb.clouddn.com/v2.0
binarysum_file="binaries.sum"
binarydl_result=0

if [ ! -d "$PREBUILD_DIR" ] ; then
	mkdir -p "$PREBUILD_DIR" 2> /dev/null
fi

cd $PREBUILD_DIR/
echo "Checking the checksum for binaries ..."
check_sum "../estuary/checksum/$binarysum_file"
if [ x"$?" != x"0" ]; then
	TEMPFILE=tempfile
	md5sum --quiet --check $binarysum_file 2>/dev/null | grep "$FAILED_STR" | cut -d : -f 1 > $TEMPFILE
	while read LINE
	do
	    if [ x"$LINE" != x"" ]; then
	        echo "Downloading $LINE ..."
		    rm -rf $LINE 2>/dev/null
		    wget -c $BINARY_SOURCE/$LINE
			if [ x"$?" != x"0" ]; then
                binarydl_result=$LINE
				rm -rf $binarysum_file $LINE $TEMPFILE 2>/dev/null
			fi
	    fi
	done  < $TEMPFILE
	rm $TEMPFILE
fi
cd -

# Copy some common prebuilt files to build target directory
if [ x"QEMU" != x"$PLATFORM" ] && [ -d $binary_dir ]; then 
    if [ x"$TARGETARCH" = x"ARM32" ]; then
	if [ -f $PREBUILD_DIR/mini-rootfs-arm32.cpio.gz ]; then
	    cp $PREBUILD_DIR/mini-rootfs-arm32.cpio.gz $binary_dir/ 2>/dev/null
	fi
    else
	if [ -f $PREBUILD_DIR/mini-rootfs-arm64.cpio.gz ]; then
	    cp $PREBUILD_DIR/mini-rootfs-arm64.cpio.gz $binary_dir/ 2>/dev/null
	fi
    fi

    if [[ x"D02" = x"$PLATFORM" || x"D03" = x"$PLATFORM" ]] && [ -f $PREBUILD_DIR/CH02TEVBC_V03.bin ]; then
        cp $PREBUILD_DIR/CH02TEVBC_V03.bin $binary_dir/ 2>/dev/null
    fi
    
    if [ x"D01" = x"$PLATFORM" ] && [ -f $PREBUILD_DIR/filesystem.bin ]; then
        cp $PREBUILD_DIR/filesystem.bin $binary_dir/.filesystem
    fi

	if [ x"HiKey" = x"$PLATFORM" ]; then
		if [ -f $PREBUILD_DIR/hisi-idt.py ] && [ ! -f $binary_dir/hisi-idt.py ]; then
	    	cp $PREBUILD_DIR/hisi-idt.py $binary_dir/
		fi

		if [ -f $PREBUILD_DIR/nvme.img ] && [ ! -f $binary_dir/nvme.img ]; then
	    	cp $PREBUILD_DIR/nvme.img $binary_dir/
		fi
	fi
fi

###################################################################################
########################### Produce documentation for building ####################
###################################################################################
DOC_DIR=estuary/doc
doc_dir=$build_dir/doc
TEMPFILE=.tempfile

copy_doc()
{
    postfix=$1

    find $DOC_DIR/*$postfix > $TEMPFILE

	while read LINE
	do
	    if [ x"$LINE" != x"" ]; then
            filename=${LINE##*/}
            filename=${filename%.txt.*}".txt"
            cp $LINE $doc_dir/$filename
	    fi
	done  < $TEMPFILE
	rm $TEMPFILE
}

if [ x"" != x"$PLATFORM" ]; then
    if [ ! -d "$doc_dir" ] ; then
        mkdir -p "$doc_dir" 2>/dev/null
    fi
    copy_doc ".4All"
    copy_doc ".4$PLATFORM"
fi

###################################################################################
########################### Build UEFI from source code   #########################
###################################################################################
UEFI_TOOLS=tools/uefi-tools
UEFI_DIR=uefi
uefi_dir=$build_dir/$UEFI_DIR
uefi_update_flag=0

if [ x"QEMU" = x"$PLATFORM" ]; then
    uefi_bin=
else
    uefi_bin=`find $uefi_dir -name *.fd 2>/dev/null`
fi

build_uefi()
{
	if [ ! -d "$uefi_dir" ] ; then
		mkdir -p "$uefi_dir" 2>/dev/null
	fi
    # use uefi_tools to compile
    if [ ! -d "$UEFI_TOOLS" ] ; then 
        echo "Can not find uefi-tools!"
        exit 1
    fi
    export PATH=$PATH:${PRJROOT}/$UEFI_TOOLS
    # Let UEFI detect the arch automatically
    export ARCH=

	echo "Building UEFI ..."

	if [ x"D01" = x"$PLATFORM" ]; then
		# Build UEFI for D01 platform
     	pushd $UEFI_TOOLS/
     	echo "[d01]" >> platforms.config 
     	echo "LONGNAME=HiSilicon D01 Cortex-A15 16-cores" >> platforms.config
     	echo "BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1" >> platforms.config
     	echo "DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc" >> platforms.config
     	echo "ARCH=ARM" >> platforms.config
     	popd

    	rm `find "$UEFI_DIR/Build/D01" -name "*.fd" 2>/dev/null` 2>/dev/null
    	# compile uefi for D01
    	pushd $UEFI_DIR/
		# roll back to special version for D01
		git reset --hard
		git clean -fdx
		git checkout open-estuary/old

    	#env CROSS_COMPILE_32=$CROSS uefi-tools/uefi-build.sh -b DEBUG d01
    	../$UEFI_TOOLS/uefi-build.sh -b DEBUG d01
    	popd
    	UEFI_BIN=`find "$UEFI_DIR/Build/D01" -name "*.fd" 2>/dev/null`
	elif [[ x"D02" = x"$PLATFORM" || x"D03" = x"$PLATFORM" ]]; then
		# Build UEFI for D02/D03 platform
		rm `find "$UEFI_DIR/Build/Pv660$PLATFORM" -name "*.fd" 2>/dev/null` 2>/dev/null
    	pushd $UEFI_DIR/
		# roll back to special version for D02/D03
		git reset --hard
		git clean -fdx
		git checkout open-estuary/master
		git submodule init
		git submodule update

    	#env CROSS_COMPILE_32=$CROSS uefi-tools/uefi-build.sh -b DEBUG d02
    	if [ x"D02" = x"$PLATFORM" ]; then
			dsc_file="OpenPlatformPkg/Platforms/Hisilicon/D02/Pv660D02.dsc"
    	else
			dsc_file="OpenPlatformPkg/Platforms/Hisilicon/D03/D03.dsc"
    	fi

		grep -P "AARCH64_ARCHCC_FLAGS.*-fno-stack-protector" $dsc_file
    	if [ x"$?" != x"0" ] && [[ $LOCALARCH == arm* || $LOCALARCH == aarch64 ]]; then
			sed -i '/AARCH64_ARCHCC_FLAGS.*$/s//& -fno-stack-protector/g' $dsc_file
    	fi
		platform=$(echo $PLATFORM | tr "[:upper:]" "[:lower:]")
		uefi-tools/uefi-build.sh -c LinaroPkg/platforms.config $platform
		git submodule deinit -f .
    	popd
		if [ x"D02" = x"$PLATFORM" ]; then
			UEFI_BIN=`find "$UEFI_DIR/Build/Pv660D02" -name "*.fd" 2>/dev/null`
		else
			UEFI_BIN=`find "$UEFI_DIR/Build/D03" -name "*.fd" 2>/dev/null`
		fi

#		if [ x"$UEFI_BIN" != x"" ]; then
#			cp $UEFI_DIR/HwProductsPkg/D02/*.bin $uefi_dir/
#			cp $UEFI_DIR/HwProductsPkg/D02/*.bin $binary_dir/
#		fi
	elif [ x"HiKey" = x"$PLATFORM" ]; then
    	rm `find "$UEFI_DIR/l-loader" -name "fip.bin" 2>/dev/null` 2>/dev/null
		# Build UEFI for D02 platform
    	pushd $UEFI_DIR/
#		export AARCH64_TOOLCHAIN=GCC49
	    export EDK2_DIR=${PWD}
	    export UEFI_TOOLS_DIR=${PWD}/uefi-tools

		git reset --hard
		git checkout open-estuary/master
		git submodule init
		git submodule update

	    grep -P "PLATFORM_FLAGS.*-fno-stack-protector" OpenPlatformPkg/Platforms/Hisilicon/HiKey/HiKey.dsc
	    if [ x"$?" != x"0" ] && [[ $LOCALARCH == arm* || $LOCALARCH == aarch64 ]]; then
	    	sed -i '/_PLATFORM_FLAGS.*$/s//& -fno-stack-protector/g' OpenPlatformPkg/Platforms/Hisilicon/HiKey/HiKey.dsc
	    fi

	    ${UEFI_TOOLS_DIR}/uefi-build.sh -b DEBUG -a arm-trusted-firmware hikey

	    cd l-loader
	    cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/FV/bl1.bin ./
	    cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/FV/fip.bin ./

		arm-linux-gnueabihf-gcc -c -o start.o start.S
		arm-linux-gnueabihf-gcc -c -o debug.o debug.S
		arm-linux-gnueabihf-ld -Bstatic -Tl-loader.lds -Ttext 0xf9800800 start.o debug.o -o loader
		arm-linux-gnueabihf-objcopy -O binary loader temp
		python gen_loader.py -o l-loader.bin --img_loader=temp --img_bl1=bl1.bin

		sudo PTABLE=linux-8g bash -x generate_ptable.sh
		python gen_loader.py -o ptable-linux.img --img_prm_ptable=prm_ptable.img --img_sec_ptable=sec_ptable.img

	    cp l-loader.bin ../../$uefi_dir/
	    cp fip.bin      ../../$uefi_dir/
	    cp ptable-linux.img ../../$uefi_dir/
	    cp ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/AARCH64/AndroidFastbootApp.efi ../../$uefi_dir/
		cd ..

	    uefi_hikey_bin=`find "${EDK2_DIR}/l-loader" -name "fip.bin" 2>/dev/null`
	    if [ x"$uefi_hikey_bin" != x"" ]; then
			cp $uefi_hikey_bin ${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/AARCH64/
			UEFI_BIN=${EDK2_DIR}/Build/HiKey/DEBUG_GCC49/AARCH64/fip.bin
	    fi
	    # roll back to special version for D02
	    git submodule deinit -f .
    	popd
    fi
	if [ x"$UEFI_BIN" != x"" ]; then
		uefi_bin=$uefi_dir"/UEFI_"$PLATFORM".fd"
    	cp $UEFI_BIN $uefi_bin
	fi
}

# Build UEFI for D01 platform
check_build_log $UEFI_DIR $binary_dir $uefi_dir
uefi_update_flag=$?

if [[ x"" = x"$uefi_bin" && x"" != x"$PLATFORM" && x"QEMU" != x"$PLATFORM" ]] || [ x"$uefi_update_flag" != x"0" ]; then
	build_uefi
fi

if [ x"" != x"$PLATFORM" ] && [ x"" != x"$uefi_bin" ] && [ -f $uefi_bin ] && [ -d $binary_dir ]; then
    cp $uefi_dir/* $binary_dir/
    create_build_log $UEFI_DIR $binary_dir
fi

###################################################################################
##################  Build bootwrapper binary from source code   ###################
###################################################################################
if [ x"D01" = x"$PLATFORM" ]; then
    WRAPPER_DIR=bootwrapper
    wrapper_dir=$build_dir/$WRAPPER_DIR
    check_build_log $WRAPPER_DIR $binary_dir $wrapper_dir

    if [ ! -d "$wrapper_dir" ] ; then 
    	mkdir -p "$wrapper_dir" 2> /dev/null
	fi

    if [ ! -f $wrapper_dir/.text ]; then
        echo "Building boot wrapper ..."
        pushd $WRAPPER_DIR
        make clean
        make
        popd
    fi

    if [ -f $WRAPPER_DIR/.text ]; then
        cp $WRAPPER_DIR/.text $wrapper_dir/
        cp $WRAPPER_DIR/.text $binary_dir/
    fi

    if [ -f $WRAPPER_DIR/.monitor ]; then
        cp $WRAPPER_DIR/.monitor $wrapper_dir/
        cp $WRAPPER_DIR/.monitor $binary_dir/
    fi

    if [ -f $wrapper_dir/.text ] && [ -f $wrapper_dir/.monitor ]; then
	create_build_log $WRAPPER_DIR $binary_dir
    fi

fi

###################################################################################
################## Build grub binary from grub source code      ###################
###################################################################################
GRUB_DIR=grub
grub_dir=$build_dir/$GRUB_DIR

if [ x"QEMU" = x"$PLATFORM" ]; then
    GRUB_BIN=
else
    GRUB_BIN=`find $grub_dir -name *.efi 2>/dev/null`
fi

build_grub()
{
    if [ ! -d "$grub_dir" ] ; then 
    	mkdir -p "$grub_dir" 2> /dev/null
	fi
    echo "Path: ${PWD}"
    cd $grub_dir
    absolute_dir=${PWD}
    cd -

	if [ x"ARM32" = x"$TARGETARCH" ]; then
    	pushd $GRUB_DIR/
# Rollbak the grub master
        git reset --hard
		git checkout grub/master
		git checkout 8e3d2c80ed1b9c2d150910cf3611d7ecb7d3dc6f
		git am ../patches/0002-D01-fix-dtb-load-address.patch

    	make distclean
    	./autogen.sh
    	./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix="$absolute_dir"
    	make -j${corenum}
    	make install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grubarm32.efi -O arm-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	cd -
	else
# Build grub for ARM64 platform
    	pushd $GRUB_DIR/
# Apply patch for boot from inidcated MAC address
        git reset --hard
		git checkout grub/master
		git checkout 8e3d2c80ed1b9c2d150910cf3611d7ecb7d3dc6f
		git am ../patches/001-Search-for-specific-config-file-for-netboot.patch
#		git pull
#        git checkout grub-2.02-beta2

    	make distclean
    	./autogen.sh
    	./configure --prefix="$absolute_dir" --with-platform=efi --build=x86_64-suse-linux-gnu --target=aarch64-linux-gnu --disable-werror --host=x86_64-suse-linux-gnu
    	make -j${corenum}
    	make  install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	echo $PATH
    	cd -
    fi
    GRUB_BIN=`find "$grub_dir" -name "*.efi" 2>/dev/null`
}

# Build grub for D01 platform
check_build_log $GRUB_DIR $binary_dir $grub_dir
grub_update_flag=$?

if [[ x"" = x"$GRUB_BIN" && x"" != x"$PLATFORM" && x"QEMU" != x"$PLATFORM" ]] || [ x"$grub_update_flag" != x"0" ]; then
	build_grub
fi

if [ x"" != x"$PLATFORM" ] && [ x"" != x"$GRUB_BIN" ] && [ -f $GRUB_BIN ] && [ -d $binary_dir ]; then
	cp $GRUB_BIN $binary_dir/

    if [ -f $PREBUILD_DIR/grub.cfg ]; then
        cp $PREBUILD_DIR/grub.cfg $grub_dir/ 2>/dev/null
        cp $PREBUILD_DIR/grub.cfg $binary_dir/ 2>/dev/null
    fi
    create_build_log $GRUB_DIR $binary_dir
fi

###################################################################################
######################### Uncompress the distribution   ###########################
###################################################################################
uncompress_distro()
{
	distro_dir=$build_dir/$DISTRO_DIR/$1
	image=`ls "$DISTRO_DIR/" | grep -E "^$1*" | grep -E "$TARGETARCH" | grep -v ".sum"`
	if [ x"" != x"$1" ] && [ x"" != x"$image" ] && [ ! -d "$distro_dir" ]; then
	    mkdir -p "$distro_dir" 2> /dev/null
	    
	    echo "Uncompressing the distribution($1) ..."
	    image_postfix=`echo "$image" | grep -Po "((\.tar)*\.(tar|bz2|gz|xz)$)" 2>/dev/null`
	    case "$image_postfix" in
		.tar.bz2 )
			sudo tar zxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
			echo "This is a tar.bz2 package"
			;;
		.bz2 )
			bunzip2 $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
			echo "This is a tar.bz2 package"
			;;
		.tar.gz )
			sudo tar zxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
			echo "This is a tar.gz package"
			;;
		.gz )
			gunzip $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
			echo "This is a tar.gz package"
			;;
		.tar.xz | .xz)
			tar xvf $DISTRO_DIR/$TEMP -C $distro_dir 2> /dev/null 1>&2
			echo "This is a xz package"
			;;
		.tbz )
			tar jxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
			echo "This is a tbz package"
			;;
		* )
			echo "Can not find the suitable root filesystem!"
			exit 1
			;;
	    esac

	    echo "Remove old module files in rootfs..."
	    sudo rm -rf $distro_dir/lib/modules/*

	fi
}

for tmp in "${DISTROLS[@]}"
do
	uncompress_distro $tmp
done

###################################################################################
##################### Build kernel from kernel source code      ###################
###################################################################################
# preprocess for kernel building
BUILDFLAG=FALSE
KERNEL_DIR=kernel
kernel_dir=$build_dir/$KERNEL_DIR
KERNEL_BIN=
DTB_BIN=

check_build_log $KERNEL_DIR $binary_dir $kernel_dir
kernel_update_flag=$?

if [ x"" = x"$PLATFORM" ]; then
    #do nothing
	echo "Do not build kernel."
elif [ x"ARM32" = x"$TARGETARCH" ]; then
	KERNEL_BIN=$kernel_dir/arch/arm/boot/zImage
    DTB_BIN=$kernel_dir/arch/arm/boot/dts/hip04-d01.dtb
	CFG_FILE=hisi_defconfig

	if [ ! -f $kernel_dir/arch/arm/boot/zImage ]; then
		BUILDFLAG=TRUE
	fi

	export ARCH=arm
else
	KERNEL_BIN=$kernel_dir/arch/arm64/boot/Image
	CFG_FILE=defconfig

    if [ x"QEMU" = x"$PLATFORM" ]; then
        DTB_BIN=""
    elif [ x"HiKey" = x"$PLATFORM" ]; then
	    DTB_BIN=$kernel_dir/arch/arm64/boot/dts/hisilicon/hi6220-hikey.dtb
    elif [ x"D02" = x"$PLATFORM" ]; then
            DTB_BIN=$kernel_dir/arch/arm64/boot/dts/hisilicon/hip05-d02.dtb
    else
	    DTB_BIN=$kernel_dir/arch/arm64/boot/dts/hisilicon/hip06-d03.dtb
    fi

	if [ ! -f $kernel_dir/arch/arm64/boot/Image ]; then
		BUILDFLAG=TRUE
	fi

	export ARCH=arm64
fi

if [ ! -d $kernel_dir ]; then
	mkdir -p "$kernel_dir" 2> /dev/null
fi

pushd $KERNEL_DIR/

build_kernel()
{
    echo "Building kernel ..."

	git clean -fdx
	git reset --hard
	sudo rm -rf ../$kernel_dir/*
	make O=../$kernel_dir mrproper
	make O=../$kernel_dir $CFG_FILE

    # kernel building
    if [ x"ARM32" = x"$TARGETARCH" ]; then
#		sed -i 's/CONFIG_HAVE_KVM_IRQCHIP=y/# CONFIG_VIRTUALIZATION is not set/g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM_MMIO=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_HAVE_KVM_CPU_RELAX_INTERCEPT=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_VIRTUALIZATION=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM_ARM_HOST=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM_ARM_MAX_VCPUS=4//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM_ARM_VGIC=y//g' ../$kernel_dir/.config
#		sed -i 's/CONFIG_KVM_ARM_TIMER=y//g' ../$kernel_dir/.config
		git apply ../patches/d01-kernel-ethernet/*.patch
		make O=../$kernel_dir -j${corenum} ${KERNEL_BIN##*/}
		make O=../$kernel_dir ${DTB_BIN#*/boot/dts/}
        cat ../$KERNEL_BIN ../$DTB_BIN > ../$kernel_dir/.kernel
    else
        if [ x"QEMU" = x"$PLATFORM" ]; then
    		sed -i -e '/# CONFIG_ATA_OVER_ETH is not set/ a\CONFIG_VIRTIO_BLK=y' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_SCSI_BFA_FC is not set/ a\# CONFIG_SCSI_VIRTIO is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VETH is not set/ a\# CONFIG_VIRTIO_NET is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_SERIAL_FSL_LPUART is not set/ a\# CONFIG_VIRTIO_CONSOLE is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRT_DRIVERS is not set/ a\CONFIG_VIRTIO=y' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRTIO_PCI is not set/ a\# CONFIG_VIRTIO_BALLOON is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRTIO_MMIO is not set/ a\# CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES is not set' ../$kernel_dir/.config
    		sed -i 's/# CONFIG_VIRTIO_MMIO is not set/CONFIG_VIRTIO_MMIO=y/g' ../$kernel_dir/.config
        else
			sed -i 's/\(CONFIG_CDROM_PKTCDVD=\)\(.*\)/\1y/' ../$kernel_dir/.config
			sed -i 's/\(CONFIG_ISO9660_FS=\)\(.*\)/\1y/' ../$kernel_dir/.config
			sed -i 's/\(CONFIG_BLK_DEV_SR=\)\(.*\)/\1y/' ../$kernel_dir/.config
			sed -i 's/\(CONFIG_CHR_DEV_SG=\)\(.*\)/\1y/' ../$kernel_dir/.config
        fi
		make O=../$kernel_dir -j${corenum} ${KERNEL_BIN##*/}

		dtb_dir=${DTB_BIN#*arch/}
		dtb_dir=${DTB_BIN%/*}
		dtb_dir=../${kernel_dir}/arch/${dtb_dir}

	    mkdir -p $dtb_dir 2>/dev/null

		make O=../$kernel_dir ${DTB_BIN#*/boot/dts/}
    fi
}

if [ x"$BUILDFLAG" = x"TRUE" ] || [ x"$kernel_update_flag" != x"0" ]; then
	build_kernel
	echo "PWD `pwd`"
	if [ x"" != x"$KERNEL_BIN" ] && [ -f ../$KERNEL_BIN ]; then
		pushd ..
		create_build_log $KERNEL_DIR $binary_dir
		popd
	fi
fi

# postprocess for kernel building
echo "Postprocess for kernel building ..."
for tmp in "${DISTROLS[@]}"
do
	distro_dir=${PRJROOT}/$build_dir/$DISTRO_DIR/$tmp
	modulesfile=`find ${distro_dir}/lib/modules -name modules.dep 2>/dev/null`

	if [ x"" = x"$modulesfile" ]; then
		#make O=../$kernel_dir $CFG_FILE
		make O=../$kernel_dir -j${corenum} modules INSTALL_MOD_PATH=$distro_dir

		sudo ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE make O=../$kernel_dir -j${corenum} modules_install INSTALL_MOD_PATH=$distro_dir
		sudo ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE make O=../$kernel_dir -j${corenum} firmware_install INSTALL_FW_PATH=$distro_dir/lib/firmware
	fi
done

popd
#	pushd $KERNEL_DIR/
#	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1"
#	for tmp in "${DISTROLS[@]}"
#	do
#		distro_dir=${PRJROOT}/$build_dir/$DISTRO_DIR/$tmp
#		export ARCH=arm64
#		export CROSS_COMPILE=$CROSS_COMPILE
#		echo "============$ARCH,$CROSS_COMPILE"
#
#		make O=../$kernel_dir $CFG_FILE
#
#		sudo ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE  make O=../$kernel_dir -j${corenum} modules_install INSTALL_MOD_PATH=$distro_dir
#		sudo ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE  make O=../$kernel_dir -j${corenum} firmware_install INSTALL_FW_PATH=$distro_dir/lib/firmware
#	done
#	popd

if [ x"" != x"$KERNEL_BIN" ] && [ -f $KERNEL_BIN ]; then
	cp $KERNEL_BIN $binary_dir/${KERNEL_BIN##*/}"_$PLATFORM"

    if [ x"D01" = x"$PLATFORM" ] && [ -f $kernel_dir/.kernel ]; then
        cp $kernel_dir/.kernel $binary_dir/
    fi
fi

if [ x"" != x"$DTB_BIN" ] && [ -f $DTB_BIN ]; then
    cp $DTB_BIN $binary_dir/
fi

###################################################################################
######################### install applications          ###########################
###################################################################################
PACKAGES=packages
install_pkgs()
{
    if [ x"" = x"$CFGFILE" ] || [ ! -f $CFGFILE ]; then
		return
	fi

	echo "Installing packages ..."

	idx=0
    pkg=`jq -r ".packages[$idx].name" $CFGFILE`
	while [ x"$pkg" != x"null" ];
	do
    	install=`jq -r ".packages[$idx].install" $CFGFILE`
		if [ x"yes" = x"$install" ]; then
			appdir="$PACKAGES/$pkg"
			if [ -d "$appdir" ] && [ -f "$appdir/build.sh" ]; then
				kdir=${PRJROOT}/$kernel_dir
				mkdir -p $build_dir/$appdir 2>/dev/null
				$appdir/build.sh $PLATFORM $1 $2 $kdir

				for cpfile in postinstall remove
				do
					specialfile=`find $appdir -name "*${pkg}_${cpfile}.sh"`
					if [ x"" != x"$specialfile" ] && [ -f $specialfile ]; then
						targetdir="$2/usr/bin/estuary/$cpfile"
						if [ ! -d $targetdir ]; then
							sudo mkdir -p $targetdir 2>/dev/null
						fi
						sudo cp $specialfile  $targetdir/
					fi
				done
			fi
		fi

		let idx=$idx+1
    	pkg=`jq -r ".packages[$idx].name" $CFGFILE`
	done
}

###################################################################################
######################### create distribution           ###########################
###################################################################################
distro_postfix=".tar.gz"

rc_local_template="#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will \"exit 0\" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0"

create_distro()
{
	local rc_local_file=
	case "$1" in
		OpenSuse )
			rc_local_file=rc.d/after.local
			;;
		Fedora )
			rc_local_file=rc.d/rc.local
			;;
		* )
			rc_local_file=rc.local
			;;
	esac

	distro_dir=${PRJROOT}/$build_dir/$DISTRO_DIR/$1
	image="$1_$TARGETARCH$distro_postfix"
	if [ x"" != x"$1" ] && [ x"" != x"$image" ] && [ ! -f "$build_dir/$DISTRO_DIR/$image" ]; then
		if [ ! -d $distro_dir/usr/bin/estuary ]; then
			sudo mkdir -p $distro_dir/usr/bin/estuary 2>/dev/null
		fi

		install_pkgs $1 $distro_dir
		sed -i "s/lastupdate=.*/lastupdate=\"$lastupdate\"/" estuary/post_install.sh
		sudo cp estuary/post_install.sh $distro_dir/usr/bin/estuary/
		sudo chmod 755 $distro_dir/usr/bin/estuary/post_install.sh
		if [ ! -f $distro_dir/etc/$rc_local_file ]; then
			echo "$rc_local_template" | sudo tee $distro_dir/etc/$rc_local_file >/dev/null
			sudo chown root:root $distro_dir/etc/$rc_local_file
			sudo chmod 755 $distro_dir/etc/$rc_local_file
		fi
		
		grep "/usr/bin/estuary/post_install.sh" $distro_dir/etc/$rc_local_file >/dev/null
		if [ x"$?" != x"0" ]; then
			grep -E "^(exit)" $distro_dir/etc/$rc_local_file >/dev/null
			if [ x"$?" = x"0" ]; then
				sudo sed -i "/^exit/i/usr/bin/estuary/post_install.sh" $distro_dir/etc/$rc_local_file
			else
				sudo sed -i '$ a /usr/bin/estuary/post_install.sh' $distro_dir/etc/$rc_local_file
			fi
		fi

		pushd $distro_dir/
		echo "Creating $image ..."
		sudo tar -czf ../$image *
		popd

		ln -s ../../../$build_dir/$DISTRO_DIR/$image $binary_dir/$image
	fi
}

for tmp in "${DISTROLS[@]}"
do
	create_distro $tmp
done

installresult=0
###################################################################################
########################## Install Caliper for Estuary     ########################
###################################################################################
if [ x"Caliper" = x"$INSTALL" ]; then
	pushd caliper
	echo "Installing Caliper ..."
	sudo python setup.py install
	installresult=$?
	popd
fi

###################################################################################
########################## Install toolchain for Estuary     ########################
###################################################################################
if [ x"toolchain" = x"$INSTALL" ]; then
	sudo mkdir -p /opt 2>/dev/null
	for compiler in $GCC32 $GCC64
	do
		compiler=${compiler%%.tar.xz}
		echo "Installing $compiler ..."
		if [ ! -d "/opt/$compiler" ]; then
			sudo cp -r $TOOLCHAIN_DIR/$compiler /opt/
			if [ x"$?" != x"0" ]; then
				installresult=1
			fi
			str='export PATH=$PATH:/opt/'$compiler'/bin' 
			grep "$str" ~/.bashrc >/dev/null
			if [ x"$?" != x"0" ]; then
				echo "$str">> ~/.bashrc
			fi
		fi
	done
fi

###################################################################################
################## Create install iso image #######################################
###################################################################################
if [ x"$INSTALL_ISO_IMG" != x"" ] && [ ! -f $binary_dir/${INSTALL_ISO_IMG} ]; then
	echo "Start to create install iso image ......"
	if (./estuary/mkisoimg.sh --disklabel=Estuary --bindir=$binary_dir --confdir=./estuary --grubdir=$build_dir/grub); then
		echo "move $INSTALL_ISO_IMG to $binary_dir/$INSTALL_ISO_IMG ......"
		mv Estuary.iso $binary_dir/${INSTALL_ISO_IMG}
		echo -e "\033[32mCreate install iso image successfully!\033[0m"
	else
		echo -e "\033[31mCreate install iso image failed!\033[0m"
	fi
fi

###################################################################################
################### Create usb install disk #######################################
###################################################################################
usb_result=0
if [ x"$INSTALL_UDISK_DEV" != x"" ]; then
	install_device=$INSTALL_UDISK_DEV
	echo "Start to create usb install disk ......"
	if (./estuary/mkusbinstall.sh --disk=$install_device --disklabel=Estuary --bindir=$binary_dir --confdir=./estuary); then
		echo -e "\033[32mCreate usb install disk successfully!\033[0m"
	else
		echo -e "\033[31mCreate usb install disk failed!\033[0m"
		usb_result=1
	fi
fi

###################################################################################
########################## Check and report build resutl   ########################
###################################################################################
echo ""
echo -e "\033[32m==========================================================================\033[0m"

if [ x"2" = x"$DEPRECATED_PARAMETER" ]; then
	echo -e "\033[31mParameter -p or --platform and -d or --distro are deprecated.\033[0m"
	echo -e "\033[31mStrongly recommend to use parameter -f or --file to specify configuration file.\033[m"
	echo -e "\033[31mE.g.: ./estuary/build.sh -f ./estuary/estuarycfg.json.\033[m"
	echo ""
fi

if [ x"" != x"$PLATFORM" ]; then
    echo "Building completed!"
    #echo "Of course, you can also find all original binaries in follows:"
    
    build_error=0
    if [ x"QEMU" != x"$PLATFORM" ]; then
    	if [ x"" != x"$uefi_bin" ] && [ -f $uefi_bin ]; then
    		#echo -e "\033[32mUEFI         is $uefi_bin.\033[0m"
            true
    	else
    		echo -e "\033[31mFailed! UEFI         can not be found!\033[0m"
            build_error=1
    	fi
    fi
    
    if [ x"QEMU" != x"$PLATFORM" ]; then
    	if [ x"" != x"$GRUB_BIN" ] && [ -f $GRUB_BIN ]; then
    		#echo -e "\033[32mgrub         is $GRUB_BIN.\033[0m"
            true
    	else
    		echo -e "\033[31mFailed! grub         can not be found!\033[0m"
            build_error=1
    	fi
    fi

    if [ x"D01" = x"$PLATFORM" ]; then
        if [ -f $wrapper_dir/.text ] && [ -f $wrapper_dir/.monitor ]; then
		    #echo -e "\033[32mBoot wrapper is in $wrapper_dir.\033[0m"
            true
	    else
		    echo -e "\033[31mFailed! Boot wrapper can not be found!\033[0m"
            build_error=1
        fi
    fi
    
    if [ x"" != x"$KERNEL_BIN" ] && [ -f $KERNEL_BIN ]; then
    	#echo -e "\033[32mkernel       is $KERNEL_BIN.\033[0m"
        true
    else
    	echo -e "\033[31mFailed! kernel       can not be found!\033[0m"
        build_error=1
    fi
    
    if [ x"QEMU" = x"$PLATFORM" ]; then
    	#echo "dtb is not necessary for QEMU."
        true
    else
    	if [ x"" != x"$DTB_BIN" ] && [ -f $DTB_BIN ]; then
    		#echo -e "\033[32mdtb          is $DTB_BIN.\033[0m"
            true
    	else
    		echo -e "\033[31mFailed! dtb          can not be found!\033[0m"
            build_error=1
    	fi
    fi
    
	for tmp in "${DISTROLS[@]}"
	do
		image="$build_dir/$DISTRO_DIR/$tmp"_"$TARGETARCH$distro_postfix"
	    if [ -f $image ]; then
			#echo -e "\033[32mDistribution is $image.\033[0m"
	        true
		else
			echo -e "\033[31mFailed! Distribution($image) can not be found!\033[0m"
	        build_error=1
	    fi
	done

	if [[ $LOCALARCH != arm* && $LOCALARCH != aarch64 ]]; then
	    if [ -f $toolchain_dir/$GCC64 ] || [ -f $toolchain_dir/$GCC32 ]; then
	    	#echo -e "\033[32mtoolchain    is in $toolchain_dir.\033[0m"
	        true
	    else
	    	echo -e "\033[31mFailed! toolchain    can not be found!\033[0m"
	        build_error=1
	    fi
	fi

    if [ $build_error = 0 ]; then
        echo -e "\033[32mAll binaries are ready in $binary_dir.\033[0m"
    fi

    if [ -d $docdir ]; then    
        grep -R "readme" $doc_dir > /dev/null
        doc_result=$?
    else
        doc_result=1
    fi

    if [ x"0" != x"$doc_result" ]; then
    	echo -e "\033[31mFailed! Documents    can not be found!\033[0m"
    else
        if [ $build_error = 0 ]; then
    	    echo -e "\033[32mPlease follow the instructions in $doc_dir/Readme.txt to use the binaries for your purpose.\033[0m"
        fi
    fi

    if [ x"$INSTALL_ISO_IMG" != x"" ]; then
	if [ -f $binary_dir/${INSTALL_ISO_IMG} ]; then
    	    echo -e "\033[32mInstall iso image ${INSTALL_ISO_IMG} created.\033[0m"
	else
    	    echo -e "\033[31mFailed! File ${INSTALL_ISO_IMG} can not be found!\033[0m"
	fi
    fi

    if [ x"$INSTALL_UDISK_DEV" = x"yes" ]; then
        if [ $usb_result = 0 ]; then
    	    echo -e "\033[32mCreate usb install disk on device INSTALL_UDISK_DEVICE.\033[0m"
		else
    	    echo -e "\033[31mFailed! Create usb install disk return error!\033[0m"
		fi
    fi
fi

# Binaries download report
#if [ x"0" = x"$binarydl_result" ]; then
#	echo -e "\033[32mPrebuilt Binaries are in $PREBUILD_DIR.\033[0m"
#else
#	echo -e "\033[31mFailed! Some Binaries ($binarydl_result) can not be found!\033[0m"
#fi

# Install Caliper report
if [ x"Caliper" = x"$INSTALL" ]; then
	if [ x"0" = x"$installresult" ]; then
    	echo -e "\033[32mInstalled Caliper successfully.\033[0m"
		echo "Please edit /etc/caliper/config/client_config.cfg to config target board."
    else
    	echo -e "\033[31mCaliper installing failed!\033[0m"
	fi
fi

# Install toolchain report
if [ x"toolchain" = x"$INSTALL" ]; then
	if [ x"0" = x"$installresult" ]; then
   		echo -e "\033[32mInstalled toolchain successfully.\033[0m"
		echo "The toolchain is installed into /opt directory"
	else
    	echo -e "\033[31mToolchain installing failed!\033[0m"
	fi
fi

###################################################################################
################ Build QEMU and start it if platform is QEMU   ####################
###################################################################################
if [ x"QEMU" = x"$PLATFORM" ]; then
# Find the rootfs image file's name for QEMU
    findfs="first"
    while [ x"$findfs" != x"false" ]
    do
    	rootfs=`ls $distro_dir/*.img 2>/dev/null`
    	if [ x"" = x"$rootfs" ]; then
    		rootfs=`ls $distro_dir/*.raw 2>/dev/null`
    	fi
    
    	if [ x"" != x"$rootfs" ]; then
            findfs="false"
            break
        else
    	    if [ x"$findfs" = x"first" ]; then
                # Create a new image file from rootfs directory for QEMU
                sudo find $distro_dir -name "etc" | grep --quiet "etc"
                if [ x"$?" = x"0" ]; then
        	        echo "Creating new rootfs image file for QEMU ..."
                    cd $distro_dir
                    
                    IMAGEFILE="$DISTRO"_"$TARGETARCH"."img"
                    dd if=/dev/zero of=../$IMAGEFILE bs=1M count=10240
                    mkfs.ext4 ../$IMAGEFILE -F
                    mkdir -p ../tempdir 2>/dev/null
                    sudo mount ../$IMAGEFILE ../tempdir
					echo "Producing the rootfs image file for QEMU ..."
                    sudo cp -a * ../tempdir/
                    sudo umount ../tempdir
                    rm -rf ../tempdir
                    mv ../$IMAGEFILE ./

                    cd -
                fi

                findfs="second"
            else
                findfs="false"
        	    echo "Do not found suitable root filesystem!"
                exit 1
            fi
        fi
    done

# Find the vda device
	case $DISTRO in 
		OpenEmbedded | OpenSuse)
			partition=2
			;;
		Debian | Ubuntu)
			;;
		Fedora)
			partition=4
			;;
	esac
	CMDLINE="console=ttyAMA0 root=/dev/vda$partition rw"
# Temporarily use fixed vda
	CMDLINE="console=ttyAMA0 root=/dev/vda rw"

# Compile qemu
	qemu_dir=${PRJROOT}/$build_dir/qemu
	mkdir -p $qemu_dir 2> /dev/null

	QEMU=`find $qemu_dir -name qemu-system-aarch64 2>/dev/null`
	if [ x"" = x"$QEMU" ]; then
		pushd qemu/
        check_init ".initialized" $lastupdate
        if [ x"$?" = x"0" ]; then
            sudo apt-get install -y gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev
            if [ x"$?" = x"0" ]; then
                touch ".initialized"
            fi
        fi
        echo "Building the QEMU ..."
		./configure --prefix=$qemu_dir --target-list=aarch64-softmmu
		make -j${corenum}
		make install
		popd
	    QEMU=`find $qemu_dir -name qemu-system-aarch64 2>/dev/null`
	fi
	
# Run the qemu
    echo "Starting QEMU ..."
	$QEMU -machine virt -cpu cortex-a57 \
	    -kernel ${PRJROOT}/$KERNEL_BIN \
	    -drive if=none,file=$rootfs,id=fs \
	    -device virtio-blk-device,drive=fs \
	    -append "$CMDLINE" \
	    -nographic
fi
