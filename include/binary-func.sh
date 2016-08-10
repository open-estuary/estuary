#!/bin/bash

###################################################################################
# int download_binaries <ftp_cfgfile> <ftp_addr> <target_dir>
###################################################################################
download_binaries()
{
	(
	ftp_cfgfile=$1
	ftp_addr=$2
	target_dir=$3

	binaries=(`get_field_content $ftp_cfgfile prebuild`)

	pushd $target_dir >/dev/null
	for binary in ${binaries[*]}; do
		target_file=`expr "X$binary" : 'X\([^:]*\):.*' | sed 's/ //g'`
		target_addr=`expr "X$binary" : 'X[^:]*:\(.*\)' | sed 's/ //g'`
		binary_file=`basename $target_addr`
		if [ ! -f ${binary_file}.sum ]; then
			rm -f .${binary_file}.sum 2>/dev/null
			wget -c $ftp_addr/${target_addr}.sum || return 1
		fi

		if [ ! -f $binary_file ] || ! check_sum . ${binary_file}.sum; then
			rm -f $binary_file 2>/dev/null
			wget -c $ftp_addr/$target_addr || return 1
			check_sum . ${binary_file}.sum || return 1
		fi
		
		if [ x"$target_file" != x"$binary_file" ]; then
			rm -f $target_file 2>/dev/null
			ln -s $binary_file $target_file
		fi
	done

	popd >/dev/null
	return 0
	)
}

###################################################################################
# Copy_Comm_binaries <src_dir> <target_dir>
###################################################################################
Copy_Comm_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/mini-rootfs.cpio.gz ]; then
		cp $src_dir/mini-rootfs.cpio.gz $target_dir/ || return 1
	fi
	
	if [ ! -f $target_dir/deploy-utils.tar.bz2 ]; then
		cp $src_dir/deploy-utils.tar.bz2 $target_dir/ || return 1
	fi

	if [ ! -f $target_dir/grub.cfg ]; then
		cp $src_dir/grub.cfg $target_dir/ || return 1
	fi

	return 0
	)
}

###################################################################################
# Copy_D02_binaries <src_dir> <target_dir>
###################################################################################
Copy_D02_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/CH02TEVBC_V03.bin ]; then
		cp $src_dir/CH02TEVBC_V03.bin $target_dir/ || return 1
	fi

	return 0
	)
}

###################################################################################
# Copy_D03_binaries <src_dir> <target_dir>
###################################################################################
Copy_D03_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	return 0
	)
}

###################################################################################
# Copy_HiKey_binaries <src_dir> <target_dir>
###################################################################################
Copy_HiKey_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/hisi-idt.py ]; then
		cp $src_dir/hisi-idt.py $target_dir/ || return 1
	fi

	if [ ! -f $target_dir/nvme.img ]; then
		cp $src_dir/nvme.img $target_dir/ || return 1
	fi

	return 0
	)
}

###################################################################################
# Copy_QEMU_binaries <src_dir> <target_dir>
###################################################################################
Copy_QEMU_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	return 0
	)
}


###################################################################################
# copy_all_binaries <platforms> <src_dir> <target_dir>
###################################################################################
copy_all_binaries()
{
	(
	platforms=`echo $1 | tr ',' ' '`
	src_dir=$2
	target_dir=$3

	mkdir -p $target_dir/arm64
	Copy_Comm_binaries $src_dir $target_dir/arm64 || return 1

	for plat in ${platfroms[*]}; do
		mkdir -p $target_dir/$plat
		Copy_${plat}_binaries $src_dir $target_dir/$plat || return 1
	done

	return 0
	)
}

