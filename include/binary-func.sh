#!/bin/bash

###################################################################################
# download_binaries <target_dir> <checksum_dir> <binary_source>
###################################################################################
download_binaries()
{
	(
	target_dir=$1
	checksum_dir=$(cd $2; pwd)
	binary_source=$3

	checksum_files=$(cd $checksum_dir 2>/dev/null; ls *.sum 2>/dev/null)
	pushd $target_dir >/dev/null
	for checksum_file in ${checksum_files[*]}; do
		remote_file=`cat $checksum_dir/$checksum_file | awk '{print $2}'`
		origin_file=`echo $remote_file | sed 's/.*\///'`
		target_file=`echo $checksum_file | sed 's/\.sum$//'`
		if ! check_sum . $checksum_dir/$checksum_file || [ ! -f $target_file ] ; then
			rm -f $origin_file 2>/dev/null
			wget -c $binary_source/$remote_file || return 1
			if ! check_sum . $checksum_dir/$checksum_file; then
				return 1
			fi
		fi

		if [ x"$target_file" != x"$origin_file" ]; then
			rm -f $target_file 2>/dev/null
			ln -s $origin_file $target_file
		fi
	done
	popd

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

