#!/bin/bash

###################################################################################
# copy_plat_doc <plat> <src_dir> <target_dir>
###################################################################################
copy_plat_doc()
{
    (
    plat=$1
    src_dir=$2
    target_dir=$3
    for doc in `find $src_dir -type f -name "*.4$plat.md" 2>/dev/null`; do
        target_doc=`basename $doc | sed "s/\(.*\)\(.4$plat\)\(.md\)$/\1\3/"`
        cp $doc $target_dir/$target_doc || return 1
    done

    return 0
    )
}

###################################################################################
# copy_all_docs <platforms> <src_dir> <target_dir>
###################################################################################
copy_all_docs()
{
    (
    platforms=`echo $1 | tr ',' ' '`
    src_dir=$2
    target_dir=$3

    mkdir -p $target_dir/arm64
    copy_plat_doc All $doc_src_dir $target_dir/arm64 || return 1

    for plat in ${platfroms[*]}; do
        mkdir -p $target_dir/$plat
        copy_plat_doc $plat $doc_src_dir $target_dir/$plat || return 1
        pushd $target_dir/$plat >/dev/null
        find . -maxdepth 1 -type l -print | xargs rm -f
        find ../arm64/ -maxdepth 1 -type f | xargs -i ln -s {}
        popd >/dev/null
    done

    return 0
    )
}

