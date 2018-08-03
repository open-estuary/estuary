#!/bin/bash

set -ex

build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag
version=${version:-master}

top_dir=$(cd `dirname $0`; cd ..; pwd)
out_rpm=${build_dir}/out/kernel-pkg/${version}/centos
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/kernel

# Install estuary latest kernel
wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import ${ESTUARY_REPO}/ESTUARY-GPG-KEY
yum remove epel-release -y
yum clean dbcache
yum install --disablerepo=* --enablerepo=Estuary kernel -y

#find build_num
if [ ! -z "$(yum info installed kernel)" ]; then
        build_num=$(yum info installed kernel|grep estuary|awk -F ' ' '{print $3}'|awk -F '.' '{print $2}')
        build_num=$((build_num + 1))
else
        build_num=500
fi
build_num=${BUILD_NUM:-${build_num}}

# build arguments
kernel_dir=${workspace}/linux

# Checkout source code
rm -rf ${workspace}
mkdir -p ${workspace} && cd ${workspace}
mkdir -p ${out_rpm}

rsync -avq $build_dir/../kernel/ ${kernel_dir}

# Export the kernel packaging version
cd ${kernel_dir}
kernel_version=$(make kernelversion)
kernel_abi=`echo ${kernel_version}|cut -d "." -f 1,2`
make mrproper
git archive --format=tar --prefix=linux-${kernel_abi}/ HEAD | xz --threads=0 -c > linux-${kernel_abi}.tar.xz

# Build rpm source package
rpmversion=${kernel_version//-*/}
cd ${workspace} 
rm -rf centos-kernel-packages
git clone --depth 1 -b ${version} https://github.com/open-estuary/centos-kernel-packages.git
cp -rf centos-kernel-packages/* .

sed -i "s/\%define rpmversion.*/\%define rpmversion $rpmversion/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define pkgrelease.*/\%define pkgrelease estuary.${build_num}/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define signmodules 1/\%define signmodules 0/g" SPECS/kernel-aarch64.spec
sed -i "s/\%{gitrelease}/\%{pkgrelease}/g" SPECS/kernel-aarch64.spec
sed -i "s/mv linux-\%{rheltarball}/mv linux-\*/g" SPECS/kernel-aarch64.spec
sed -i "s/^BuildRequires: openssl$/BuildRequires: openssl-devel/g" SPECS/kernel-aarch64.spec
sed -i "s/0.0.0/0.0.1/g" SPECS/kernel-aarch64.spec

cp -f ${kernel_dir}/linux-${kernel_abi}.tar.xz SOURCES/linux-${rpmversion}-estuary.${build_num}.tar.xz
rpmbuild --nodeps --define "%_topdir `pwd`" -bs SPECS/kernel-aarch64.spec

# Copy back the resulted artifacts
mkdir -p $out_rpm
cp -p $workspace/SRPMS/*.src.rpm $out_rpm
echo "Source packages available at $out_rpm"

cd $out_rpm
rpmbuild --define "%_topdir ${workspace}" --rebuild *.src.rpm
cp $workspace/RPMS/aarch64/*.rpm .
