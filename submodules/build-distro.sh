#!/bin/bash -xe

top_dir=$(cd `dirname $0`; cd .. ; pwd)
sh_dir=${top_dir}/submodules
. ${top_dir}/Include.sh


usage()
{
	echo "Usage: ./build_distro.sh --distro=DISTRO --version=VERSION --envlist=ENVLIST --build_dir=BUILD_DIR --build_kernel=FALSE"
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


envlist_dir=${build_dir}/tmp
envlist_file=${envlist_dir}/env.list
build_absolute_dir=${build_dir}

# get relative path
sh_dir=$(echo $sh_dir| sed "s#$HOME/##")
build_dir=$(echo $build_dir| sed "s#$HOME/##")

# genrate env.list
mkdir -p ${envlist_dir}
rm -f ${envlist_file}
for var in ${envlist}; do
	echo ${var} >> ${envlist_file}
done
sort -n ${envlist_file} | uniq > test.txt
cat test.txt > ${envlist_file}
rm -f test.txt

# Notice:
# Build kernel pakages and iso seperately.
# The building process is:
# 1) build kernel packages and upload to estuary repo.
#    This stage should be moved to
#    https://github.com/open-estuary/distro-repo in the fucture.
# 2) build installer and iso, in which stage fetch kernel packages from
#    estuary repo.
if [ "${distro}" == "minifs" ];then
    ./submodules/${distro}-build-kernel.sh ${version} ${build_absolute_dir}
    if [ $? -ne 0 ]; then
        exit 1
    else
        exit 0
    fi
fi
if [ "${build_kernel_pkg_only}" == "true" ]; then
	# 1) build kernel
	docker_run_sh ${distro} ${sh_dir} ${envlist_file} \
		${distro}-build-kernel.sh ${version} ${build_dir}
else
	# 2) build installer
	docker_run_sh ${distro} ${sh_dir} ${envlist_file} \
		${distro}-build-installer.sh ${version} ${build_dir}

	# 3) build iso
	docker_run_sh ${distro} ${sh_dir} ${envlist_file} \
		${distro}-build-iso.sh 	${version} ${build_dir}

	# 4) build rootfs tar

	# 5) calculate md5sum
	docker_run_sh ${distro} ${sh_dir} ${envlist_file} \
		${distro}-calculate-md5sum.sh ${version} ${build_dir}
fi
