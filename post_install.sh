#!/bin/bash
#author: Justin Zhao
#date: 31/10/2015
#description: automatically call all post install scripts in post_dir

lastupdate="2015-10-15"
post_dir="/usr/bin/estuary/postinstall"

###################################################################################
############################# Check initilization status ##########################
###################################################################################
check_init()
{
    tmpfile=$1
    tmpdate=$2

    if [ -f "$tmpfile" ]; then
	    inittime=`stat -c %Y $tmpfile`
	    checktime=`date +%s -d $tmpdate`

	    if [ $inittime -gt $checktime ]; then
	          return 1
	    fi
	fi

	return 0
}

for fullfile in $post_dir/*
do
	file=${fullfile##*/}
	if [ -f $fullfile ]; then
		check_init "$post_dir/.$file" $lastupdate
		if [ x"0" = x"$?" ]; then
			$fullfile
			if [ x"0" = x"$?" ]; then
				touch "$post_dir/.$file"
			fi
		fi
	fi
done
