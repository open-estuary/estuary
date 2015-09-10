#!/bin/bash
#Description: download necessary files firstly, then build target system according to parameters indicated by user
#Use case:
#   ./build.sh -h:                  to get help information for this script
#   ./build.sh -p D02 -d Ubuntu:    to build Ubuntu distribution for D02 platform
#Author: Justin Zhao
#Date: August 7, 2015

###################################################################################
############################# Variables definition         ########################
###################################################################################
distros=(OpenEmbedded Debian Ubuntu OpenSuse Fedora)
distros_d01=(Ubuntu)
distros_d02=(Ubuntu OpenSuse Fedora Debian)
platforms=(QEMU D01 D02)
installs=(Caliper toolchain)

PATH_DISTRO=http://7xjz0v.com1.z0.glb.clouddn.com/dist
#arm64 distributions
#PATH_OPENSUSE64=http://download.opensuse.org/ports/aarch64/distribution/13.2/appliances/openSUSE-13.2-ARM-JeOS.aarch64-rootfs.aarch64-Current.tbz
#PATH_UBUNTU64=https://cloud-images.ubuntu.com/vivid/current/vivid-server-cloudimg-arm64.tar.gz
#PATH_FEDORA64=http://dmarlin.fedorapeople.org/fedora-arm/aarch64/F21-20140407-foundation-v8.tar.xz
PATH_OPENSUSE64=default
PATH_UBUNTU64=default
PATH_FEDORA64=default
PATH_DEBIAN64=default
#arm32 distributions
#PATH_OPENSUSE32=http://download.opensuse.org/ports/armv7hl/distribution/13.2/appliances/openSUSE-13.2-ARM-XFCE.armv7-rootfs.armv7l-1.12.1-Build33.7.tbz
#PATH_UBUNTU32=http://releases.linaro.org/15.02/ubuntu/lt-d01/linaro-utopic-server-20150220-698.tar.gz
#PATH_OPENSUSE32=default
PATH_UBUNTU32=default

###################################################################################
############################# Print help information       ########################
###################################################################################
usage()
{
	echo "usage:"
	echo -n "build.sh [ -p "
	echo -n ${platforms[*]} | sed "s/ / | /g"
	echo -n " ] [ -d "
	echo -n ${distros[*]} | sed "s/ / | /g"
	echo -n " ] [ -i "
	echo -n ${installs[*]} | sed "s/ / | /g"
	echo " ] "

	echo -e "\n -h,--help: to print this message"
	echo " -p,--platform: the target platform, the -d musb be specified if platform is QEMU"
	echo " -d,--distro: the distribuation, the -p must be specified if -d is specified"
	echo "		*for D01, only support Ubuntu, OpenSuse"
	echo "		*for D02, support OpenEmbedded, Ubuntu, OpenSuse, Fedora"
    echo " -i,--install: to install target into local host machine"
	echo "		*for Caliper, to install Caliper as the benchmark tools"
	echo "		*for toolchain, to install ARM cross compiler"
}

###################################################################################
############################# Check distribution parameter ########################
###################################################################################
check_distro()
{
	if [ x"QEMU" = x"$PLATFORM" ]; then
		for dis in ${distros[@]}; do
			if [ x"$dis" = x"$1" ]; then 
				DISTRO=$1
				return
			fi
		done
	elif [ x"D01" = x"$PLATFORM" ]; then
		for dis in ${distros_d01[@]}; do
			if [ x"$dis" = x"$1" ]; then 
				DISTRO=$1
				return
			fi
		done
	elif [ x"D02" = x"$PLATFORM" ]; then
		for dis in ${distros_d02[@]}; do
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
############################# Check the checksum file   ###########################
###################################################################################
checksum_result=0
check_sum()
{
    checksum_source=$1
    if [ x"$checksum_source" = x"" ]; then
        echo "Invalidate checksum file!"
        checksum_result=1
        exit 1
    fi

    checksum_file=${checksum_source##*/}

	touch $checksum_file
	diff $checksum_source $checksum_file >/dev/null
	if [ x"0" != x"$?" ]; then
		rm -rf ".$checksum_file" >/dev/null
		cp $checksum_source ./
	fi

	if [ -f ".$checksum_file" ]; then
		checksum_result=0
		return
	fi

	md5sum --quiet --check $checksum_file 2>/dev/null | grep 'FAILED' >/dev/null
	if [ x"$?" = x"0" ]; then
		checksum_result=1
	else
		checksum_result=0
		touch ".$checksum_file"
	fi
}

###################################################################################
############################# Check all parameters     ############################
###################################################################################
PLATFORM=
DISTRO=
INSTALL=
while [ x"$1" != x"" ]; do 
    case $1 in 
        "-h" | "--help" )
			usage
			exit
			;;
		"-p" | "--platform" )
			shift
			check_platform $1
			echo "Platform: $1"
			;;
		"-d" | "--distro" )
			shift
			check_distro $1
			echo "Distro: $1"
			;;
		"-i" | "--install" )
			shift
			check_install $1
			echo "Install: $1"
			;;
		* )
			echo "unknown arg $1"
			usage
			exit 1
			;;
    esac
	shift
