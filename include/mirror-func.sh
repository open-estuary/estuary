set_debian_mirror()
{
	if [ -n "${DEBIAN_MIRROR}" ]; then
		local default_mirror="http://debian.ustc.edu.cn/debian"
		sed -i "s#${default_mirror}#${DEBIAN_MIRROR}#" \
			/etc/apt/sources.list
	fi

	if [ -n "${DEBIAN_ESTUARY_REPO}" ]; then
		local default_repo="http://repo.estuarydev.org/releases/5.0/debian"
		sed -i "s#${default_repo}#${DEBIAN_ESTUARY_REPO}#" \
			/etc/apt/sources.list.d/estuary.list
	fi
}

set_ubuntu_mirror()
{
rm -rf /etc/apt/sources.list.d/estuary.list

local mirror=${UBUNTU_MIRROR:-ports.ubuntu.com/ubuntu-ports}
cat <<EOF > /etc/apt/sources.list
deb http://${mirror}/ xenial main restricted universe multiverse
deb-src http://${mirror}/ xenial main restricted universe multiverse

deb http://${mirror}/ xenial-updates main restricted universe multiverse
deb-src  http://${mirror}/ xenial-updates main restricted universe multiverse

deb http://${mirror}/ xenial-security main restricted universe multiverse
deb-src  http://${mirror}/ xenial-security main restricted universe multiverse

deb http://${mirror}/ xenial-backports main restricted universe multiverse
deb-src http://${mirror}/ xenial-backports main restricted universe multiverse
EOF
}

