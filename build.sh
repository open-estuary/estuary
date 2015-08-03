#!/bin/bash

distros=(OpenEmbedded Debian Ubuntu OpenSuse Fedora)
distros_d01=(Ubuntu OpenSuse Fedora)
distros_evb=(OpenEmbedded)
distros_d02=(OpenEmbedded Ubuntu OpenSuse Fedora)
platforms=(QEMU D01 EVB D02)

PATH_OPENSUSE_D02=http://download.opensuse.org/ports/aarch64/distribution/13.1/appliances/openSUSE-13.1-ARM-JeOS.aarch64-rootfs.aarch64-1.12.1-Build37.1.tbz
PATH_UBUNTU_D02=http://snapshots.linaro.org/ubuntu/images/developer-arm64/latest/linaro-utopic-developer-20150410-92.tar.gz
PATH_OPENSUSE_D01=uhttp://download.opensuse.org/ports/armv7hl/distribution/13.1/appliances/openSUSE-13.1-ARM-JeOS.armv7-rootfs.armv7l-1.12.1-Build37.1.tbz
PATH_UBUNTU_D01=http://releases.linaro.org/latest/ubuntu/utopic-images/server/linaro-utopic-server-20150220-698.tar.gz

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
	echo "		*for D01, only support Ubuntu, OpenSuse, Fedora"
	echo "		*for EVB, only support OpenEmbedded"
	echo "		*for D02, support OpenEmbedded Ubuntu, OpenSuse, Fedora"
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
	elif [ x"EVB" = x"$PLATFORM" ]; then
		for dis in ${distros_evb[@]}; do
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

	echo "error distro!"
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
	echo "error platform!"
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

LOCALARCH=`uname -m`
TOOLS_DIR="`dirname $0`"
cd $TOOLS_DIR/../
build_dir=./build/$PLATFORM
mkdir -p "$build_dir" 2> /dev/null
case $PLATFORM in
	"QEMU" | "EVB" | "D02")
		cross_gcc=aarch64-linux-gnu-gcc
		cross_prefix=aarch64-linux-gnu
		;;
	"D01" )
		cross_gcc=arm-linux-gnueabihf-gcc
		cross_prefix=arm-linux-gnueabihf
		;;
esac


# uncompress the cross-compile-chain
toolchain_dir=./build/$PLATFORM/toolchain
mkdir -p "$toolchain_dir" 2> /dev/null

arm_gcc=`find "$toolchain_dir" -name "$cross_gcc"`
if [ x"" = x"$arm_gcc" ]; then 
	package=`ls ./toolchain/*.xz | grep "$cross_prefix"`
	echo "uncompress the toolchain......"
	tar Jxf $package -C $toolchain_dir
	arm_gcc=`find "$build_dir" -name $cross_gcc`
fi
CROSS=`pwd`/${arm_gcc%g*}
echo "Cross compiler is $CROSS"

#Download filesystem according to special PLATFORM and DISTRO
DISTRO_DIR=distro
if [ ! -d "$DISTRO_DIR" ] ; then
	mkdir -p "$DISTRO_DIR" 2> /dev/null
fi
if [ x"$PLATFORM" = x"D02" -o x"$PLATFORM" = x"QEMU" ] ; then
	case $DISTRO in
		"OpenSuse" )
			if [ ! -e ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tbz ] ; then
				wget $PATH_OPENSUSE_D02 
				chmod 777 openSUSE-13.1-ARM-JeOS.aarch64-rootfs.aarch64-1.12.1-Build37.1.tbz
				mv openSUSE-13.1-ARM-JeOS.aarch64-rootfs.aarch64-1.12.1-Build37.1.tbz ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tbz
			fi
			;;
		"Ubuntu" )
			if [ ! -e ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tar.gz ] ; then
				echo "$DISTRO"_"$PLATFORM".tar.gz
				curl $PATH_UBUNTU_D02 > ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tar.gz
			fi
			;;	
	esac
