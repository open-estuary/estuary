#!/bin/bash

###################################################################################
# check_sum <target_dir> <checksum_source>
###################################################################################
check_sum()
{
	(
	target_dir=$1
	checksum_source=$2
	checksum_dir=$(cd `dirname $checksum_source` ; pwd)
	checksum_file=`basename $checksum_source`
	checksum_temp=`mktemp /tmp/.$checksum_file.XXXX`
	cat $checksum_dir/$checksum_file | sed 's/[^ ]*\///g' >$checksum_temp

	pushd $target_dir >/dev/null
	if [ -f .$checksum_file ]; then
		if diff .$checksum_file $checksum_temp >/dev/null 2>&1; then
			rm -f $checksum_temp 2>/dev/null
			return 0
		fi

		rm -f .$checksum_file 2>/dev/null
	fi

	if md5sum --quiet --check $checksum_temp >/dev/null 2>&1; then
		mv $checksum_temp .$checksum_file
		return 0
	else
		rm -f $checksum_temp 2>/dev/null
		return 1
	fi

	popd >/dev/null
	)
}

