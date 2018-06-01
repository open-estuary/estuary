#!/bin/bash

set -e

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/Debian/
distro_dir=${build_dir}/tmp/debian
workspace=${distro_dir}/installer
out_installer=${workspace}/out/images

# set mirror
. ${top_dir}/include/mirror-func.sh
set_debian_mirror

mirror=${DEBIAN_MIRROR:-http://deb.debian.org/debian/}
estuary_repo=${DEBIAN_ESTUARY_REPO:-"http://repo.estuarydev.org/releases/5.1/debian"}
estuary_dist=${DEBIAN_ESTUARY_DIST:-estuary-5.1}
installer_src_version="20170615+deb9u2"

apt-get update -q=2

# Find kernel abi
kernel_abi=$(apt-cache depends linux-image-estuary-arm64 | grep -m 1 Depends \
| sed -e "s/.*linux-image-//g" -e "s/-arm64//g")

# Build the installer
mkdir -p ${workspace}
cd ${workspace}
rm -rf debian-installer-*
dget ${mirror}/pool/main/d/debian-installer/debian-installer_${installer_src_version}.dsc
cd debian-installer-*
apt-get build-dep -q --no-install-recommends -y .

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=810654, so lava can use grub to load grub.cfg from the local disk
sed -i 's/fshelp|//g' build/util/grub-cpmodules

## Config changes
cd build
sed -i "s/LINUX_KERNEL_ABI.*/LINUX_KERNEL_ABI = $kernel_abi/g" config/common
sed -i "s/PRESEED.*/PRESEED = default-preseed/g" config/common
sed -i "s/USE_UDEBS_FROM.*/USE_UDEBS_FROM = stretch/g" config/common

# Local pkg-list (to include all udebs)
cat <<EOF > pkg-lists/local
ext4-modules-\${kernel:Version}
fat-modules-\${kernel:Version}
btrfs-modules-\${kernel:Version}
md-modules-\${kernel:Version}
efi-modules-\${kernel:Version}
nic-modules-\${kernel:Version}
scsi-modules-\${kernel:Version}
jfs-modules-\${kernel:Version}
xfs-modules-\${kernel:Version}
ata-modules-\${kernel:Version}
sata-modules-\${kernel:Version}
usb-storage-modules-\${kernel:Version}
estuary-netboot-udeb
EOF

# Set up local repo
cat <<EOF > sources.list.udeb
deb [trusted=yes] ${estuary_repo} ${estuary_dist} main/debian-installer
deb ${mirror} stretch main/debian-installer
deb ${mirror} stretch-backports main/debian-installer
EOF

# Default preseed to add the overlay and kernel
cat <<EOF > default-preseed
# Continue install on "no kernel modules were found for this kernel"
d-i anna/no_kernel_modules boolean true

# Skip linux-image-arm64 installation
d-i base-installer/kernel/image string none

EOF

# 1) build netboot installer
fakeroot make build_netboot

# publish netboot 
mkdir -p ${out}
(cp -f default-preseed ${out}/default-preseed.cfg)
(cd dest/netboot/ && cp -f mini.iso netboot.tar.gz ${out})

## 2) build cdrom installer
cat <<EOF > default-preseed
# Continue install on "no kernel modules were found for this kernel"
d-i anna/no_kernel_modules boolean true

# The kernel image (meta) package to be installed.
d-i base-installer/kernel/image string linux-image-estuary-arm64

EOF

sed -i 's/estuary-netboot-udeb/estuary-cdrom-udeb/' pkg-lists/local
fakeroot make build_cdrom_grub

# publish cdrom 
mkdir -p ${out_installer}
(cp -rf dest/* ${out_installer}/)
