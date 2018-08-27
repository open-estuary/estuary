#!/bin/bash
set -ex

build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag
version=${version:-master}

top_dir=$(cd `dirname $0`; cd ..; pwd)
out_rpm=${build_dir}/out/kernel-pkg/${version}/fedora
distro_dir=${build_dir}/tmp/fedora
workspace=${distro_dir}/kernel
WGET_OPTS="-T 120 -c"
http_addr=${FEDORA_ISO_MIRROR:-"ftp://117.78.41.188/utils/distro-binary/fedora"}

# Update fedora repo
wget ${WGET_OPTS} -O /etc/yum.repos.d/estuary.repo ${http_addr}/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import ${ESTUARY_REPO}/ESTUARY-GPG-KEY
. ${top_dir}/include/mirror-func.sh
set_fedora_mirror
dnf clean dbcache

# Install estuary latest kernel
dnf install --disablerepo=* --enablerepo=Estuary,fedora kernel -y

#find build_num
if [ ! -z "$(dnf info installed kernel)" ]; then
        build_num=$(dnf info installed kernel|grep Release | awk -F ' ' '{print $3}'|awk -F '.' '{print $2}')
        build_num=$((build_num + 1))
else
        build_num=1
fi
build_num=${BUILD_NUM:-${build_num}}

# build arguments
kernel_dir=${workspace}/linux

# Checkout source code
rm -rf ${workspace} ${out_rpm}
mkdir -p ${workspace}/linux && cd ${workspace}
mkdir -p ${out_rpm}

cd $build_dir/../../kernel/
tar cf - . | (cd ${kernel_dir}; tar xf -)
cd ${kernel_dir}
kernel_version=$(make kernelversion)
kernel_abi=`echo ${kernel_version}|cut -d "." -f 1,2`
make mrproper
git archive --format=tar --prefix=linux-${kernel_abi}/ HEAD | xz --threads=0 -c > linux-${kernel_abi}.tar.xz

# Build the source kernel
cd ${workspace}
git clone https://github.com/open-estuary/fedora-kernel-packages.git --depth 1 -b ${version} kernel-src-debug
cd kernel-src-debug
cp -f ${kernel_dir}/linux-${kernel_abi}.tar.xz .
sed -i "s/\%define pkg_release.*/\%define pkg_release estuary.${build_num}.fc28/g" kernel.spec

dnf builddep kernel.spec -y
fedpkg local

# Copy back the resulted artifacts
cp -p *.src.rpm $out_rpm
echo "Source packages available at $out_rpm"

cd $out_rpm
cp ${workspace}/kernel-src-debug/aarch64/*.rpm .
