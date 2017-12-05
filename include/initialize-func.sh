#!/bin/bash

check_build_permission()
{
    if [ "$dname" != "/root" ] && [ "$dname" != "/home" ]; then
        echo -e "\033[31mERROR: please move estuary to user's HOME directory!!!\033[0m"
        exit 1
    fi
}

check_docker_running_permission()
{
	if [ "$USER" != "root" ] && [ -z "$(groups|grep docker)" ]; then
		sudo groupadd docker || true
		sudo usermod -aG docker $USER
		sudo systemctl start docker
		echo -e "\033[31m warning: user just add into docker group, please re-login!!!\033[0m"
		exit 1
	fi

}

###################################################################################
# int install_jq
###################################################################################
install_jq()
{
    tools_dir=${top_dir}/tools
    mkdir -p ${tools_dir}
    cd ${tools_dir}
    jq_version=jq-1.5
    if [ ! -d jq ]; then
        git clone --depth 1 -b $jq_version https://github.com/stedolan/jq.git 
    fi

    cd jq && autoreconf -i && ./configure --disable-maintainer-mode --prefix=/usr && make && sudo make install
}

install_dev_tools_debian()
{
	sudo apt-get install -y git jq docker.io bc libssl-dev unzip make build-essential
	check_docker_running_permission
}

install_dev_tools_ubuntu()
{
	sudo apt-get install -y git jq docker.io bc libssl-dev unzip make build-essential
	check_docker_running_permission
}

###################################################################################
# int install_dev_tools_centos
###################################################################################
install_dev_tools_centos()
{

   sudo yum groupinstall "Development Tools" -y 
   sudo yum install autoconf automake libtool python git docker bc openssl-devel unzip -y

    install_jq
    check_docker_running_permission

    return 0
}

###################################################################################
# install_dev_tools
###################################################################################
install_dev_tools()
{
    local host_distro=$(cat /etc/os-release |grep ^ID=|awk -F '=' '{print $2}')

    # remove "centos"'s ""
    if [ -n "$(echo ${host_distro}|grep \")" ]; then
	host_distro=$(echo ${host_distro}|awk -F \" '{print $2}')
    fi	

    if ! declare -F install_dev_tools_${host_distro} >/dev/null; then
        echo "Unspported distro!" >&2; return 1
    fi

    if [ -z "$(which jq)" ] || [ -z "$(which git)" ] \
	    || [ -z "$(which docker)" ]; then
	install_dev_tools_${host_distro}
    fi

}

###################################################################################
# update_acpica_tools
###################################################################################
update_acpica_tools()
{
    if [ ! -d acpica ]; then
        git clone https://github.com/acpica/acpica.git
    fi

    corenum=`cat /proc/cpuinfo | grep "processor" | wc -l`
    (cd acpica/generate/unix && make -j${corenum} && sudo make install)
}

check_arch()
{
	if [ "$(uname -m)" != "aarch64" ]; then
		echo -e "\033[31mError: build.sh script only run on arm64 server!!\033[0m" 
		exit 1
	fi
}

check_running_not_in_container()
{
	if [ -f /.dockerenv ]; then
		echo -e "\033[31mError: build.sh script can't run inside container!!\033[0m"
		exit 1
	fi
}