done

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

###################################################################################
############################# Setup host environmenta #############################
###################################################################################
automake --version | grep 'automake (GNU automake) 1.11' > /dev/null
if [ x"$?" = x"1" ]; then
	sudo apt-get remove -y --purge automake*
fi

if [ ! -f ".initialized" ]; then
	sudo apt-get update
    sudo apt-get install -y wget automake1.11 make bc libncurses5-dev libtool libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex
    if [ x"$?" = x"0" ]; then
        touch ".initialized"
    fi
fi

# Detect and dertermine some environment variables
LOCALARCH=`uname -m`
TOOLS_DIR="`dirname $0`"
if [ x"$PLATFORM" = x"D01" ]; then
    TARGETARCH="ARM32"
else
    TARGETARCH="ARM64"
fi

cd $TOOLS_DIR/../
build_dir=build/$PLATFORM
if [ ! -d "$build_dir" ] ; then
	mkdir -p "$build_dir" 2> /dev/null
fi

binary_dir=$build_dir/binary
if [ x"" != x"$PLATFORM" ] && [ ! -d "$binary_dir" ] ; then
	mkdir -p "$binary_dir" 2> /dev/null
fi

if [ x"$TARGETARCH" = x"ARM32" ]; then
	cross_gcc=arm-linux-gnueabihf-gcc
	cross_prefix=arm-linux-gnueabihf
else
	cross_gcc=aarch64-linux-gnu-gcc
	cross_prefix=aarch64-linux-gnu
fi

###################################################################################
###################### Download & uncompress toochain #############################
###################################################################################
TOOLCHAIN_DIR=toolchain
toolchain_dir=$build_dir/toolchain
GCC32=gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz
GCC64=gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz
toolchainsum_file="toolchain.sum"

if [ ! -d "$TOOLCHAIN_DIR" ] ; then
	mkdir -p "$TOOLCHAIN_DIR" 2> /dev/null
fi

# Download firstly
TOOLCHAIN_SOURCE=http://7xjz0v.com1.z0.glb.clouddn.com/tools
cd $TOOLCHAIN_DIR
echo "Check the checksum for toolchain..."
check_sum "../estuary/checksum/$toolchainsum_file"
if [ x"$checksum_result" != x"0" ]; then
	TEMPFILE=tempfile
	md5sum --quiet --check $toolchainsum_file 2>/dev/null | grep ': FAILED' | cut -d : -f 1 > $TEMPFILE
	while read LINE
	do
	    if [ x"$LINE" != x"" ]; then
	        echo "Download the toolchain..."
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

# Copy to build target directory
if [ x"" != x"$PLATFORM" ] && [ ! -d "$toolchain_dir" ] ; then
    echo "Copy toolchain to 'build' directory..."
	mkdir -p "$toolchain_dir" 2>/dev/null
    cp $TOOLCHAIN_DIR/$GCC32 $toolchain_dir/
    cp $TOOLCHAIN_DIR/$GCC64 $toolchain_dir/
fi

# Uncompress the toolchain
arm_gcc=`find "$TOOLCHAIN_DIR" -name "$cross_gcc" 2>/dev/null`
if [ x"" = x"$arm_gcc" ]; then 
	package=`ls $TOOLCHAIN_DIR/*.xz | grep "$cross_prefix"`
	echo "Uncompress the toolchain......"
	tar Jxf $package -C $TOOLCHAIN_DIR
	arm_gcc=`find $TOOLCHAIN_DIR -name $cross_gcc 2>/dev/null`
