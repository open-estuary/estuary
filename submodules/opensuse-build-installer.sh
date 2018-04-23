#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

release_dir=${build_dir}/out/release/${version}/OpenSuse/netboot
distro_dir=${build_dir}/tmp/opensuse
workspace=${distro_dir}/installer
netiso_url=${OPENSUSE_ISO_MIRROR:-"http://ftp.jaist.ac.jp/pub/Linux/openSUSE/ports/aarch64/distribution/leap/42.3/iso/"}
ISO=openSUSE-Leap-42.3-NET-aarch64-Build0200-Media.iso

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p opensuse-installer

zypper install -y wget xorriso mkisofs

# download ISO
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
rm -f ${ISO}.sha256
wget ${netiso_url}/${ISO}.sha256 || exit 1
if [ ! -f $ISO ] || ! (sha256sum -c --status ${ISO}.sha256); then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${netiso_url}/${ISO} || exit 1
    sha256sum -c --status ${ISO}.sha256 || exit 1
fi

# create the netinstall image
cd ${workspace}/opensuse-installer; rm -rf netinstall
xorriso -osirrox on -indev ${iso_dir}/${ISO} -extract / netinstall
cd netinstall
sed -i 's/silent.*/& autoyast=http:\/\/htsat.vicp.cc:804\/opensuse\/autoinst.xml/' EFI/BOOT/grub.cfg
mkisofs  -R -o boot.iso -b boot/aarch64/efi -c boot.catalog -no-emul-boot .

# Final preparation for publishing
mkdir -p ${release_dir}
cp -rf ${workspace}/opensuse-installer/netinstall/* ${release_dir}
