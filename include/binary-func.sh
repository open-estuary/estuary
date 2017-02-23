#!/bin/bash

###################################################################################
# int binary_md5_compare <file1> <file2>
###################################################################################
binary_md5_compare()
{
    local file1=$1
    local file2=$2
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 1
    fi

    if [ "$(md5sum $file1 | awk '{print $1}')" != "$(md5sum $file2 | awk '{print $1}')" ]; then
        return 1
    fi

    return 0
}

###################################################################################
# int download_binaries <ftp_cfgfile> <ftp_addr> <target_dir>
###################################################################################
download_binaries()
{
    (
    ftp_cfgfile=$1
    ftp_addr=$2
    target_dir=$3

    binaries=(`get_field_content $ftp_cfgfile prebuild`)

    pushd $target_dir >/dev/null
    for binary in ${binaries[*]}; do
        target_file=`expr "X$binary" : 'X\([^:]*\):.*' | sed 's/ //g'`
        target_addr=`expr "X$binary" : 'X[^:]*:\(.*\)' | sed 's/ //g'`
        binary_file=`basename $target_addr`
        if [ ! -f ${binary_file}.sum ]; then
            rm -f .${binary_file}.sum 2>/dev/null
            wget $ftp_addr/${target_addr}.sum || return 1
        fi

        if [ ! -f $binary_file ] || ! check_sum . ${binary_file}.sum; then
            rm -f $binary_file 2>/dev/null
            wget ${WGET_OPTS} $ftp_addr/$target_addr || return 1
            check_sum . ${binary_file}.sum || return 1
        fi

        if [ x"$target_file" != x"$binary_file" ]; then
            rm -f $target_file 2>/dev/null
            ln -s $binary_file $target_file
        fi
    done

    popd >/dev/null
    return 0
    )
}

###################################################################################
# int Copy_deploy_utils <deploy_utils_file> <setup_file> <target_dir>
###################################################################################
Copy_deploy_utils()
{
    (
    deploy_utils_file=$1
    setup_file=$2
    target_dir=$3

    check_file_update $target_dir/deploy-utils.tar.bz2 $deploy_utils_file $setup_file && return 0
    tempdir=`mktemp -d deploy.XXXX`
    while true; do
        tar xf "$deploy_utils_file" -C "$tempdir" || break
        rm -f $tempdir/usr/bin/setup.sh 2>/dev/null
        cp $setup_file $tempdir/usr/bin/ || break
        pushd $tempdir >/dev/null
        tar cjf ../deploy-utils.tar.bz2 *
        popd >/dev/null
        mkdir -p $target_dir
        rm -f $target_dir/deploy-utils.tar.bz2 2>/dev/null
        mv deploy-utils.tar.bz2 $target_dir/ || break
        rm -rf $tempdir 2>/dev/null
        return 0
    done

    rm -f deploy-utils.tar.bz2 2>/dev/null
    rm -rf $tempdir 2>/dev/null
    return 1
    )
}

###################################################################################
# int Copy_grub_cfg <src_dir> <target_dir> <plat>
###################################################################################
Copy_grub_cfg()
{
    local src_dir=$1
    local target_dir=$2
    local plat=$3

    check_file_update $target_dir/grub.cfg $src_dir/grub.cfg && return 0

    default_menuentry=`grep -Po -i -m 1 "(?<=\-\-id )([^ ]*$plat[^ ]*)(?= *{)" $src_dir/grub.cfg`
    if [ x"$default_menuentry" = x"" ]; then
        return 0
    fi

    cat > $target_dir/grub.cfg << EOF
# NOTE: Please remove the unused boot items according to your real condition.
# Sample GRUB configuration file
#

# Boot automatically after 3 secs.
set timeout=3

# By default, boot the Linux
set default=${default_menuentry}

EOF
    sed -n "/\"${plat}.*\" *--id .*{/,/}/p" $src_dir/grub.cfg >> $target_dir/grub.cfg
    sed -i '/}/G' $target_dir/grub.cfg
    return 0
}

###################################################################################
# Copy_Comm_binaries <src_dir> <target_dir>
###################################################################################
Copy_Comm_binaries()
{
    (
    src_dir=$1
    target_dir=$2

    # copy mini-rootfs.cpio.gz
    if ! binary_md5_compare "$src_dir/mini-rootfs.cpio.gz" "$target_dir/mini-rootfs.cpio.gz"; then
        rm -f $target_dir/mini-rootfs.cpio.gz 2>/dev/null
        cp $src_dir/mini-rootfs.cpio.gz $target_dir/ || return 1
    fi

    return 0
    )
}

###################################################################################
# Copy_HiKey_binaries <src_dir> <target_dir>
###################################################################################
Copy_HiKey_binaries()
{
    (
    src_dir=$1
    target_dir=$2
    if [ ! -f $target_dir/hisi-idt.py ]; then
        cp $src_dir/hisi-idt.py $target_dir/ || return 1
    fi

    if [ ! -f $target_dir/nvme.img ]; then
        cp $src_dir/nvme.img $target_dir/ || return 1
    fi

    return 0
    )
}

###################################################################################
# copy_all_binaries <platforms> <src_dir> <target_dir>
###################################################################################
copy_all_binaries()
{
    (
    platforms=`echo $1 | tr ',' ' '`
    src_dir=$2
    target_dir=$3

    mkdir -p $target_dir/arm64
    Copy_Comm_binaries $src_dir $target_dir/arm64 || return 1

    for plat in ${platfroms[*]}; do
        mkdir -p $target_dir/$plat
        Copy_grub_cfg $src_dir $target_dir/$plat $plat || return 1
        if declare -F Copy_${plat}_binaries >/dev/null; then
            Copy_${plat}_binaries $src_dir $target_dir/$plat || return 1
        fi
    done

    return 0
    )
}