fi
CROSS=`pwd`/${arm_gcc%g*}
export PATH=${CROSS%/*}:$PATH
echo "Cross compiler is $CROSS"

###################################################################################
######## Download distribution according to special PLATFORM and DISTRO ###########
###################################################################################
DISTRO_DIR=distro
if [ ! -d "$DISTRO_DIR" ] ; then
	mkdir -p "$DISTRO_DIR" 2> /dev/null
fi

# Determine the source file
if [ x"$TARGETARCH" = x"ARM32" ] ; then
	case $DISTRO in
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
	case $DISTRO in
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
		* )
			DISTRO_SOURCE="none"
			;;
	esac
fi
#DISTRO_SOURCE="default"

if [ x"$DISTRO_SOURCE" != x"none" ]; then

	if [ x"$DISTRO_SOURCE" = x"default" ]; then
	    DISTRO_SOURCE=$PATH_DISTRO/"$DISTRO"_"$TARGETARCH"."tar.gz"
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
	echo "Check the checksum for distribution: "$DISTRO"_"$TARGETARCH"..."
	check_sum "../estuary/checksum/${DISTRO_SOURCE##*/}.sum"
	if [ x"$checksum_result" != x"0" ]; then
	    echo "Check the checksum for distribution..."
		distrosum_file=${DISTRO_SOURCE##*/}".sum"
#		md5sum --quiet --check $distrosum_file 2>/dev/null | grep 'FAILED' >/dev/null
#		if [ x"$?" = x"0" ]; then
		    echo "Download the distribution: "$DISTRO"_"$TARGETARCH"..."
			rm -rf "$DISTRO"_"$TARGETARCH"."$postfix" 2>/dev/null
		    wget -c $DISTRO_SOURCE -O "$DISTRO"_"$TARGETARCH"."$postfix"
			if [ x"$?" != x"0" ]; then
				rm -rf $distrosum_file $DISTRO"_"$TARGETARCH"."$postfix 2>/dev/null
				echo "Download distributions "$DISTRO"_"$TARGETARCH"."$postfix" failed!"
				exit 1
			fi
		    chmod 777 "$DISTRO"_"$TARGETARCH".$postfix
#		fi
	fi
	cd -
fi

###################################################################################
##########  Download prebuilt binaries based on md5 checksum file    ##############
###################################################################################
BINARY_DIR=binary
BINARY_SOURCE=https://github.com/open-estuary/estuary/releases/download/bin-v1.2
binarysum_file="binaries.sum"
binarydl_result=0

if [ ! -d "$BINARY_DIR" ] ; then
	mkdir -p "$BINARY_DIR" 2> /dev/null
fi

cd $BINARY_DIR/
echo "Check the checksum for binaries..."
check_sum "../estuary/checksum/$binarysum_file"
if [ x"$checksum_result" != x"0" ]; then
	TEMPFILE=tempfile
	md5sum --quiet --check $binarysum_file 2>/dev/null | grep ': FAILED' | cut -d : -f 1 > $TEMPFILE
	while read LINE
	do
	    if [ x"$LINE" != x"" ]; then
	        echo "Download "$LINE"..."
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

# Copy some common to build target directory
if [ x"QEMU" != x"$PLATFORM" ] && [ -d $binary_dir ]; then 
    if [ -f $BINARY_DIR/mini-rootfs.cpio.gz ]; then
        cp $BINARY_DIR/mini-rootfs.cpio.gz $binary_dir/ 2>/dev/null
    fi

    if [ x"D02" = x"$PLATFORM" ] && [ -f $BINARY_DIR/CH02TEVBC_V03.bin ]; then
        cp $BINARY_DIR/CH02TEVBC_V03.bin $binary_dir/ 2>/dev/null
    fi
    
    if [ x"D01" = x"$PLATFORM" ] && [ -f $BINARY_DIR/default.filesystem ]; then
        cp $BINARY_DIR/default.filesystem $binary_dir/.filesystem
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

if [ x"QEMU" = x"$PLATFORM" ]; then
    uefi_bin=
else
    uefi_bin=`find $uefi_dir -name *.fd 2>/dev/null`
fi

# Build UEFI for D01 platform
if [ x"" = x"$uefi_bin" ] && [ x"" != x"$PLATFORM" ] && [ x"QEMU" != x"$PLATFORM" ]; then
	if [ ! -d "$uefi_dir" ] ; then
		mkdir -p "$uefi_dir" 2>/dev/null
	fi
    # use uefi_tools to compile
    if [ ! -d "$UEFI_TOOLS" ] ; then 
        echo "Can not find uefi-tools!"
        exit 1
    fi
    export PATH=$PATH:`pwd`/$UEFI_TOOLS
    # Let UEFI detect the arch automatically
    export ARCH=

	echo "Build UEFI..."

	if [ x"ARM32" = x"$TARGETARCH" ]; then
		# Build UEFI for D01 platform
     	pushd $UEFI_TOOLS/
     	echo "[d01]" >> platforms.config 
     	echo "LONGNAME=HiSilicon D01 Cortex-A15 16-cores" >> platforms.config
     	echo "BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1" >> platforms.config
     	echo "DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc" >> platforms.config
     	echo "ARCH=ARM" >> platforms.config
     	popd

    	# compile uefi for D01
    	pushd $UEFI_DIR/
		# roll back to special version for D01
		git reset --hard
		git checkout open-estuary/old

    	#env CROSS_COMPILE_32=$CROSS uefi-tools/uefi-build.sh -b DEBUG d01
    	../$UEFI_TOOLS/uefi-build.sh -b DEBUG d01
    	popd
    	UEFI_BIN=`find "$UEFI_DIR/Build/D01" -name "*.fd" 2>/dev/null`
	else
		if [ x"QEMU" != x"$PLATFORM" ]; then
			# Build UEFI for D02 platform
	    	pushd $UEFI_DIR/
			# roll back to special version for D02
			git reset --hard
			git checkout open-estuary/master
			git apply HwPkg/Patch/*.patch
			export LC_CTYPE=C 
            make -C BaseTools clean
			make -C BaseTools 
			source edksetup.sh 
            build -a AARCH64 -b RELEASE -t ARMLINUXGCC -p HwProductsPkg/D02/Pv660D02.dsc cleanall
			build -a AARCH64 -b RELEASE -t ARMLINUXGCC -p HwProductsPkg/D02/Pv660D02.dsc
	
	    	#env CROSS_COMPILE_32=$CROSS uefi-tools/uefi-build.sh -b DEBUG d02
	    	#../$UEFI_TOOLS/uefi-build.sh -b DEBUG d02
	    	popd
	    	UEFI_BIN=`find "$UEFI_DIR/Build/Pv660D02" -name "*.fd" 2>/dev/null`

			if [ x"$UEFI_BIN" != x"" ]; then
				cp $UEFI_DIR/HwProductsPkg/D02/*.bin $uefi_dir/
				cp $UEFI_DIR/HwProductsPkg/D02/*.bin $binary_dir/
			fi
		fi
    fi
	if [ x"$UEFI_BIN" != x"" ]; then
		uefi_bin=$uefi_dir"/UEFI_"$PLATFORM".fd"
    	cp $UEFI_BIN $uefi_bin
	fi
fi
if [ x"" != x"$PLATFORM" ] && [ x"" != x"$uefi_bin" ] && [ -f $uefi_bin ] && [ -d $binary_dir ]; then
    cp $uefi_dir/* $binary_dir/
fi

###################################################################################
################## Build boot-wrapper binary from source code   ###################
###################################################################################
if [ x"D01" = x"$PLATFORM" ]; then
    WRAPPER_DIR=boot-wrapper
    wrapper_dir=$build_dir/$WRAPPER_DIR

    pushd $WRAPPER_DIR
	#export CROSS_COMPILE=$CROSS 
    popd
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

# Build grub for D01 platform
if [ x"" = x"$GRUB_BIN" ] && [ x"" != x"$PLATFORM" ] && [ x"QEMU" != x"$PLATFORM" ]; then
    if [ ! -d "$grub_dir" ] ; then 
    	mkdir -p "$grub_dir" 2> /dev/null
	fi
    echo path:`pwd`
    cd $grub_dir
    absolute_dir=`pwd`
    cd -

	if [ x"ARM32" = x"$TARGETARCH" ]; then
    	pushd $GRUB_DIR/
# Rollbak the grub master
        git reset --hard
		git checkout grub/master
		git checkout 8e3d2c80ed1b9c2d150910cf3611d7ecb7d3dc6f

    	make distclean
    	./autogen.sh
    	./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix="$absolute_dir"
    	make -j14 
    	make install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grubarm32.efi -O arm-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	cd -
else
# Build grub for D02 platform
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
    	make -j14
    	make  install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p / boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	echo $PATH
    	cd -
    fi
    GRUB_BIN=`find "$grub_dir" -name "*.efi" 2>/dev/null`
fi

if [ x"" != x"$PLATFORM" ] && [ x"" != x"$GRUB_BIN" ] && [ -f $GRUB_BIN ] && [ -d $binary_dir ]; then
	cp $GRUB_BIN $binary_dir/

    if [ -f $BINARY_DIR/grub.cfg ]; then
        cp $BINARY_DIR/grub.cfg $grub_dir/ 2>/dev/null
        cp $BINARY_DIR/grub.cfg $binary_dir/ 2>/dev/null
    fi
fi

###################################################################################
##################### Build kernel from kernel source code      ###################
###################################################################################
# preprocess for kernel building
BUILDFLAG=FALSE
KERNEL_DIR=kernel
kernel_dir=$build_dir/$KERNEL_DIR
KERNEL_BIN=
DTB_BIN=

if [ x"" = x"$PLATFORM" ]; then
    #do nothing
	echo "Do not build kernel."
elif [ x"ARM32" = x"$TARGETARCH" ]; then
	KERNEL_BIN=$kernel_dir/arch/arm/boot/zImage
    DTB_BIN=$kernel_dir/arch/arm/boot/dts/hip04-d01.dtb

	if [ ! -f $kernel_dir/arch/arm/boot/zImage ]; then
		BUILDFLAG=TRUE

		export ARCH=arm
	fi
else
	KERNEL_BIN=$kernel_dir/arch/arm64/boot/Image
    if [ x"QEMU" = x"$PLATFORM" ]; then
        DTB_BIN=""
    else
	    DTB_BIN=$kernel_dir/arch/arm64/boot/dts/hisilicon/hip05-d02.dtb
    fi

	if [ ! -f $kernel_dir/arch/arm64/boot/Image ]; then
		BUILDFLAG=TRUE

		export ARCH=arm64
	fi
fi

if [ x"$BUILDFLAG" = x"TRUE" ]; then
    echo "Build kernel..."
    mkdir -p "$kernel_dir" 2> /dev/null

	if [ "$LOCALARCH" != "arm" -a "$LOCALARCH" != "aarch64" ]; then
		export CROSS_COMPILE=$CROSS 
	fi

	pushd $KERNEL_DIR/
	
	make mrproper
	make O=../$kernel_dir mrproper

    # kernel building
    if [ x"ARM32" = x"$TARGETARCH" ]; then
		make O=../$kernel_dir hisi_defconfig

		sed -i 's/CONFIG_HAVE_KVM_IRQCHIP=y/# CONFIG_VIRTUALIZATION is not set/g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM_MMIO=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_HAVE_KVM_CPU_RELAX_INTERCEPT=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_VIRTUALIZATION=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM_ARM_HOST=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM_ARM_MAX_VCPUS=4//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM_ARM_VGIC=y//g' ../$kernel_dir/.config
		sed -i 's/CONFIG_KVM_ARM_TIMER=y//g' ../$kernel_dir/.config

		make O=../$kernel_dir -j14 zImage
		make O=../$kernel_dir hip04-d01.dtb
        cat ../$KERNEL_BIN ../$DTB_BIN > ../$kernel_dir/.kernel
    else
		make O=../$kernel_dir defconfig
        if [ x"QEMU" = x"$PLATFORM" ]; then
    		sed -i -e '/# CONFIG_ATA_OVER_ETH is not set/ a\CONFIG_VIRTIO_BLK=y' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_SCSI_BFA_FC is not set/ a\# CONFIG_SCSI_VIRTIO is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VETH is not set/ a\# CONFIG_VIRTIO_NET is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_SERIAL_FSL_LPUART is not set/ a\# CONFIG_VIRTIO_CONSOLE is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRT_DRIVERS is not set/ a\CONFIG_VIRTIO=y' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRTIO_PCI is not set/ a\# CONFIG_VIRTIO_BALLOON is not set' ../$kernel_dir/.config
    		sed -i -e '/# CONFIG_VIRTIO_MMIO is not set/ a\# CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES is not set' ../$kernel_dir/.config
    		sed -i 's/# CONFIG_VIRTIO_MMIO is not set/CONFIG_VIRTIO_MMIO=y/g' ../$kernel_dir/.config
        fi
		make O=../$kernel_dir -j14 Image

	    mkdir -p "../$kernel_dir/arch/arm64/boot/dts/hisilicon"
		make O=../$kernel_dir hisilicon/hip05-d02.dtb
    fi

    # postprocess for kernel building
	if [ "$LOCALARCH" = "arm" -o "$LOCALARCH" = "aarch64" ]; then
		make O=../$kernel_dir -j14 modules
		make O=../$kernel_dir -j14 modules_install
		make O=../$kernel_dir -j14 firmware_install
	fi

	popd
fi

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
######################### Uncompress the distribution   ###########################
###################################################################################
distro_dir=$build_dir/$DISTRO_DIR/$DISTRO
image=`ls "$DISTRO_DIR/" | grep -E "^$DISTRO*" | grep -E "$TARGETARCH" | grep -v ".sum"`
if [ x"" != x"$DISTRO" ] && [ x"" != x"$image" ] && [ ! -d "$distro_dir" ]; then
    mkdir -p "$distro_dir" 2> /dev/null
    
    echo "Uncompress the distribution($DISTRO) ......"
    if [ x"${image##*.}" = x"bz2" ] ; then
    	TEMP=${image%.*}
    	if [ x"${TEMP##*.}" = x"tar" ] ; then
    		tar jxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo "This is a tar.bz2 package"
    	else
    		bunzip2 $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo "This is a bz2 package"
    	fi
    fi
    if [ x"${image##*.}" = x"gz" ] ; then
    	TEMP=${image%.*}
    	if [ x"${TEMP##*.}" = x"tar" ] ; then
    		sudo tar zxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo "This is a tar.gz package"
    	else
    		gunzip $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo "This is a gz package"
    	fi
    fi
    if [ x"${image##*.}" = x"tar" ] ; then 
    	tar xvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    	echo "This is a tar package"
    fi
    if [ x"${image##*.}" = x"xz" ] ; then 
    #	echo "This is a xz package"
    	TEMP=${image%.*}
    	if [ x"${TEMP##*.}" = x"tar" ] ; then
    		xz -d $DISTRO_DIR/$image 2> /dev/null 1>&2
    		tar xvf $DISTRO_DIR/$TEMP -C $distro_dir 2> /dev/null 1>&2
    	fi
    fi
    if [ x"${image##*.}" = x"tbz" ] ; then
    	tar jxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    fi
    if [ x"${image}" = x"" ] ; then
    	echo "Can not find the suitable root filesystem!"
        exit 1
    fi
fi

installresult=0
###################################################################################
########################## Install Caliper for Estuary     ########################
###################################################################################
if [ x"Caliper" = x"$INSTALL" ]; then
	pushd caliper
	echo "Start to install Caliper..."
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
		echo "Installing $compiler..."
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
########################## Check and report build resutl   ########################
###################################################################################
echo ""
echo -e "\033[32m==========================================================================\033[0m"
if [ x"" != x"$PLATFORM" ]; then
    echo -e "\033[32mBuilding completed! Most binaries can be found in $binary_dir direcory.\033[0m"
    echo "Of course, you can also find all original binaries in follows:"
    
    if [ x"QEMU" = x"$PLATFORM" ]; then
    	echo "UEFI is not necessary for QEMU."
    else
    	if [ x"" != x"$uefi_bin" ] && [ -f $uefi_bin ]; then
    		echo -e "\033[32mUEFI         is $uefi_bin.\033[0m"
    	else
    		echo -e "\033[31mFailed! UEFI         can not be found!\033[0m"
    	fi
    fi
    
    if [ x"QEMU" = x"$PLATFORM" ]; then
    	echo "grub is not necessary for QEMU."
    else
    	if [ x"" != x"$GRUB_BIN" ] && [ -f $GRUB_BIN ]; then
    		echo -e "\033[32mgrub         is $GRUB_BIN.\033[0m"
    	else
    		echo -e "\033[31mFailed! grub         can not be found!\033[0m"
    	fi
    fi
    
    if [ x"" != x"$KERNEL_BIN" ] && [ -f $KERNEL_BIN ]; then
    	echo -e "\033[32mkernel       is $KERNEL_BIN.\033[0m"
    else
    	echo -e "\033[31mFailed! kernel       can not be found!\033[0m"
    fi
    
    if [ x"QEMU" = x"$PLATFORM" ]; then
    	echo "dtb is not necessary for QEMU."
    else
    	if [ x"" != x"$DTB_BIN" ] && [ -f $DTB_BIN ]; then
    		echo -e "\033[32mdtb          is $DTB_BIN.\033[0m"
    	else
    		echo -e "\033[31mFailed! dtb          can not be found!\033[0m"
    	fi
    fi
    
    if [ x"" != x"$DISTRO" ]; then
		if [ -f $DISTRO_DIR/$image ]; then
    		echo -e "\033[32mDistribution is $DISTRO_DIR/$image.\033[0m"
    	else
    		echo -e "\033[31mFailed! Distribution can not be found!\033[0m"
    	fi
	fi
    
    if [ -f $toolchain_dir/$GCC64 ]; then
    	echo -e "\033[32mtoolchain    is in $toolchain_dir.\033[0m"
    else
    	echo -e "\033[31mFailed! toolchain    can not be found!\033[0m"
    fi

    if [ -d $docdir ]; then    
        grep -R "readme" $doc_dir > /dev/null
        doc_result=$?
    else
        doc_result=1
    fi

    if [ x"0" = x"$doc_result" ]; then
    	echo -e "\033[32mDocuments    is in $doc_dir.\033[0m"
    else
    	echo -e "\033[31mFailed! Documents    can not be found!\033[0m"
    fi
fi

# Binaries download report
if [ x"0" = x"$binarydl_result" ]; then
	echo -e "\033[32mPrebuilt Binaries are in $BINARY_DIR.\033[0m"
else
	echo -e "\033[31mFailed! Some Binaries ($binarydl_result) can not be found!\033[0m"
fi

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
        	        echo "Create a new rootfs image file for QEMU..."
                    cd $distro_dir
                    
                    IMAGEFILE="$DISTRO"_"$TARGETARCH"."img"
                    dd if=/dev/zero of=../$IMAGEFILE bs=1M count=10240
                    mkfs.ext4 ../$IMAGEFILE -F
                    mkdir -p ../tempdir 2>/dev/null
                    sudo mount ../$IMAGEFILE ../tempdir
					echo "Produce the rootfs image file for QEMU..."
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
	qemu_dir=`pwd`/$build_dir/qemu
	mkdir -p $qemu_dir 2> /dev/null

	QEMU=`find $qemu_dir -name qemu-system-aarch64 2>/dev/null`
	if [ x"" = x"$QEMU" ]; then
		pushd qemu/
        if [ ! -f ".initialized" ]; then
            sudo apt-get install -y gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev
            if [ x"$?" = x"0" ]; then
                touch ".initialized"
            fi
        fi
        echo "Build the QEMU..."
		./configure --prefix=$qemu_dir --target-list=aarch64-softmmu
		make -j14
		make install
		popd
	    QEMU=`find $qemu_dir -name qemu-system-aarch64 2>/dev/null`
	fi
	
# Run the qemu
    echo "Start QEMU..."
	$QEMU -machine virt -cpu cortex-a57 \
	    -kernel `pwd`/$KERNEL_BIN \
	    -drive if=none,file=$rootfs,id=fs \
	    -device virtio-blk-device,drive=fs \
	    -append "$CMDLINE" \
	    -nographic
fi
