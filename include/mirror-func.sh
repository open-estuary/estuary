set_debian_mirror()
{
	rm -rf /etc/apt/sources.list.d/*.list
	wget -O - ${ESTUARY_REPO}/ESTUARY-GPG-KEY | \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg add -
	wget -O /etc/apt/sources.list.d/estuary.list https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp_debian.list
	if [ -n "${DEBIAN_MIRROR}" ]; then
		local default_mirror="http://deb.debian.org/debian"
		sed -i "s#${default_mirror}#${DEBIAN_MIRROR}#" \
			/etc/apt/sources.list
	fi

        if [ -n "${DEBIAN_SECURITY_MIRROR}" ]; then
                local default_security_mirror="http://security.debian.org/"
                sed -i "s#${default_security_mirror}#${DEBIAN_SECURITY_MIRROR}#" \
                        /etc/apt/sources.list
        fi
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
    sed -i 's/5.[0-9]/5.1/g' /etc/yum.repos.d/estuary.repo
    rpm --import ${ESTUARY_REPO}/ESTUARY-GPG-KEY
}
