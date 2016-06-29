#!/bin/bash

###################################################################################
# get_last_commit <target_dir>
###################################################################################
get_last_commit()
{
	(
	target_dir=$1
	pushd $target_dir
	git log -n 1 2>/dev/null | grep -P "^(commit ).*" | awk '{print $2}'
	popd
	)
}


