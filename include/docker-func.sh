#!/bin/bash -ex

docker_run_sh() {
	distro=$1
	sh_dir=$2
	envlist_file=$3
	script=$4

	usage()
	{
		echo "Usage: docker_run_sh script_running_disro script_dir envlist script_name script_options"
	}

	if [ $# -lt 4 ]; then
		usage
		exit 1
	fi

	shift 4
	scipt_options=$@
	name=$(echo $script| awk -F '.' '{print $1}')
	tag=3.1-full
	image=openestuary/${distro}:${tag}

	if [ -z "$(docker info)" ]; then
		echo -e "\033[31mError: docker is not running!\033[0m" ; exit 1   
	fi

        echo "Start container to build."
        if [  x"$(docker ps -a|grep ${name})" != x"" ]; then
                docker stop ${name}
                docker rm ${name}
        fi

	echo "Start container to build."
	docker run  --privileged=true -i --env-file ${envlist_file} -v ~/:/root/ \
		--name ${name} ${image} \
		bash /root/${sh_dir}/${script} ${scipt_options}
        echo "Collect log and clean container"
        mkdir -p log/${distro}
        docker logs ${name} > log/${distro}/${name}
        docker stop ${name}
        docker rm ${name}

}
