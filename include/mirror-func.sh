set_debian_mirror()
{
	if [ -n "${DEBIAN_MIRROR}" ]; then
		local default_mirror="http://deb.debian.org/debian"
		sed -i "s#${default_mirror}#${DEBIAN_MIRROR}#" \
			/etc/apt/sources.list
	fi
	debian_region="${estuary_repo} ${estuary_dist}"
	echo -e "deb ${debian_region} main\ndeb-src ${debian_region} main" > /etc/apt/sources.list.d/estuary.list
}

set_ubuntu_mirror()
{

        if [ -n "${UBUNTU_MIRROR}" ]; then
                local default_mirror="http://ports.ubuntu.com/ubuntu-ports"
                sed -i "s#${default_mirror}#${UBUNTU_MIRROR}#" \
                        /etc/apt/sources.list
        fi

}
set_fedora_mirror()
{
    if [ -n "${FEDORA_MIRROR}" ]; then
        local mirror=${FEDORA_MIRROR}
        sed -i "s#http://download.fedoraproject.org/pub/fedora/linux#${mirror}#g" /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
        sed -i '1,/metalink/{s/metalink/#metalink/}' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
        sed -i '1,/#baseurl/{s/#baseurl/baseurl/}' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
    fi
    if [ -n "${FEDORA_ESTUARY_REPO}" ]; then
        local mirror=${FEDORA_ESTUARY_REPO}
        docker_mirror="ftp://repoftp:repopushez7411@117.78.41.188/releases/.*/fedora"
        sed -i "s#${docker_mirror}#${mirror}#g" /etc/yum.repos.d/estuary.repo
    fi
}
set_centos_mirror()
{
    if [ -n "${CENTOS_MIRROR}" ]; then
        local mirror=${CENTOS_MIRROR}
        docker_mirror="http://mirror.centos.org/altarch/\$releasever/os/\$basearch/"
        sed -i "s#${docker_mirror}#${mirror}#g" /etc/yum.repos.d/CentOS-Base.repo
    fi
    if [ -n "${CENTOS_ESTUARY_REPO}" ]; then
        local mirror=${CENTOS_ESTUARY_REPO}
        docker_mirror="ftp://repoftp:repopushez7411@117.78.41.188/releases/.*/centos"
        sed -i "s#${docker_mirror}#${mirror}#g" /etc/yum.repos.d/estuary.repo
    fi
    sed -i 's/5.[0-9]/5.2/g' /etc/yum.repos.d/estuary.repo
    rpm --import ${ESTUARY_REPO}/ESTUARY-GPG-KEY
}
set_docker_loop()
{
    seq 0 7 | xargs -I {} mknod -m 660 /dev/loop{} b 7 {} || true
    chgrp disk /dev/loop[0-7]
}
