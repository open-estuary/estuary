#!/bin/bash

###################################################################################
# get_all_binary_files <checksum_source_file>
###################################################################################
get_all_binary_files()
{
	(
	checksum_source_file=$1
	cat $checksum_source_file 2>/dev/null | sed 's/.*\///' | awk '{print $2}'
	)
}

###################################################################################
# download_binary <binary> <remote_binary>
###################################################################################
{
	(
	binary=$1
	remote_binary=$2
	)
}

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
# copy_binaries <plat> <src_dir> <target_dir>
###################################################################################
copy_binaries()
{
	(
	plat=$1
	src_dir=$2
	target_dir=$3
	)
}