fi
if [ x"$PLATFORM" = x"D01" ] ; then
	case $DISTRO in
		"OpenSuse" )
			if [ ! -e ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tbz ] ; then
				curl $PATH_OPENSUSE_D01 > ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tbz
			fi
			;;
		"Ubuntu" )
			if [ ! -e ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tar.gz ] ; then
				curl $PATH_UBUNTU_D01 > ./$DISTRO_DIR/"$DISTRO"_"$PLATFORM".tar.gz	
			fi
			;;	
	esac
fi

if [ x"D01" = x"$PLATFORM" ]; then
	#build binary dir for special PLATFORM
	binary_dir=./build/$PLATFORM/binary/
	mkdir -p "$binary_dir" 2> /dev/null

	# use uefi-tools to compile
	if [ ! -d uefi-tools ] ; then 
		git clone git://git.linaro.org/uefi/uefi-tools.git
    	# add a build item for d01 in uefi-tools
    	pushd uefi-tools/
		echo "[d01]" >> platforms.config 
		echo "LONGNAME=HiSilicon D01 Cortex-A15 16-cores" >> platforms.config
		echo "BUILDFLAGS=-D EDK2_ARMVE_STANDALONE=1" >> platforms.config
		echo "DSC=HisiPkg/D01BoardPkg/D01BoardPkg.dsc" >> platforms.config
		echo "ARCH=ARM" >> platforms.config
		popd
	fi

	export PATH=$PATH:`pwd`/uefi-tools/
	# compile uefi for d01
	pushd uefi/
	#env CROSS_COMPILE_32=$CROSS ./uefi-tools/uefi-build.sh -b DEBUG d01
	../uefi-tools/uefi-build.sh -b DEBUG d01
	popd
	uefi_dir=./build/$PLATFORM/uefi
	mkdir -p "$uefi_dir" 2> /dev/null
	cp ./uefi/Build/D01/DEBUG_GCC48/FV/D01.fd $uefi_dir
	cp ./uefi/Build/D01/DEBUG_GCC48/FV/D01.fd $binary_dir

	# compile the grub
	grub_dir=./build/$PLATFORM/grub
	mkdir -p "$grub_dir" 2> /dev/null
	echo path:`pwd`
	cd $grub_dir
	absolute_dir=`pwd`
	cd -
	pushd grub/
	make distclean
	./autogen.sh
	old_path=$PATH
	export PATH=${CROSS%/*}:$PATH
	./configure --target=arm-linux-gnueabihf --with-platform=efi --prefix="$absolute_dir"
	make -j8 
	make install
	popd
	# TODO -- check whether it is useful
	cd $grub_dir
	./bin/grub-mkimage -v -o grub.efi -O arm-efi -p "efi" boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
	cd -
	cp ./$grub_dir/grub.efi ./$binary_dir
fi

if [ x"EVB" = x"$PLATFORM" ]; then
	# copy the uefi binary to build dir
	uefi_dir=./build/$PLATFORM/uefi
	mkdir -p "$uefi_dir" 2> /dev/null
	cp ./uefi/HisiPkg/PV660_EFI_L1_EVBa_TC.fd $uefi_dir
fi

if [ x"D02" = x"$PLATFORM" ]; then
	# copy the uefi binary to build dir
	binary_dir=./build/$PLATFORM/binary/
	mkdir -p "$binary_dir" 2> /dev/null
	cp -r ./estuary/binary/* $binary_dir

	# compile the grub
	grub_dir=./build/$PLATFORM/grub
	mkdir -p "$grub_dir" 2> /dev/null
	echo path:`pwd`
	cd $grub_dir
	absolute_dir=`pwd`
	cd -
	pushd grub/
	./autogen.sh
	old_path=$PATH
	export PATH=${CROSS%/*}:$PATH
	./configure --prefix="$absolute_dir" --target=aarch64-linux-gnu 
	make -j8
	make  install
	popd
	# TODO -- check whether it is useful
	cd $grub_dir
	./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p ./ boot chain configfile configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
	mv grubaa64.efi ../binary
	echo $PATH
	cd -
fi

# compile the kernel
# preprocess for kernel building
kernel_dir=./build/$PLATFORM/kernel
mkdir -p "$kernel_dir" 2> /dev/null
if [ x"D01" = x"$PLATFORM" ]; then
	if [ ! -f $kernel_dir/arch/arm/boot/zImage ]; then
		BUILDFLAG=TRUE
		KERNEL=`pwd`/$kernel_dir/arch/arm/boot/zImage

		export ARCH=arm
		if [ "$LOCALARCH" != "arm" ]; then
			export CROSS_COMPILE=$CROSS 
		fi
	fi
else
	if [ ! -f $kernel_dir/arch/arm64/boot/Image ]; then
		BUILDKERNEL=TRUE
		KERNEL=`pwd`/$kernel_dir/arch/arm64/boot/Image

		export ARCH=arm64
		if [ "$LOCALARCH" != "aarch64" ]; then
			export CROSS_COMPILE=$CROSS 
		fi
	fi
fi

if [ x"BUILDKERNEL" = x"TRUE" ]; then
	pushd kernel/
	
	make mrproper
	make O=../$kernel_dir mrproper
fi

# kernel building
if [ x"QEMU" = x"$PLATFORM" ]; then
	if [ x"BUILDKERNEL" = x"TRUE" ]; then
		make O=../$kernel_dir hulk_defconfig
		sed -i -e '/# CONFIG_ATA_OVER_ETH is not set/ a\CONFIG_VIRTIO_BLK=y' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_SCSI_BFA_FC is not set/ a\# CONFIG_SCSI_VIRTIO is not set' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_VETH is not set/ a\# CONFIG_VIRTIO_NET is not set' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_SERIAL_FSL_LPUART is not set/ a\# CONFIG_VIRTIO_CONSOLE is not set' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_VIRT_DRIVERS is not set/ a\CONFIG_VIRTIO=y' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_VIRTIO_PCI is not set/ a\# CONFIG_VIRTIO_BALLOON is not set' ../$kernel_dir/.config
		sed -i -e '/# CONFIG_VIRTIO_MMIO is not set/ a\# CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES is not set' ../$kernel_dir/.config
		sed -i 's/# CONFIG_VIRTIO_MMIO is not set/CONFIG_VIRTIO_MMIO=y/g' ../$kernel_dir/.config
		make O=../$kernel_dir -j8 Image
		make O=../$kernel_dir hisi_p660_evb_32core.dtb
	fi
	DTB=$kernel_dir/arch/arm64/boot/dts/hisi_p660_evb_32core.dtb
fi

if [ x"EVB" = x"$PLATFORM" ]; then
	if [ x"BUILDKERNEL" = x"TRUE" ]; then
		make O=../$kernel_dir hulk_defconfig
		make O=../$kernel_dir -j8 Image
		make O=../$kernel_dir hisi_p660_evb_32core.dtb
		make O=../$kernel_dir hisi_p660_evb_16core.dtb
	fi
	DTB=$kernel_dir/arch/arm64/boot/dts/hisi_p660_evb_32core.dtb
fi

if [ x"D02" = x"$PLATFORM" ]; then
	mkdir -p $kernel_dir/arch/arm64/boot/dts/hisilicon
	if [ x"BUILDKERNEL" = x"TRUE" ]; then
		make O=../$kernel_dir defconfig
		make O=../$kernel_dir -j8 Image
		make O=../$kernel_dir hisilicon/hip05-d02.dtb
	fi
	DTB=$kernel_dir/arch/arm64/boot/dts/hisilicon/hip05-d02.dtb
fi

if [ x"D01" = x"$PLATFORM" ]; then
	if [ x"BUILDKERNEL" = x"TRUE" ]; then
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
fi

# postprocess for kernel building
if [ x"BUILDKERNEL" = x"TRUE" ]; then
	if [[ "$LOCALARCH" = "arm" || "$LOCALARCH" = "aarch64" ]]; then
		make O=../$kernel_dir modules
		make O=../$kernel_dir modules_install
	fi

	popd
fi
DTB=`pwd`/$DTB
cat $KERNEL $DTB > ./build/$PLATFORM/kernel/.kernel
cp $KERNEL $binary_dir
cp $DTB $binary_dir


# uncompress the distro
distro_dir=./build/$PLATFORM/distro/$DISTRO
mkdir -p $distro_dir 2> /dev/null

if [ x"QEMU" = x"$PLATFORM" ]; then
	image=`ls "$distro_dir" | grep -E "*.img$|*.raw$"`
	
	if [ $? -ne 0 ]; then
		fs_file=`pwd`/distro/$DISTRO/`ls "distro/$DISTRO" | grep -vE "armhfp|armv7l|arm32"`
		echo "uncompress the distribution($DISTRO) ......"
		cd $distro_dir
		case ${fs_file##*.} in
			gz)
				cp $fs_file ./
				gunzip ${fs_file##*/} 
				;;
			xz)
				cp $fs_file ./
				xz -d ${fs_file##*/}
				;;
			*)
				echo "error suffix of the distro"
				exit 1
				;;
		esac
		image=`ls *.img 2>/dev/null`
		if [ x"" = x"$image" ]; then
			image=`ls *.raw`
		fi
		cd -
	fi
	
	cd $distro_dir
	ROOTFS=`pwd`/$image
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
	cd -
