#!/bin/bash -ex

docker_run_sh() {
	distro=$1
	sh_dir=$2
	home_dir=$3
	envlist_file=$4
	script=$5

	usage()
	{
		echo "Usage: docker_run_sh script_running_disro script_dir home_dir envlist script_name script_options"
	}

	if [ $# -lt 5 ]; then
		usage
		exit 1
	fi

	shift 5
	scipt_options=$@
	name=$(echo $script| awk -F '.' '{print $1}')
	name=$(echo ${name}${top_dir} | sed -e 's#/#-#g')
        debian_image="linaro/ci-arm64-debian:stretch"
        centos_image="estuary/centos:5.1-full"
        opensuse_image="estuary/opensuse:5.1-full"
        fedora_image="estuary/fedora:28"
        ubuntu_image="estuary/ubuntu:5.1-full"
        eval image="$"${distro}"_image"
        localarch=`uname -m`
        if [ x"$localarch" = x"x86_64" ]; then
             qemu_cmd="-v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static"
        fi

	if [ -z "$(docker info)" ]; then
		echo -e "\033[31mError: docker is not running!\033[0m" ; exit 1   
	fi

        echo "Start container to build."
        if [  x"$(docker ps -a|grep ${name})" != x"" ]; then
                docker stop ${name}
                docker rm ${name}
        fi

	echo "Start container to build."
	docker run  --privileged=true -i --env-file ${envlist_file} -v ${home_dir}:/root/ \
		${qemu_cmd} --name ${name} ${image} \
		bash /root/${sh_dir}/${script} ${scipt_options}
        echo "Collect log and clean container"
        mkdir -p log/${distro}
        docker logs ${name} > log/${distro}/${name}
        docker stop ${name}
        docker rm ${name}

}
