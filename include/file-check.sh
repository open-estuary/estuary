#!/bin/bash

###################################################################################
# int check_file_update <target_file> <dep_file1> <dep_file2> ...
###################################################################################
check_file_update()
{
    (
    target_file=$1
    shift
    target_file_modify=`stat -L -c %Y "$target_file" 2>/dev/null` || return 1
    for f in $@; do
        dep_file_modify=`stat -L -c %Y "$f" 2>/dev/null` || return 1
        [[ "$dep_file_modify" -gt "$target_file_modify" ]] && return 1
    done
    return 0
    )
}
