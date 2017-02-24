#!/bin/bash

GRUB_DIR=grub
TOPDIR=$(cd `dirname $0` ; pwd)

###################################################################################
# build arguments
###################################################################################
CLEAN=
PLATFORM=
OUTPUT_DIR=
CROSS_COMPILE=

###################################################################################
# Include
###################################################################################
. $TOPDIR/submodules-common.sh

###################################################################################
# build_grub_usage
###################################################################################
build_grub_usage()
{
cat << EOF
Usage: build-grub.sh [clean] --cross=xxx --output=xxx
    clean: clean the grub binary files
    --cross: cross compile prefix (if the host is not arm architecture, it must be specified.)
    --output: target binary output directory

Example:
    build-grub.sh --output=./workspace
    build-grub.sh --output=./workspace --cross=aarch64-linux-gnu-
    build-grub.sh clean --output=./workspace

EOF
}

###################################################################################
# build_check <prefix> <output>
###################################################################################
build_check()
{
    (
    prefix=$1
    output=$2
    if [ ! -d $output ] || [ ! -f $output/binary/arm64/grubaa64.efi ]; then
        return 1
    fi

    return 0
    )
}

###################################################################################
# build_grub <prefix_dir> <output_dir>
###################################################################################
build_grub()
{
    (
    prefix_dir=$(cd $1; pwd)
    output_dir=$(cd $2; pwd)
    core_num=`cat /proc/cpuinfo | grep "processor" | wc -l`

    pushd $GRUB_DIR

    ./autogen.sh
    ./configure --prefix=$prefix_dir --with-platform=efi \
        --build=x86_64-linux-gnu --target=aarch64-linux-gnu \
        --disable-werror --host=x86_64-linux-gnu
    make -j${core_num} && make install

    pushd $prefix_dir
    ./bin/grub-mkimage -v -o grubaa64.efi -O arm64-efi -p / boot chain configfile efinet ext2 fat \
        iso9660 gettext help hfsplus loadenv lsefi normal ntfs ntfscomp part_gpt part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
    popd
    grub_efi=`find "$prefix_dir" -name "*.efi" 2>/dev/null`
    mkdir -p $output_dir/binary/arm64
    cp $grub_efi $output_dir/binary/arm64/

    popd
    )
}

###################################################################################
# clean_grub <output_dir> <prefix_dir>
###################################################################################
clean_grub()
{
    (
    echo "Clean grub ......"
    output_dir=$1
    prefix_dir=$2
    rm -f $output_dir/binary/arm64/grubaa64.efi
    rm -rf $prefix_dir
    return 0
    )
}

###################################################################################
# build grub
###################################################################################
while test $# != 0
do
    case $1 in
        --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        *) ac_option=$1 ;;
    esac

    case $ac_option in
            clean) CLEAN="yes" ;;
    --cross) CROSS_COMPILE=$ac_optarg ;;
            --output) OUTPUT_DIR=$ac_optarg ;;
            *) echo -e "\033[31mUnknown option $ac_option!\033[0m"
        build_grub_usage ; exit 1 ;;
    esac

    shift
done

###################################################################################
# Check args
###################################################################################
if [ x"$OUTPUT_DIR" = x"" ]; then
    echo -e "\033[31mPlease specify output directory!\033[0m"
    build_grub_usage ; exit 1
fi

if [ x"$CROSS_COMPILE" != x"" ]; then
    export CROSS_COMPILE=$CROSS_COMPILE
fi

###################################################################################
# Clean grub
###################################################################################
if [ x"$CLEAN" = x"yes" ]; then
    rm_module_build_log grub $OUTPUT_DIR
    clean_grub $OUTPUT_DIR $OUTPUT_DIR/grub
    exit 0
fi

###################################################################################
# Build grub
###################################################################################
# check update
if build_check $OUTPUT_DIR/grub $OUTPUT_DIR && update_module_check grub $OUTPUT_DIR; then
    exit 0
fi

# build grub and check result
rm_module_build_log grub $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/grub
if build_grub $OUTPUT_DIR/grub $OUTPUT_DIR && build_check $OUTPUT_DIR/grub $OUTPUT_DIR; then
    gen_module_build_log grub $OUTPUT_DIR ; exit 0
else
    exit 1
fi

