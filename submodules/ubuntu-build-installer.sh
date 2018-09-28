#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

release_name=ubuntu-netboot
out=${build_dir}/out/release/${version}/Ubuntu/
kernel_deb_dir=${build_dir}/out/kernel-pkg/${version}/ubuntu
distro_dir=${build_dir}/tmp/ubuntu
workspace=${distro_dir}/installer
out_installer=${workspace}/out/images

# set mirror
mirror=${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}
estuary_repo=${UBUNTU_ESTUARY_REPO:-"${ESTUARY_REPO}/5.2/ubuntu"}
estuary_dist=${UBUNTU_ESTUARY_DIST:-estuary-5.2}

. ${top_dir}/include/mirror-func.sh
set_ubuntu_mirror
apt-get update -q=2

# Find kernel abi
kernel_version=$(apt-cache depends linux-image-estuary | grep -m 1 Depends \
| sed -e "s/.*linux-image-//g")

if [ -f "${build_dir}/build-ubuntu-kernel" ]; then
    build_kernel=true
fi
if [ x"$build_kernel" = x"true" ]; then
    kernel_version=$(dpkg --info ${kernel_deb_dir}/meta/linux-image-estuary* \
    | grep Depends | sed -e "s/.*linux-image-extra-//g" -e "s/,.*//g")
    cd ${kernel_deb_dir}/not_meta/
    dpkg-scanpackages -t udeb . > Packages
fi

echo "mirror is ${mirror}"
echo "estuary_repo is ${estuary_repo}"
echo "estuary_dist is ${estuary_dist}"
echo "kernel_version is ${kernel_version}"

# Build the installer
mkdir -p ${workspace}
cd ${workspace}
rm -rf ./*
dscname="debian-installer_20101020ubuntu543.dsc"
(dget -u ${mirror}/pool/main/d/debian-installer/${dscname})

cd debian-installer-*

## Config changes
cd build
sed -i "s/PRESEED.*/PRESEED = default-preseed/g" config/common
sed -i "s/KERNELVERSION =.*/KERNELVERSION = ${kernel_version}/g" config/arm64.cfg
sed -i '1,/-cp/{s/-cp/#-cp/}' Makefile
sed -i 's/gzip/pigz/g' Makefile

# Local pkg-list (to include all udebs)
cat <<EOF > pkg-lists/local
fat-modules-\${kernel:Version}
md-modules-\${kernel:Version}
scsi-modules-\${kernel:Version}
sata-modules-\${kernel:Version}
usb-modules-\${kernel:Version}
block-modules-\${kernel:Version}
crypto-modules-\${kernel:Version}
nfs-modules-\${kernel:Version}
nic-modules-\${kernel:Version}
nic-shared-modules-\${kernel:Version}
nic-usb-modules-\${kernel:Version}
storage-core-modules-\${kernel:Version}
virtio-modules-\${kernel:Version}
fs-core-modules-\${kernel:Version}
fs-secondary-modules-\${kernel:Version}
input-modules-\${kernel:Version}
ipmi-modules-\${kernel:Version}
message-modules-\${kernel:Version}
mouse-modules-\${kernel:Version}
multipath-modules-\${kernel:Version}
parport-modules-\${kernel:Version}
plip-modules-\${kernel:Version}
ppp-modules-\${kernel:Version}
vlan-modules-\${kernel:Version}
estuary-cdrom-udeb
EOF


# Set up local repo
cat <<EOF > sources.list.udeb
deb ${mirror} bionic main/debian-installer
deb ${mirror} bionic-updates main/debian-installer
EOF
if [ x"$build_kernel" = x"true" ]; then
    echo "deb [trusted=yes] copy:${kernel_deb_dir}/not_meta ./" >> sources.list.udeb
else
    echo "deb [trusted=yes] ${estuary_repo} ${estuary_dist} main/debian-installer" >> sources.list.udeb
fi


# Default preseed to add the overlay and kernel
cat <<EOF > default-preseed
d-i anna/no_kernel_modules boolean true
d-i base-installer/kernel/image string none
tasksel tasksel/first multiselect standard
d-i pkgsel/include string openssh-server vim
d-i preseed/late_command string apt-install linux-image-estuary
EOF

# 1) build netboot installer
if [ x"$build_kernel" != x"true" ]; then
    fakeroot make build_netboot
    mkdir -p ${out}
    cp -f default-preseed ${out}/default-preseed.cfg
    pushd dest/netboot/
    mv mini.iso ${release_name}.iso
    mv netboot.tar.gz ${release_name}.tar.gz
    cp -f ${release_name}* ${out}
    popd
fi

## 2) build cdrom installer
cat <<EOF > default-preseed
d-i anna/no_kernel_modules boolean true
d-i base-installer/kernel/image string linux-image-estuary
d-i pkgsel/include string openssh-server vim
d-i preseed/late_command string in-target apt-get update || true
EOF

fakeroot make build_cdrom_grub

# publish cdrom
mkdir -p ${out_installer}
(cp -rf dest/* ${out_installer}/)
