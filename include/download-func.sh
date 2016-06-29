#!/bin/bash

###################################################################################
# download_files_witchout_path <target_dir> <checksum_source> <file_source>
###################################################################################
download_files_witchout_path()
{
	(
	target_dir=$1
	checksum_source=$2
	checksum_dir=$(cd `dirname $checksum_source` ; pwd)
	checksum_file=`basename $checksum_source`
	file_source=$3

	mkdir -p $target_dir
	if ! check_sum_without_path $target_dir $checksum_dir/$checksum_file; then
		pushd $target_dir
		download_files=($(md5sum --quiet --check $checksum_dir/$checksum_file 2>/dev/null | grep FAILED | cut -d : -f 1))
		for download_file in ${download_files[@]}; do
			wget -c $file_source/$download_file || return 1
		done
		popd
		
		check_sum_without_path $target_dir $checksum_source || return 1
	fi

	return 0
	)
}

###################################################################################
# download_files_with_path <all_files> <file_source>
###################################################################################
download_files_with_path()
{
	(
	all_files=($(echo $1 | tr ',' ' '))
	file_source=$2
	for download_file in ${all_files[@]}; do
		target_dir=`dirname $download_file`
		mkdir -p $target_dir ; rm -f $download_file 2>/dev/null
		wget -c $file_source/$download_file -O $download_file ; return 1
	done

	return 0
	)
}

