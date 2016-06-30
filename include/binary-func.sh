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
		if ! check_sum . $checksum_dir/$checksum_file; then
			wget -c $binary_source/$remote_file || return 1
			if ! check_sum . $checksum_dir/$checksum_file; then
				return 1
			fi
		fi

		origin_file=`echo $remote_file | sed 's/.*\///'`
		target_file=`echo $checksum_file | sed 's/\.sum$//'`
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
# copy_common_binaries <src_dir> <target_dir>
###################################################################################
copy_common_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/mini-rootfs.cpio.gz ]; then
		cp $src_dir/mini-rootfs.cpio.gz $target_dir || return 1
	fi
	
	if [ -f $target_dir/deploy-utils.tar.bz2 ]; then
		cp $src_dir/deploy-utils.tar.bz2 $target_dir || return 1
	fi

	return 0
	)
}

###################################################################################
# copy_d02_binaries <src_dir> <target_dir>
###################################################################################
copy_d02_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/CH02TEVBC_V03.bin ]; then
		cp $src_dir/CH02TEVBC_V03.bin $target_dir || return 1
	fi

	return 0
	)
}

###################################################################################
# copy_hikey_binaries <src_dir> <target_dir>
###################################################################################
copy_d02_binaries()
{
	(
	src_dir=$1
	target_dir=$2
	if [ ! -f $target_dir/hisi-idt.py ]; then
		cp $src_dir/hisi-idt.py $target_dir || return 1
	fi

	if [ ! -f $target_dir/nvme.img ]; then
		cp $src_dir/nvme.img $target_dir || return 1
	fi

	return 0
	)
}

###################################################################################
# copy_binaries <plat> <src_dir> <target_dir>
###################################################################################
copy_binaries()
{
	(
	plat=$1
	src_dir=$2
	target_dir=$3
	if [ x"$plat" = x"D02" ]; then
		copy_d02_binaries $src_dir $target_dir/D02
	elif [ x"$plat" = x"HiKey" ]; then
		copy_hikey_binaries $src_dir $target_dir/HiKey
	fi
	)
}