fi

if [ x"EVB" = x"$PLATFORM" ] || [ x"D02" = x"$PLATFORM" ] || [ x"D01" = x"$PLATFORM" ]; then
#	image=`ls "$distro_dir" | grep -E "*.img$|*.raw$"`
	image=`ls "./distro/" | grep -E "^$DISTRO*" | grep -E "$PLATFORM"`
	fs_file=`pwd`/build/$PLATFORM/distro/$DISTRO
	echo $fs_file
   	echo "uncompress the distribution($DISTRO) ......"
	if [ x"${image##*.}" = x"bz2" ] ; then
		TEMP=${image%.*}
		if [ x"${TEMP##*.}" = x"tar" ] ; then
			tar jxvf ./distro/$image -C $fs_file 2> /dev/null 1>&2
			echo This is a tar.bz2 package
		else
			bunzip2 ./distro/$image -C $fs_file 2> /dev/null 1>&2
			echo This is a bz2 package
		fi
	fi
	if [ x"${image##*.}" = x"gz" ] ; then
		TEMP=${image%.*}
		if [ x"${TEMP##*.}" = x"tar" ] ; then
			tar zxvf ./distro/$image -C $fs_file 2> /dev/null 1>&2
			echo This is a tar.gz package
		else
			gunzip ./distro/$image -C $fs_file 2> /dev/null 1>&2
			echo This is a gz package
		fi
	fi
	if [ x"${image##*.}" = x"tar" ] ; then 
		tar xvf ./distro/$image -C $fs_file 2> /dev/null 1>&2
		echo This is a tar package
	fi
	if [ x"${image##*.}" = x"xz" ] ; then 
