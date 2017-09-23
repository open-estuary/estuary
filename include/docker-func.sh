#!/bin/bash

docker_run_sh() {
	build_dir=$1
	sh_dir=$2
	distro=$3
	script=$4

	CUR_DIR=$(cd `dirname $0`; pwd)

	usage()
	{
		echo "Usage: deb_build.sh debian/ubuntu"
	}

	if [ $# -lt 4 ]; then
		usage
		exit 1
	fi

	name=$(echo $script| awk -F '.' '{print $1}')
	tag=3.1-full
	image=openestuary/${distro}:${tag}


	docker_status=`service docker status | grep "inactive" | awk '{print $2}'`
	if [ ! -z ${docker_status} ]; then
		echo "Docker service is inactive, begin to start docker service"
		sudo service docker start
		if [ $? -ne 0 ] ; then
			echo "Starting docker service failed!"
			exit 1
		else
			echo "Docker service start sucessfully!"
		fi
	fi

	ps ax | grep gpg-agent | grep -v grep | awk '{print $1}' |xargs kill -9 >/dev/null 2>&1

	echo "Start container to build."
	docker run -it --rm -v ~/:/root/ --name ${name} ${image} bash /root/${sh_dir}/${script} /root/$build_dir

}
