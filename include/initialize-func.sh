#!/bin/bash

###################################################################################
# int install_jq
###################################################################################
install_jq()
{
    if [ ! -d jq ]; then
        git clone https://github.com/stedolan/jq.git
    fi

    (cd jq && autoreconf -i && ./configure --disable-maintainer-mode && make && sudo make install)
}

###################################################################################
# int install_dev_tools_ubuntu <arch>
###################################################################################
install_dev_tools_ubuntu()
{
    local arch=$1
    if [ x"$arch" = x"x86_64" ]; then
        local dev_tools="wget automake1.11 make bc libncurses5-dev libtool libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex uuid-dev build-essential iasl jq genisoimage libssl-dev gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev"
    else
        local dev_tools="wget automake1.11 make bc libncurses5-dev libtool libc6 libncurses5 libstdc++6 bison flex uuid-dev build-essential iasl acpica-tools jq genisoimage libssl-dev gcc-arm-linux-gnueabihf gcc zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev"
    fi

    if ! (automake --version 2>/dev/null | grep 'automake (GNU automake) 1.11' >/dev/null); then
        sudo apt-get remove -y --purge automake*
    fi

    if ! (dpkg-query -l $dev_tools >/dev/null 2>&1); then
        sudo apt-get update
        if ! (sudo apt-get install -y --force-yes $dev_tools); then
            return 1
        fi
    fi

    return 0
}

###################################################################################
# int install_dev_tools_centos_linux <arch>
###################################################################################
install_dev_tools_centos_linux()
{
    local arch=$1
    local dev_tools="automake bc ncurses-devel libtool ncurses bison flex libuuid-devel uuid-devel iasl genisoimage openssl-devel bzip2 lshw dosfstools glib2-devel pixman-devel libfdt-devel"

    if ! yum install -y $dev_tools; then
        if ! (yum makecache && yum install -y $dev_tools); then
            return 1
        fi
    fi

    if !(which jq >/dev/null 2>&1 || install_jq); then
        return 1
    fi

    return 0
}

###################################################################################
# install_dev_tools <arch>
###################################################################################
install_dev_tools()
{
    local arch=$1
    local host_distro=`cat /etc/os-release | grep -Po "(?<=^NAME=\")([^\"]*)(?=\")" | tr "[:upper:]" "[:lower:]" | tr ' ' '_'`
    if ! declare -F install_dev_tools_${host_distro} >/dev/null; then
        echo "Unspported distro!" >&2; return 1
    fi

    install_dev_tools_${host_distro} $arch
}

###################################################################################
# update_acpica_tools
###################################################################################
update_acpica_tools()
{
    if [ ! -d acpica ]; then
        git clone https://github.com/acpica/acpica.git
    fi

    (cd acpica/generate/unix && make -j${corenum} && sudo make install)
}