#		echo This is a xz package
		TEMP=${image%.*}
		if [ x"${TEMP##*.}" = x"tar" ] ; then
			xz -d ./distro/$image 2> /dev/null 1>&2
			tar xvf ./distro/$TEMP -C $fs_file 2> /dev/null 1>&2
		fi
	fi
	if [ x"${image##*.}" = x"tbz" ] ; then
		sudo tar jxvf ./distro/$image -C $fs_file 2> /dev/null 1>&2
	fi
	if [ x"${image}" = x"" ] ; then
		echo no found suitable filesystem
	fi
fi

if [ x"QEMU" = x"$PLATFORM" ]; then
	
	distro_dir=./build/$PLATFORM/qemu
	all_path=`pwd`/build/$PLATFORM/qemu
	mkdir -p $distro_dir 2> /dev/null

	# compile the qemu
	QEMU=`find ./build -name qemu-system-aarch64`
	if [ x"" = x"$QEMU" ]; then
		pushd qemu/
		./configure --prefix=$all_path --target-list=aarch64-softmmu
		make -j8
		make install
		popd
		QEMU=$distro_dir/bin/qemu-system-aarch64
	fi
	
	# run the qemu
	$QEMU -machine virt -cpu cortex-a57 \
	    -kernel $KERNEL \
	    -drive if=none,file=$ROOTFS,id=fs \
	    -device virtio-blk-device,drive=fs \
	    -append "$CMDLINE" \
	    -nographic
	
fi
