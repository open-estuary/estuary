#!/bin/bash
#description: download necessary files firstly, then build target system according to indicated parameters by user
#author: Justin Zhao
#date: August 7, 2015

distros=(OpenEmbedded Debian Ubuntu OpenSuse Fedora)
distros_d01=(Ubuntu OpenSuse)
distros_d02=(OpenEmbedded Ubuntu OpenSuse Fedora)
platforms=(QEMU D01 D02)

PATH_OPENSUSE64=http://7xjz0v.com1.z0.glb.clouddn.com/dist/opensuse.img.tar.gz
PATH_UBUNTU64=http://7xjz0v.com1.z0.glb.clouddn.com/dist/ubuntu-vivid.img.tar.gz
PATH_FEDORA64=http://7xjz0v.com1.z0.glb.clouddn.com/dist/fedora-22.img.tar.gz
PATH_OPENSUSE32=http://download.opensuse.org/ports/armv7hl/distribution/13.2/appliances/openSUSE-13.2-ARM-XFCE.armv7-rootfs.armv7l-1.12.1-Build33.7.tbz
PATH_UBUNTU32=http://releases.linaro.org/15.02/ubuntu/lt-d01/linaro-utopic-server-20150220-698.tar.gz

usage()
{
	echo "usage:"
	echo -n "build.sh [ -p "
	echo -n ${platforms[*]} | sed "s/ / | /g"
	echo -n " ] [ -d "
	echo -n ${distros[*]} | sed "s/ / | /g"
	echo " ] "

	echo -e "\n -h,--help	print this message"
	echo " -p,--platform	platform"
	echo " -d,--distro	distribuation"
	echo "		*for D01, only support Ubuntu, OpenSuse"
	echo "		*for D02, support OpenEmbedded, Ubuntu, OpenSuse, Fedora"
}

# identify the distro
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

	echo "Error distribution!"
    usage
	exit 1
}

check_platform()
{
	for plat in ${platforms[@]}; do
		if [ x"$plat" = x"$1" ]; then 
			PLATFORM=$1
			return
		fi
	done
	echo "Error platform!"
    usage
	exit 1
}

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
		* )
			echo "unknown arg $1"
			usage
			exit 1
			;;
    esac
	shift
done

if [ x"$PLATFORM" = x"" -o x"$DISTRO" = x"" ]; then
	usage
    exit 1
fi

# Setup host environment
automake --version | grep 'automake (GNU automake) 1.11' > /dev/null
if [ x"$?" = x"1" ]; then
  sudo apt-get update
  sudo apt-get remove -y --purge automake*
  sudo apt-get install -y automake1.11 make bc libncurses5-dev
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
mkdir -p "$build_dir" 2> /dev/null

if [ x"$TARGETARCH" = x"ARM32" ]; then
	cross_gcc=arm-linux-gnueabihf-gcc
	cross_prefix=arm-linux-gnueabihf
else
	cross_gcc=aarch64-linux-gnu-gcc
	cross_prefix=aarch64-linux-gnu
fi

# Download & uncompress the cross-compile-chain
TOOLCHAIN_DIR=toolchain
toolchain_dir=$build_dir/toolchain
GCC32=gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz
GCC64=gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux.tar.xz

if [ ! -d "$TOOLCHAIN_DIR" ] ; then
	mkdir -p "$TOOLCHAIN_DIR" 2> /dev/null
fi

wget -c http://7xjz0v.com1.z0.glb.clouddn.com/toolchain/$GCC32 -O $TOOLCHAIN_DIR/$GCC32
wget -c http://7xjz0v.com1.z0.glb.clouddn.com/toolchain/$GCC64 -O $TOOLCHAIN_DIR/$GCC64

if [ ! -d "$toolchain_dir" ] ; then
	mkdir -p "$toolchain_dir" 2> /dev/null
    cp $TOOLCHAIN_DIR/$GCC32 $toolchain_dir/
    cp $TOOLCHAIN_DIR/$GCC64 $toolchain_dir/
fi

arm_gcc=`find "$TOOLCHAIN_DIR" -name "$cross_gcc"`
if [ x"" = x"$arm_gcc" ]; then 
	package=`ls $TOOLCHAIN_DIR/*.xz | grep "$cross_prefix"`
	echo "uncompress the toolchain......"
	tar Jxf $package -C $TOOLCHAIN_DIR
	arm_gcc=`find $TOOLCHAIN_DIR -name $cross_gcc`
