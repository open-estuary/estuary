#!/bin/bash
exit 0
set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

out=${build_dir}/out/release/${version}/Fedora/netboot
kernel_rpm_dir=${build_dir}/out/kernel-pkg/${version}/fedora
distro_dir=${build_dir}/tmp/fedora
workspace=${distro_dir}/installer
out_installer=${workspace}/out
source_url=${FEDORA_ESTUARY_REPO:-"ftp://repoftp:repopushez7411@117.78.41.188/releases/5.1/fedora"}
base_url=${FEDORA_MIRROR:-"http://dl.fedoraproject.org/pub/fedora/linux"}/releases/28/Everything/aarch64/os/

rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p fedora-installer

if [ -f "${build_dir}/build-fedora-kernel" ]; then
    build_kernel=true
fi

if [ x"$build_kernel" = x"true" ]; then
    source_url="file://${kernel_rpm_dir}"
    createrepo -q ${kernel_rpm_dir}
fi

# Install build tools and fix dependence problem
sed -i 's#"setfiles",#"setfiles","-e","/usr/lib/systemd",#g' /usr/lib/python3.6/site-packages/pylorax/imgutils.py
sed -i '1,/installpkg kernel/{s/kernel.*/kernel-4.16.0 kernel-modules-extra-4.16.0/}' \
       /usr/share/lorax/templates.d/99-generic/runtime-install.tmpl
. ${top_dir}/include/mirror-func.sh
set_docker_loop

# Call lorax to create the netinstall image
cd fedora-installer
rm -rf netinstall
lorax '--product=Fedora' --version=28 --release=28 \
  --source=${base_url} \
  --source=${source_url} \
  --isfinal --nomacboot --noupgrade --buildarch=aarch64 '--volid=Fedora-S-dvd-aarch64-28' netinstall/ 2>/dev/null


# Modify initrd to include a default kickstart (that includes the external repository)
cd netinstall/images/pxeboot/
mkdir initrd; cd initrd
sh -c 'xzcat ../initrd.img | cpio -d -i -m'
cfg_path="${top_dir}/configs/auto-install/fedora/"
cp -f $cfg_path/auto-iso/ks-iso.cfg .
cp -f $cfg_path/auto-pxe/ks.cfg .

sh -c 'find . | cpio --quiet -o -H newc --owner 0:0 | xz --threads=0 --check=crc32 -c > ../initrd.img'
cd ..; rm -rf initrd

# Rebuild boot.iso
if [ x"$build_kernel" != x"true" ]; then
    netinstall_dir=${workspace}/fedora-installer/netinstall
    cp -f $cfg_path/auto-pxe/grub.cfg ${netinstall_dir}/EFI/BOOT/grub.cfg
    rm -rf ${netinstall_dir}/images/boot.iso
    genisoimage -quiet -o ${netinstall_dir}/images/boot.iso -eltorito-alt-boot \
      -e images/efiboot.img -no-emul-boot -R -J -V 'Fedora-S-dvd-aarch64-28' -T \
      -allow-limited-size ${netinstall_dir}
fi

# Final preparation for publishing
mkdir -p ${out_installer} && mkdir -p ${out}
cd ${workspace}/fedora-installer
cp -rf lorax.log netinstall/.discinfo netinstall/.treeinfo netinstall/EFI netinstall/images ${out_installer}
cp -rf  ${out_installer}/* ${out}

# Publish
out=${build_dir}/out/release/${version}/Fedora
if [ x"$build_kernel" != x"true" ]; then
    cd ${out}
    mv netboot/images/boot.iso .
    tar -cf - netboot/ | pigz > netboot.tar.gz
    rm -rf netboot/
fi
