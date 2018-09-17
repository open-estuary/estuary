#!/bin/bash

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

###################################################################################
# update_module_check <module_name> <output_dir>
###################################################################################
update_module_check()
{
    (
    module_name=$1
    output_dir=$2

    last_build=`cat $output_dir/.$module_name 2>/dev/null`
    last_commit=`get_last_commit $output_dir/../$module_name`
    if [ x"$last_build" != x"$last_commit" ]; then
        return 1
    fi
    if [ x"$last_build" = x"" ]; then
        return 1
    fi

    return 0
    )
}

###################################################################################
# gen_module_build_log <module_name> <output_dir>
###################################################################################
gen_module_build_log()
{
    (
    module_name=$1
    output_dir=$2
    last_commit=`get_last_commit $output_dir/../$module_name`
    echo $last_commit > $output_dir/.$module_name 2>/dev/null
    )
}

###################################################################################
# rm_module_build_log <module_name> <output_dir>
###################################################################################
rm_module_build_log()
{
    (
    module_name=$1
    output_dir=$2
    rm -f $output_dir/.$module_name 2>/dev/null
    )
}

