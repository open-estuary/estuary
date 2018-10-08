#!/bin/bash

set -x

top_dir=$(cd `dirname $0`; cd ..; pwd)
version=$1 # branch or tag
build_dir=$(cd /root/$2 && pwd)

release_name=ubuntu-everything-${version}
out=${build_dir}/out/release/${version}/Ubuntu
kernel_deb_dir=${build_dir}/out/kernel-pkg/${version}/ubuntu
distro_dir=${build_dir}/tmp/ubuntu
cdrom_installer_dir=${distro_dir}/installer/out/images
workspace=${distro_dir}/ubuntu-cd

export UBUNTU_CD=${workspace}
WGET_OPTS="-T 120 -c -q"

cdimage=${workspace}/cd-image
mnt=${workspace}/mnt
grubfiles=${workspace}/grubfiles
download=${workspace}/download

# set mirror
estuary_repo=${UBUNTU_ESTUARY_REPO:-"${ESTUARY_REPO}/5.2/ubuntu"}
estuary_dist=${UBUNTU_ESTUARY_DIST:-estuary-5.2}

. ${top_dir}/include/mirror-func.sh
. ${top_dir}/include/checksum-func.sh
set_ubuntu_mirror
set_docker_loop

apt-get update -q=2

mkdir -p ${workspace}
mkdir -p ${cdimage}
rm -rf ${cdimage}/* || true
mkdir -p ${download}
rm -rf ${download}/* || true

# download debs and filesystem
if [ -f "${build_dir}/build-ubuntu-kernel" ]; then
    build_kernel=true
fi

if [ x"$build_kernel" != x"true" ]; then
    cd ${download}
    if [ ! -z "$(apt-cache show linux-image-estuary)" ]; then
        kernel_version=$(apt-cache policy linux-image-estuary|grep Candidate:|awk -F ' ' '{print $2}'|awk -F '.' '{print $1"."$2"."$3}')
        build_num=$(apt-cache policy linux-image-estuary|grep Candidate:|awk -F '.' '{print $4}')
    else
        echo "ERROR:No linux-image-estuary found !"
    fi
    estuary_repo=${UBUNTU_ESTUARY_REPO:-"${ESTUARY_REPO}/5.2/ubuntu"}
    wget ${WGET_OPTS} -r -nd -np -L -A linux-*${kernel_version}*${build_num}*.deb ${estuary_repo}/pool/main/
else
    cp -f ${kernel_deb_dir}/meta/linux-*.deb ${download}/
    cp -f ${kernel_deb_dir}/not_meta/linux-*.deb ${download}/
fi

cd ${workspace}
# download iso and decompress
ISO=ubuntu-18.04-server-arm64.iso
http_addr=${UBUNTU_ISO_MIRROR:-"ftp://117.78.41.188/utils/distro-binary/ubuntu/releases/18.04/release"}
mkdir -p /root/iso && cd /root/iso
rm -f ${ISO}.sum
wget ${http_addr}/${ISO}.sum || exit 1
if [ ! -f $ISO ] || ! check_sum . ${ISO}.sum; then
    rm -f $ISO 2>/dev/null
    wget -T 120 -c ${http_addr}/${ISO} || exit 1
    check_sum . ${ISO}.sum || exit 1
fi

xorriso -osirrox on -indev ${ISO} -extract / ${cdimage}

# copy debs to extras
mkdir -p ${cdimage}/pool/extras
cp ${download}/*.deb ${cdimage}/pool/extras

# copy vmlinuz and initrd.gz from installer
cp ${cdrom_installer_dir}/cdrom/vmlinuz ${cdimage}/install/vmlinuz
cp ${cdrom_installer_dir}/cdrom/initrd.gz ${cdimage}/install/initrd.gz

# copy grub files from installer
mkdir -p ${grubfiles}
cp ${cdrom_installer_dir}/cdrom/debian-cd_info.tar.gz ${grubfiles}
cd ${grubfiles}
tar -xzf debian-cd_info.tar.gz

cp -r ${grubfiles}/grub/arm64-efi ${cdimage}/boot/grub/
cp -r ${grubfiles}/grub/efi.img ${cdimage}/boot/grub/
cp -r ${grubfiles}/grub/font.pf2 ${cdimage}/boot/grub/

# make filesystem to install
rm -rf ${workspace}/SquashFS
mkdir -p ${workspace}/SquashFS
cd ${workspace}/SquashFS/
unsquashfs ${cdimage}/install/filesystem.squashfs
cd squashfs-root/
cp /home/ubuntu-archive-keyring.gpg usr/share/keyrings/ubuntu-archive-keyring.gpg
cp /home/ubuntu-archive-keyring.gpg etc/apt/trusted.gpg
rm -rf ${cdimage}/install/filesystem.s*
du -sx --block-size=1 ./ | cut -f1 > ${cdimage}/install/filesystem.size
mksquashfs ./ ${cdimage}/install/filesystem.squashfs
cd ${workspace}

# make cd
distro_version="bionic"
mkdir -p ${cdimage}/dists/${distro_version}/extras/binary-arm64

mkdir -p ./ubuntu-cd-make/apt-ftparchive
mkdir -p ./ubuntu-cd-make/indices
mkdir -p ./ubuntu-cd-make/script_for_ubuntu_cd

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-deb.conf << EOF 
Dir {
  ArchiveDir "${workspace}/cd-image";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/${distro_version}/main/binary-arm64/Packages";
  BinOverride "${workspace}/ubuntu-cd-make/indices/override.${distro_version}.main";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-extras.conf << EOF 
Dir {
  ArchiveDir "${workspace}/cd-image";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/extras" {
  Packages "dists/${distro_version}/extras/binary-arm64/Packages";
};

Default {
  Packages {
    Extensions ".deb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/apt-ftparchive-udeb.conf << EOF
Dir {
  ArchiveDir "${workspace}/cd-image/";
};

TreeDefault {
  Directory "pool/";
};

BinDirectory "pool/main" {
  Packages "dists/${distro_version}/main/debian-installer/binary-arm64/Packages";
  BinOverride "${workspace}/ubuntu-cd-make/indices/override.${distro_version}.main.debian-installer";
};

Default {
  Packages {
    Extensions ".udeb";
    Compress ". gzip";
  };
};

Contents {
  Compress "gzip";
};
EOF

cat > ./ubuntu-cd-make/apt-ftparchive/release.conf << EOF
APT::FTPArchive::Release::Origin "Ubuntu";
APT::FTPArchive::Release::Label "Ubuntu";
APT::FTPArchive::Release::Suite "${distro_version}";
APT::FTPArchive::Release::Version "18.04";
APT::FTPArchive::Release::Codename "${distro_version}";
APT::FTPArchive::Release::Architectures "arm64";
APT::FTPArchive::Release::Components "main extras";
APT::FTPArchive::Release::Description "Ubuntu 16.04 LTS";
EOF

cat > ./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh << EOF
#!/bin/bash

cd ${workspace}/ubuntu-cd-make/indices/
DIST=bionic
for SUFFIX in extra.main main main.debian-installer restricted restricted.debian-installer; do
  wget ${WGET_OPTS} http://archive.ubuntu.com/ubuntu/indices/override.\$DIST.\$SUFFIX
done
EOF

chmod a+x ./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh

cat > ./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh << EOF
set -ex

BUILD=${workspace}/cd-image
APTCONF=${workspace}/ubuntu-cd-make/apt-ftparchive/release.conf
DISTNAME=bionic

pushd \$BUILD
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-deb.conf
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-udeb.conf
apt-ftparchive -c \$APTCONF generate ${workspace}/ubuntu-cd-make/apt-ftparchive/apt-ftparchive-extras.conf
apt-ftparchive -c \$APTCONF release \$BUILD/dists/\$DISTNAME > \$BUILD/dists/\$DISTNAME/Release

rm -rf \$BUILD/dists/\$DISTNAME/Release.gpg /root/.gnupg
gpg1 --import /home/ESTUARY-GPG-SECURE-KEY
expect <<-END
        set timeout -1
        spawn gpg1 --default-key "3108CDA4" --output \$BUILD/dists/\$DISTNAME/Release.gpg -ba \$BUILD/dists/\$DISTNAME/Release
        expect {
                "Enter passphrase:" {send "OPENESTUARY@123\r"}
                timeout {send_user "Enter pass phrase timeout\n"}
        }
        expect eof
END

find . -type f -print0 | xargs -0 md5sum > md5sum.txt
popd

mkdir -p ${out}
xorriso -as mkisofs -r -J -joliet-long \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -o ${out}/${release_name}.iso ${workspace}/cd-image
EOF

chmod a+x ./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh

./ubuntu-cd-make/script_for_ubuntu_cd/indices.sh
./ubuntu-cd-make/script_for_ubuntu_cd/scan_make.sh

