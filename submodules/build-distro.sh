#!/bin/bash -xe

top_dir=$(cd `dirname $0`; cd .. ; pwd)
envlist_dir=${top_dir}/build/tmp
envlist_file=${envlist_dir}/env.list
workspace=${top_dir}/submodules
. ${top_dir}/Include.sh


usage()
{
	echo "Usage: ./build_distro.sh --distro=DISTRO --version=VERSION --envlist=ENVLIST"
}

if [ $# -ne 3 ]; then
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
    *) echo "Unknown option $ac_option!"
        build_platform_usage ; exit 1 ;;
    esac

    shift
done


sh_dir=$(echo $workspace| sed "s#$HOME/##")

# genrate env.list
mkdir -p ${envlist_dir}
for var in ${envlist}; do
	echo ${var} >> ${envlist_file}
done

# 1) build kernel
docker_run_sh ${distro} ${sh_dir} ${envlist_file} ${distro}-build-kernel.sh ${version} 

# 2) build installer
docker_run_sh ${distro} ${sh_dir} ${envlist_file} ${distro}-build-installer.sh ${version} 

# 3) build iso
docker_run_sh ${distro} ${sh_dir} ${envlist_file} ${distro}-build-iso.sh ${version} 

# 4) build rootfs tar 

# 5) calculate md5sum
