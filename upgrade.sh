#!/bin/bash
set -x

get_distro=`cat /etc/os-release |grep ^ID=|sed "s/ID=//"`

install_debian_kernel()
{
cat << eof > /etc/apt/sources.list.d/estuary.list
deb [trusted=yes] http://114.119.4.74/estuary-repo/kernel-5.30/debian/ estuary main
deb-src [trusted=yes] http://114.119.4.74/estuary-repo/kernel-5.30/debian/ estuary main
deb [trusted=yes] http://114.119.4.74/releases/5.0/debian/ estuary-5.0 main
deb-src [trusted=yes] http://114.119.4.74/releases/5.0/debian/ estuary-5.0 main
eof
apt-get update
apt-get install -y linux-image-estuary-arm64
reboot
}

install_centos_kernel()
{
cat << eof > /etc/yum.repos.d/estuary.repo
[Estuary-kernel]
name=Estuary-kernel
baseurl=http://114.119.4.74/estuary-repo/kernel-5.30/centos/ 
enabled=1
gpgcheck=0
[Estuary-app]
name=Estuary-app
baseurl=http://114.119.4.74/releases/5.0/centos/
enabled=1
gpgcheck=0
eof
yum clean all
yum install -y kernel
reboot
}

if [ x"$get_distro" = x"debian" ]; then
    install_debian_kernel
elif [ x"$get_distro" = x"\"centos\"" ]; then
    install_centos_kernel
fi
