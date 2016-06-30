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

