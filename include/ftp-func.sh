#!/bin/bash

###################################################################################
# check_ftp_update <estuary_version> <estuary_dir>
###################################################################################
check_ftp_update()
{
	local estuary_version=$1
	local estuary_dir=$2
	local local_update_date=`cat .${estuary_version}.initialize 2>/dev/null`
	local last_commit_date=`get_last_commit_date $estuary_dir`
	if [ ! -f ${estuary_version}.xml ] || [ x"$local_update_date" != x"$last_commit_date" ]; then
		return 1
	fi

	return 0
}

###################################################################################
# int update_ftp_cfgfile <estuary_version> <ftp_addr> <estuary_dir>
###################################################################################
update_ftp_cfgfile()
{
	local estuary_version=$1
	local ftp_addr=$2
	local estuary_dir=$3

	local last_commit_date=`get_last_commit_date $estuary_dir`
	rm -f ${estuary_version}.xml .${estuary_version}.initialize 2>/dev/null

	wget -c $ftp_addr/config/${estuary_version}.xml || return 1
	echo $last_commit_date > .${estuary_version}.initialize

	return 0
}

