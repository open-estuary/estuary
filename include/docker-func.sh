#!/bin/bash
set -x

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
	name=$(echo ${name}${top_dir} | sed -e 's#/#-#g' -e 's#@##g' )
        eval image="$"${distro}"_image"
        localarch=`uname -m`
        if [ x"$localarch" = x"x86_64" ]; then
             qemu_cmd="-v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static"
        fi

        echo "Start container to build."
        if [  x"$(docker ps -a|grep ${name})" != x"" ]; then
                docker stop ${name}
                docker rm ${name}
        fi

	mkdir -p log/${distro}
	echo "Start container to build."
	docker_flag=$(docker network inspect bridge|grep ${name})
	if [ x"$docker_flag" != x"" ]; then
	    docker network disconnect -f bridge ${name}
	fi
	docker run  --privileged=true -i --rm --env-file ${envlist_file} -v ${home_dir}:/root/ \
		${qemu_cmd} --name ${name} ${image} \
		bash /root/${sh_dir}/${script} ${scipt_options} | tee > log/${distro}/${name}

}
