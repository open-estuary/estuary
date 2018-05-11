#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)
WGET_OPTS="-T 120 -c"

out=${build_dir}/out/release/${version}/OpenSuse
distro_dir=${build_dir}/tmp/opensuse
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/opensuse
dvdiso_url=${OPENSUSE_ISO_MIRROR:-"http://ftp.jaist.ac.jp/pub/Linux/openSUSE/ports/aarch64/distribution/leap/42.3/iso/"}
opensuse_url=${OPENSUSE_MIRROR:-"http://htsat.vicp.cc:804/opensuse"}
ISO=openSUSE-Leap-42.3-DVD-aarch64-Build0200-Media.iso

# download ISO
iso_dir=/root/iso
mkdir -p ${iso_dir} && cd ${iso_dir}
rm -f ${ISO}.sha256
wget ${dvdiso_url}/${ISO}.sha256 || exit 1
if [ ! -f $ISO ] || ! (sha256sum -c --status ${ISO}.sha256); then
    rm -f $ISO 2>/dev/null
    wget ${WGET_OPTS} ${dvdiso_url}/${ISO} || exit 1
    sha256sum -c --status ${ISO}.sha256 || exit 1
fi

# create the DVD image
rm -rf ${kernel_rpm_dir} && mkdir -p ${kernel_rpm_dir}
cd ${kernel_rpm_dir} ; wget ${WGET_OPTS} -r -nd -np -L -A *.aarch64.rpm ${opensuse_url}/
cd ${distro_dir}; rm -rf dvdiso
xorriso -osirrox on -indev ${iso_dir}/${ISO} -extract / dvdiso
cd dvdiso
rm -rf suse/aarch64/kernel-*
cp ${kernel_rpm_dir}/kernel-default* suse/aarch64/
rm -rf suse/setup/descr/packages.*
create_package_descr -d suse/ -o suse/setup/descr/  -l english -l german
find . -name "packages*" |xargs gzip -f

# Create the new ISO file.
mksusecd --create ${out}/${ISO} --no-hybrid .
