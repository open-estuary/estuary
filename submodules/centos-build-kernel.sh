#!/bin/bash

set -ex

build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag
version=${version:-master}

top_dir=$(cd `dirname $0`; cd ..; pwd)
out_rpm=${build_dir}/out/kernel-pkg/${version}/centos
distro_dir=${build_dir}/tmp/centos
workspace=${distro_dir}/kernel

# Install build tools,do not change first line!
yum install -y yum-plugin-ovl
yum install -y epel-release
yum install -y python34 dpkg-dev quilt wget git rpm-build yum-utils make openssl-devel
yum install -y net-tools bc xmlto asciidoc openssl-devel audit-libs-devel 'perl(ExtUtils::Embed)'

wget http://repo.linaro.org/rpm/linaro-overlay/centos-7/linaro-overlay.repo -O /etc/yum.repos.d/linaro-overlay.repo
yum groupinstall -y "Development tools"

yum install -y redhat-rpm-config asciidoc hmaccalc pesign xmlto
yum install -y binutils-devel elfutils-devel elfutils-libelf-devel
yum install -y ncurses-devel newt-devel numactl-devel pciutils-devel python-devel zlib-devel

# Install estuary latest kernel
wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp.repo
chmod +r /etc/yum.repos.d/estuary.repo
rpm --import http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY
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
orig_dir=${workspace}/orig
repo_dir=${workspace}/distro-repo
kernel_dir=${workspace}/linux

# Checkout source code
rm -rf $orig_dir $repo_dir ~/rpmbuild
mkdir -p ${workspace} && cd ${workspace}
mkdir -p ${out_rpm} && mkdir -p debian-pkg

rsync -avq $build_dir/../distro-repo/ distro-repo
rsync -avq $build_dir/../kernel/ ${kernel_dir}

# Export the kernel packaging version
cd ${kernel_dir}
kernel_version=$(make kernelversion)
export KDEB_PKGVERSION="${kernel_version}.estuary.${build_num}-1"
git tag -f v${kernel_version}

# Build the source kernel
cd ../debian-pkg
cp -r ../distro-repo/deb/kernel/debian-package/debian .

# Use build number as ABI
sed -i "s/^abiname:.*/abiname: ${build_num}/g" debian/config/defines

cat << EOF > debian/changelog
linux ($KDEB_PKGVERSION) unstable; urgency=medium

  * Auto build:
    - URL: ${GIT_URL}
    - Branch: ${GIT_BRANCH}
    - Commit: ${GIT_COMMIT}

 -- OpenEstuary <sjtuhjh@hotmail.com>  $(date -R)

EOF

debian/bin/genorig.py ../linux
debian/rules orig

# Build rpm source package
rpmversion=${kernel_version//-*/}
cd ${workspace} 
cp -rf ${workspace}/distro-repo/rpm/kernel/centos-package/* .

sed -i "s/\%define rpmversion.*/\%define rpmversion $rpmversion/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define pkgrelease.*/\%define pkgrelease estuary.${build_num}/g" SPECS/kernel-aarch64.spec
sed -i "s/\%define signmodules 1/\%define signmodules 0/g" SPECS/kernel-aarch64.spec
sed -i "s/\%{gitrelease}/\%{pkgrelease}/g" SPECS/kernel-aarch64.spec
sed -i "s/mv linux-\%{rheltarball}/mv linux-\*/g" SPECS/kernel-aarch64.spec
sed -i "s/^BuildRequires: openssl$/BuildRequires: openssl-devel/g" SPECS/kernel-aarch64.spec
sed -i "s/0.0.0/0.0.1/g" SPECS/kernel-aarch64.spec

cp ${workspace}/orig/*.orig.tar.xz SOURCES/linux-${rpmversion}-estuary.${build_num}.tar.xz
rpmbuild --nodeps --define "%_topdir `pwd`" -bs SPECS/kernel-aarch64.spec

# Copy back the resulted artifacts
mkdir -p $out_rpm
cp -p $workspace/SRPMS/*.src.rpm $out_rpm
echo "Source packages available at $out_rpm"

cd $out_rpm
rpmbuild --rebuild *.src.rpm
cp ~/rpmbuild/RPMS/aarch64/*.rpm .
