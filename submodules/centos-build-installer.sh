#!/bin/bash

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/CentOS/netboot
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/installer
out_installer=${workspace}/out
source_url=${CENTOS_ESTUARY_REPO:-"http://repo.estuarydev.org/releases/5.1/centos"}
base_url=${CENTOS_MIRROR:-"http://mirror.centos.org/altarch/7/os/aarch64/"}

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p centos-installer

wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import ${ESTUARY_REPO}/ESTUARY-GPG-KEY
yum remove -y epel-release
yum makecache fast
seq 0 7 | xargs -I {} mknod -m 660 /dev/loop{} b 7 {} || true
chgrp disk /dev/loop[0-7]

# Call lorax to create the netinstall image
cd centos-installer
rm -rf netinstall
lorax '--product=CentOS Linux' --version=7 --release=7 \
  --source=${base_url} \
  --source=${source_url}  \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=CentOS 7 aarch64' netinstall/

# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
mkdir initrd; cd initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cfg_path="${top_dir}/configs/auto-install/centos/"
cp -f $cfg_path/auto-iso/ks-iso.cfg .
cp -f $cfg_path/auto-pxe/ks.cfg .

sh -c 'find . | cpio -o -H newc | xz --check=crc32 --lzma2=dict=512KiB > ../initrd.img'
cd ..; rm -rf initrd

# Rebuild boot.iso
netinstall_dir=${workspace}/centos-installer/netinstall
cp -f $cfg_path/auto-pxe/grub.cfg ${netinstall_dir}/EFI/BOOT/grub.cfg
rm -rf ${netinstall_dir}/images/boot.iso
mkisofs -o ${netinstall_dir}/images/boot.iso -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T \
  -graft-points \
  images/pxeboot=${netinstall_dir}/images/pxeboot \
  LiveOS=${netinstall_dir}/LiveOS \
  EFI/BOOT=${netinstall_dir}/EFI/BOOT \
  images/efiboot.img=${netinstall_dir}/images/efiboot.img

# Final preparation for publishing
mkdir -p ${out_installer} && mkdir -p ${out}
cd ${workspace}/centos-installer
cp -rf lorax.log netinstall/.discinfo netinstall/.treeinfo netinstall/EFI netinstall/images netinstall/LiveOS ${out_installer}
cp -rf  ${out_installer}/* ${out}
