#!/bin/bash -xe

top_dir=$(cd `dirname $0`; cd .. ; pwd)
sh_dir=${top_dir}/submodules
. ${top_dir}/Include.sh


usage()
{
	echo "Usage: ./clean_distro.sh --distro=DISTRO --version=VERSION --envlist=ENVLIST --build_dir=BUILD_DIR"
}

if [ $# -ne 4 ]; then
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
    *) echo "Unknown option $ac_option!"
        build_platform_usage ; exit 1 ;;
    esac

    shift
done


envlist_dir=${build_dir}/tmp
envlist_file=${envlist_dir}/env.list

# get relative path
sh_dir=$(echo $sh_dir| sed "s#$HOME/##")
build_dir=$(echo $build_dir| sed "s#$HOME/##")

# genrate env.list
mkdir -p ${envlist_dir}
for var in ${envlist}; do
	echo ${var} >> ${envlist_file}
done

# 1) clean
docker_run_sh ${distro} ${sh_dir} ${envlist_file} ${distro}-clean.sh \
	${version}  ${build_dir}
