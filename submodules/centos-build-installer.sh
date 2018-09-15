#!/bin/bash
exit 0

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

release_dir=${build_dir}/out/release/${version}/CentOS
out=${release_dir}/netboot
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/centos
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/installer
out_installer=${workspace}/out
source_url=${CENTOS_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.2/centos"}
base_url=${CENTOS_MIRROR:-"http://mirror.centos.org/altarch/7/os/aarch64/"}

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p centos-installer

. ${top_dir}/include/mirror-func.sh
set_docker_loop

# Call lorax to create the netinstall image
cd centos-installer
rm -rf netinstall
if [ -f "${build_dir}/build-centos-kernel" ]; then
    build_kernel=true
fi
if [ x"$build_kernel" = x"true" ]; then
    source_url="file://${kernel_rpm_dir}"
    createrepo -q ${kernel_rpm_dir}
fi
lorax '--product=CentOS Linux' --version=7 --release=7 \
  --source=${base_url} \
  --source=${source_url}  \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=CentOS 7 aarch64' netinstall/ 2>/dev/null

# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
mkdir initrd; cd initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cfg_path="${top_dir}/configs/auto-install/centos/"
cp -f $cfg_path/auto-iso/ks-iso.cfg .
cp -f $cfg_path/auto-pxe/ks.cfg .

sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --threads=0 --check=crc32 -c > ../initrd.img'
cd ..; rm -rf initrd

# Rebuild boot.iso
if [ x"$build_kernel" != x"true" ]; then
netinstall_dir=${workspace}/centos-installer/netinstall
cp -f $cfg_path/auto-pxe/grub.cfg ${netinstall_dir}/EFI/BOOT/grub.cfg
rm -rf ${netinstall_dir}/images/boot.iso
mkisofs -quiet -o ${netinstall_dir}/images/boot.iso -eltorito-alt-boot \
  -e images/efiboot.img -no-emul-boot -R -J -V 'CentOS 7 aarch64' -T \
  -graft-points \
  images/pxeboot=${netinstall_dir}/images/pxeboot \
  LiveOS=${netinstall_dir}/LiveOS \
  EFI/BOOT=${netinstall_dir}/EFI/BOOT \
  images/efiboot.img=${netinstall_dir}/images/efiboot.img
fi

# Final preparation for publishing
mkdir -p ${out_installer} && mkdir -p ${out}
cd ${workspace}/centos-installer
cp -rf lorax.log netinstall/.discinfo netinstall/.treeinfo netinstall/EFI netinstall/images netinstall/LiveOS ${out_installer}
cp -rf  ${out_installer}/* ${out}
if [ x"$build_kernel" != x"true" ]; then
    cd ${release_dir}
    mv netboot/images/boot.iso .
    tar -cf - netboot/ | pigz > netboot.tar.gz
fi
rm -rf ${out}
