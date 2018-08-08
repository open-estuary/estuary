#!/bin/bash

set -ex

build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag
version=${version:-master}

out_rpm=${build_dir}/out/kernel-pkg/${version}/opensuse
workspace=${build_dir}/tmp/opensuse/kernel

# Checkout source code
rm -rf ${workspace}
mkdir -p ${workspace}/linux && cd ${workspace}
mkdir -p ${out_rpm}

kernel_dir=${workspace}/linux
cd $build_dir/../../kernel/
tar cf - . | (cd ${kernel_dir}; tar xf -)

# Export the kernel packaging version
cd ${kernel_dir}
kernel_version=$(make kernelversion)
kernel_abi=`echo ${kernel_version}|cut -d "." -f 1,2`
kernel_dir=${workspace}/linux-${kernel_abi}
make mrproper
mv ${workspace}/linux ${kernel_dir}

# Build the source kernel
cd ${workspace}
tar -cf linux-${kernel_abi}.tar linux-${kernel_abi}/
xz --threads=0 -z linux-${kernel_abi}.tar

# Build kernel rpm package
cd ${workspace} 
git clone https://github.com/open-estuary/opensuse-kernel-packages.git --depth 1 -b ${version} kernel-source
cd kernel-source/
git config --global user.name "linwenkai"
git config --global user.email 941116795@qq.com
./scripts/install-git-hooks

cp ${workspace}/linux-${kernel_abi}.tar.xz .
cp -f oscrc /root/.oscrc
sed -i "s/SRCVERSION=.*/SRCVERSION=${kernel_abi}/g" rpm/config.sh
./scripts/tar-up.sh -nf -a arm64

./scripts/osc_wrapper kernel-source/kernel-default.spec 

# Copy back the resulted artifacts
tmp_rpm="/var/tmp/build-root/ARM-aarch64/home/abuild/rpmbuild/"
mkdir -p $out_rpm
cp -p ${tmp_rpm}/SRPMS/*.nosrc.rpm $out_rpm
echo "Source packages available at $out_rpm"

cp ${tmp_rpm}/RPMS/aarch64/*.rpm $out_rpm
