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

	pushd $target_dir >/dev/null
	if [ -f .$checksum_file ]; then
		if diff .$checksum_file $checksum_file >/dev/null 2>&1; then
			return 0
		fi
		rm -f .$checksum_file 2>/dev/null
	fi

	if ! md5sum --quiet --check $checksum_dir/$checksum_file >/dev/null 2>&1; then
		return 1
	fi

	cp $checksum_file .$checksum_file

	popd >/dev/null
	return 0
	)
}

