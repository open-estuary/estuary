#!/bin/bash

top_dir=$(cd `dirname $0`; cd .. ; pwd)
sh_dir=${top_dir}/submodules
. ${top_dir}/Include.sh
home_dir=$(cd ${top_dir}/.. ; pwd)


usage()
{
	echo "Usage: ./clean_distro.sh --distro=DISTRO --version=VERSION --envlist=ENVLIST --build_dir=BUILD_DIR --build_kernel=FALSE"
}

if [ $# -ne 5 ]; then
	usage
	exit 1
fi

###################################################################################
# get args
###################################################################################
while test $# != 0
do
    case $1 in
        --*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ;;
        *) ac_option=$1 ;;
    esac

    case $ac_option in
    --distro) distro=$ac_optarg ;;
    --version) version=$ac_optarg ;;
    --envlist) envlist=$ac_optarg ;;
    --build_dir) build_dir=$ac_optarg ;;
    --build_kernel) build_kernel_pkg_only=$ac_optarg ;;
    *) echo "Unknown option $ac_option!"
        build_platform_usage ; exit 1 ;;
    esac

    shift
done


envlist_dir=${build_dir}/tmp/${distro}
envlist_file=${envlist_dir}/env.list
build_absolute_dir=${build_dir}

# get relative path used in docker
sh_dir=$(echo $sh_dir| sed "s#$home_dir/##")
build_dir=$(echo $build_dir| sed "s#$home_dir/##")

# genrate env.list
mkdir -p ${envlist_dir}
rm -f ${envlist_file}
touch ${envlist_file}
for var in ${envlist}; do
	echo ${var} >> ${envlist_file}
done
sort -n ${envlist_file} | uniq > test.txt
cat test.txt > ${envlist_file}
rm -f test.txt

if [ "${distro}" == "common" ];then
    ./submodules/${distro}-clean.sh ${version} ${build_absolute_dir}
    if [ $? -ne 0 ]; then
        exit 1
    else
        exit 0
    fi
fi

# 1) clean
docker_run_sh ${distro} ${sh_dir} ${home_dir} ${envlist_file} ${distro}-clean.sh \
	${version}  ${build_dir}
