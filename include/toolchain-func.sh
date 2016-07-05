#!/bin/bash

###################################################################################
# get_toolchain <arch> <toolchainsum_source_file>
###################################################################################
get_toolchain()
{
	(
	arch=$1
	toolchainsum_source_file=$2
	cat $toolchainsum_source_file 2>/dev/null | grep $arch | awk '{print $2}' | sed 's/.*\///'
	)
}

###################################################################################
# download_toolchains <target_dir> <toolchainsum_source_file> <toolchain_source>
###################################################################################
download_toolchains()
{
	(
	target_dir=$(cd $1; pwd)
	toolchainsum_source_file=$2
	toolchain_source=$3
	
	checksum_file=`basename $toolchainsum_source_file`
	checksum_dir=`dirname $toolchainsum_source_file`
	checksum_dir=`cd $checksum_dir; pwd`

	if ! check_sum $target_dir $checksum_dir/$checksum_file >/dev/null 2>&1; then
		pushd $target_dir >/dev/null
		toolchain_files=(`md5sum --quiet --check $checksum_dir/$checksum_file 2>/dev/null | grep "FAILED" | cut -d : -f 1`)
		for toolchain_file in ${toolchain_files[*]}; do
			rm -f $toolchain_file 2>/dev/null
			wget -c $toolchain_source/$toolchain_file || return 1
		done
		popd >/dev/null

		if ! check_sum $target_dir $checksum_dir/$checksum_file >/dev/null 2>&1; then
			return 1
		fi
	fi

	return 0
	)
}

###################################################################################
# copy_toolchain <toolchain> <src_dir> <target_dir>
###################################################################################
copy_toolchain()
{
	(
	toolchain=$1
	src_dir=$2
	target_dir=$3
	if ! (diff $src_dir/.toolchain.sum $target_dir/.toolchain.sum >/dev/null 2>&1) \
		|| [ ! -f $target_dir/$toolchain ]; then
		rm -f $target_dir/$toolchain 2>/dev/null
		cp $src_dir/$toolchain $target_dir/$toolchain || return 1
		rm -f $target_dir/.toolchain.sum 2>/dev/null
		cp $src_dir/.toolchain.sum $target_dir/.toolchain.sum || return 1
	fi

	return 0
	)
}

###################################################################################
# uncompress_toolchains <toolchainsum_source_file> <src_dir>
###################################################################################
uncompress_toolchains()
{
	(
	toolchainsum_source_file=$1
	src_dir=$2

	toolchain_files=(`cat $toolchainsum_source_file 2>/dev/null | awk '{print $2}' | sed 's/.*\///'`)
	for toolchain_file in ${toolchain_files[*]}; do
		toolchain_dir=`get_compress_file_prefix $toolchain_file`
		if [ ! -d $src_dir/$toolchain_dir ]; then
			if ! uncompress_file $src_dir/$toolchain_file $src_dir; then
				rm -rf $src_dir/$toolchain_dir 2>/dev/null ; return 1
			fi
		fi
	done

	return 0
	)
}

