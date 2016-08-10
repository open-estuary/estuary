#!/bin/bash

###################################################################################
# get_last_commit_date <target_dir>
###################################################################################
get_last_commit_date()
{
	(
	target_dir=$1
	pushd $target_dir >/dev/null
	version=`git log -n 1 2>/dev/null | grep -Po "^(Date:).*" | sed 's/Date: *//g'`
	version=${version:-master}
	echo $version
	popd >/dev/null
	)
}

###################################################################################
# get_last_commit <target_dir>
###################################################################################
get_last_commit()
{
	(
	target_dir=$1
	pushd $target_dir >/dev/null
	git log -n 1 2>/dev/null | grep -P "^(commit ).*" | awk '{print $2}'
	popd >/dev/null
	)
}


