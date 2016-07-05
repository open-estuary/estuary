#!/bin/bash

###################################################################################
# get_toolchain <toolchainsum_source_file>
###################################################################################
get_toolchain()
{
	(
	toolchainsum_source_file=$1
	cat $toolchainsum_source_file 2>/dev/null | awk '{print $2}' | sed 's/.*\///'
	)
}

###################################################################################
# download_toolchains <target_dir> <toolchainsum_source_file> <toolchain_source>
###################################################################################
download_toolchain()
{
	(
	target_dir=$(cd $1; pwd)
	toolchainsum_source_file=$2
	toolchain_source=$3
	toolchain=`cat $toolchainsum_source_file 2>/dev/null | awk '{print $2}'`

	if ! check_sum $target_dir $toolchainsum_source_file >/dev/null 2>&1; then
		pushd $target_dir >/dev/null
		wget $toolchain_source/$toolchain || return 1
		popd >/dev/null
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
		|| [ !- f $target_dir/$toolchain ]; then
		rm -f $target_dir/$toolchain 2>/dev/null
		cp $src_dir/$toolchain $target_dir/$toolchain || return 1
		rm -f $target_dir/.toolchain.sum 2>/dev/null
		cp $src_dir/.toolchain.sum $target_dir/.toolchain.sum || return 1
	fi

	return 0
	)
}