fi
CROSS=`pwd`/${arm_gcc%g*}
export PATH=${CROSS%/*}:$PATH
echo "Cross compiler is $CROSS"

#Download distribution according to special PLATFORM and DISTRO
DISTRO_DIR=distro
if [ ! -d "$DISTRO_DIR" ] ; then
	mkdir -p "$DISTRO_DIR" 2> /dev/null
fi

if [ x"$TARGETARCH" = x"ARM32" ] ; then
	case $DISTRO in
		"OpenSuse" )
			DISTRO_SOURCE=$PATH_OPENSUSE32
			;;
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
			* )
			DISTRO_SOURCE="none"
			;;
	esac
fi

if [ x"$DISTRO_SOURCE" = x"none" ]; then
	echo "The distributions [$DISTRO] can not be supported on $PLATFORM now!"
    usage
	exit 1
fi

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

wget -c $DISTRO_SOURCE -O $DISTRO_DIR/"$DISTRO"_"$TARGETARCH"."$postfix"
chmod 777 $DISTRO_DIR/"$DISTRO"_"$TARGETARCH".$postfix

#Download binary files
binary_dir=$build_dir/binary
BINARY_DIR=binary
BINARY_SOURCE=https://github.com/open-estuary/estuary/releases/download/bin-v1.2
if [ ! -d "$BINARY_DIR" ] ; then
	mkdir -p "$BINARY_DIR" 2> /dev/null
fi

cd $BINARY_DIR/

wget -c $BINARY_SOURCE/bl1.bin 
wget -c $BINARY_SOURCE/CH02TEVBC_V03.bin
wget -c $BINARY_SOURCE/fip.bin
wget -c $BINARY_SOURCE/grub.cfg
wget -c $BINARY_SOURCE/grubaa64.efi
wget -c $BINARY_SOURCE/hip05-d02.dtb
wget -c $BINARY_SOURCE/hulk-hip05.cpio.gzio.gz
wget -c $BINARY_SOURCE/Image
wget -c $BINARY_SOURCE/UEFI_Release.bin

cd -

if [ ! -d "$binary_dir" ] ; then
	mkdir -p "$binary_dir" 2> /dev/null
	cp $BINARY_DIR/* $binary_dir/
fi

grub_dir=$build_dir/grub
grubimg=`find $grub_dir -name *.efi`

#Prepare tools for D01's UEFI
if [ x"ARM32" = x"$TARGETARCH" ]; then
	if [ x"" = x"$grubimg" ]; then
    	# use uefi_tools to compile
        UEFI_TOOLS=tools/uefi-tools
        UEFI_DIR=uefi

    	if [ ! -d "$UEFI_TOOLS" ] ; then 
            echo "Do not find uefi-tools!"
            exit 1
        fi

     	pushd $UEFI_TOOLS/
     	echo "[d01]" >> platforms.config 
     	echo "LONGNAME=HiSilicon D01 Cortex-A15 16-cores" >> platforms.config
     	echo "BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1" >> platforms.config
     	echo "DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc" >> platforms.config
     	echo "ARCH=ARM" >> platforms.config
     	popd
    
    	export PATH=$PATH:`pwd`/uefi-tools/
    	# compile uefi for d01
    	pushd $UEFI_DIR/
    	#env CROSS_COMPILE_32=$CROSS uefi-tools/uefi-build.sh -b DEBUG d01
    	../$UEFI_TOOLS/uefi-build.sh -b DEBUG d01
    	popd
    	uefi_dir=$build_dir/uefi
    	mkdir -p "$uefi_dir" 2> /dev/null
        UEFI_BIN=`find "$UEFI_DIR" -name "D01.fd"`
    	cp $UEFI_BIN $uefi_dir/UEFI_Release.bin
    	cp $UEFI_BIN $binary_dir/UEFI_Release.bin
    
    	# compile the grub
    	mkdir -p "$grub_dir" 2> /dev/null
    	echo path:`pwd`
    	cd $grub_dir
    	absolute_dir=`pwd`
    	cd -
    	pushd grub/
    	make distclean
    	./autogen.sh
    	./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix="$absolute_dir"
    	make -j8 
    	make install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grub.efi -O arm-efi -p "efi" boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	cd -
	fi
#    cp $grub_dir/grub.efi $binary_dir/
else
	if [ x"" = x"$grubimg" ]; then
    	# compile the grub for aarch64
    	grub_dir=$build_dir/grub
    	mkdir -p "$grub_dir" 2> /dev/null
    	echo path:`pwd`
    	cd $grub_dir
    	absolute_dir=`pwd`
    	cd -
    	pushd grub/
        git reset --hard
        git checkout grub-2.02-beta2
    	./autogen.sh
    	./configure --prefix="$absolute_dir" --target=aarch64-linux-gnu 
    	make -j8
    	make  install
    	popd
    	# TODO -- check whether it is useful
    	cd $grub_dir
    	./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p ./ boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    	echo $PATH
    	cd -
    fi
#	cp $grub_dir/grubaa64.efi $binary_dir/
fi

# compile the kernel
# preprocess for kernel building
kernel_dir=$build_dir/kernel
mkdir -p "$kernel_dir" 2> /dev/null
if [ x"ARM32" = x"$TARGETARCH" ]; then
	KERNEL=`pwd`/$kernel_dir/arch/arm/boot/zImage
	if [ ! -f $kernel_dir/arch/arm/boot/zImage ]; then
		BUILDFLAG=TRUE

		export ARCH=arm
	fi
else
	KERNEL=`pwd`/$kernel_dir/arch/arm64/boot/Image
	if [ ! -f $kernel_dir/arch/arm64/boot/Image ]; then
		BUILDFLAG=TRUE

		export ARCH=arm64
	fi
fi

if [ x"$BUILDFLAG" = x"TRUE" ]; then
	if [ "$LOCALARCH" != "arm" -a "$LOCALARCH" != "aarch64" ]; then
		export CROSS_COMPILE=$CROSS 
	fi

	pushd kernel/
	
	make mrproper
	make O=../$kernel_dir mrproper
fi

# kernel building
if [ x"ARM32" = x"$TARGETARCH" ]; then
	if [ x"$BUILDFLAG" = x"TRUE" ]; then
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

		make O=../$kernel_dir -j8 zImage
		make O=../$kernel_dir hip04-d01.dtb
	fi
	DTB=$kernel_dir/arch/arm/boot/dts/hip04-d01.dtb
else
	if [ x"$BUILDFLAG" = x"TRUE" ]; then
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
		make O=../$kernel_dir -j8 Image

	    mkdir -p "../$kernel_dir/arch/arm64/boot/dts/hisilicon"
		make O=../$kernel_dir hisilicon/hip05-d02.dtb
	fi
	DTB=$kernel_dir/arch/arm64/boot/dts/hisilicon/hip05-d02.dtb
fi

# postprocess for kernel building
if [ x"$BUILDFLAG" = x"TRUE" ]; then
	if [ "$LOCALARCH" = "arm" -o "$LOCALARCH" = "aarch64" ]; then
		make O=../$kernel_dir -j8 modules
		make O=../$kernel_dir -j8 modules_install
		make O=../$kernel_dir -j8 firmware_install
	fi

	popd
fi
DTB=`pwd`/$DTB
#cat $KERNEL $DTB > $build_dir/kernel/.kernel
cp $KERNEL $binary_dir/
if [ x"QEMU" != x"$PLATFORM" ]; then
    cp $DTB $binary_dir/
fi

# Uncompress the distribution
distro_dir=$build_dir/$DISTRO_DIR/$DISTRO
if [ ! -d "$distro_dir" ] ; then
    mkdir -p "$distro_dir" 2> /dev/null
    
    image=`ls "$DISTRO_DIR/" | grep -E "^$DISTRO*" | grep -E "$TARGETARCH"`
    echo "uncompress the distribution($DISTRO) ......"
    if [ x"${image##*.}" = x"bz2" ] ; then
    	TEMP=${image%.*}
    	if [ x"${TEMP##*.}" = x"tar" ] ; then
    		tar jxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo This is a tar.bz2 package
    	else
    		bunzip2 $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo This is a bz2 package
    	fi
    fi
    if [ x"${image##*.}" = x"gz" ] ; then
    	TEMP=${image%.*}
    	if [ x"${TEMP##*.}" = x"tar" ] ; then
    		tar zxvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo This is a tar.gz package
    	else
    		gunzip $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    		echo This is a gz package
    	fi
    fi
    if [ x"${image##*.}" = x"tar" ] ; then 
    	tar xvf $DISTRO_DIR/$image -C $distro_dir 2> /dev/null 1>&2
    	echo This is a tar package
    fi
    if [ x"${image##*.}" = x"xz" ] ; then 
    #	echo This is a xz package
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
    	echo "Do not found suitable root filesystem!"
        exit 1
    fi
fi

# Build Qemu and start it
if [ x"QEMU" = x"$PLATFORM" ]; then
#Find the image file's name
	rootfs=`ls $distro_dir/*.img 2>/dev/null`
	if [ x"" = x"$rootfs" ]; then
		rootfs=`ls $distro_dir/*.raw`
	fi

	if [ x"" = x"$rootfs" ]; then
    	echo "Do not found suitable root filesystem!"
        exit 1
    fi
	
	rootfs=`pwd`/$rootfs
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

#Compile qemu
	qemu_dir=`pwd`/$build_dir/qemu
	mkdir -p $qemu_dir 2> /dev/null

	QEMU=`find $qemu_dir -name qemu-system-aarch64`
	if [ x"" = x"$QEMU" ]; then
		pushd qemu/
		./configure --prefix=$qemu_dir --target-list=aarch64-softmmu
		make -j8
		make install
		popd
	    QEMU=`find $qemu_dir -name qemu-system-aarch64`
	fi
	
# run the qemu
	$QEMU -machine virt -cpu cortex-a57 \
	    -kernel $KERNEL \
	    -drive if=none,file=$rootfs,id=fs \
	    -device virtio-blk-device,drive=fs \
	    -append "$CMDLINE" \
	    -nographic
fi
