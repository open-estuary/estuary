set_debian_mirror()
{
	rm -rf /etc/apt/sources.list.d/*.list
	wget -O - http://repo.estuarydev.org/releases/ESTUARY-GPG-KEY | apt-key add -
	wget -O /etc/apt/sources.list.d/estuary.list https://raw.githubusercontent.com/open-estuary/distro-repo/master/estuaryftp_debian.list
	if [ -n "${DEBIAN_MIRROR}" ]; then
		local default_mirror="http://deb.debian.org/debian"
		sed -i "s#${default_mirror}#${DEBIAN_MIRROR}#" \
			/etc/apt/sources.list
	fi

        if [ -n "${DEBIAN_SECURITY_MIRROR}" ]; then
                local default_security_mirror="http://security.debian.org/"
                sed -i "s#${default_security_mirror}#${DEBIAN_SECURITY_MIRROR}#" \
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
	if [ -n "${UBUNTU_ESTUARY_REPO}" ]; then
		local default_repo="http://repo.estuarydev.org/releases/5.0/ubuntu"
		sed -i "s#${default_repo}#${UBUNTU_ESTUARY_REPO}#" \
			/etc/apt/sources.list.d/estuary.list
		sed -i "s#5.0#5.1#g" \
			/etc/apt/sources.list.d/estuary.list
	fi

	local mirror=${UBUNTU_MIRROR:-http://ports.ubuntu.com/ubuntu-ports}

cat >/etc/apt/sources.list<<EOF
deb ${mirror}/ xenial main restricted universe multiverse
deb-src ${mirror}/ xenial main restricted universe multiverse

deb ${mirror}/ xenial-updates main restricted universe multiverse
deb-src ${mirror}/ xenial-updates main restricted universe multiverse

deb ${mirror}/ xenial-security main restricted universe multiverse
deb-src ${mirror}/ xenial-security main restricted universe multiverse

deb ${mirror}/ xenial-backports main restricted universe multiverse
deb-src ${mirror}/ xenial-backports main restricted universe multiverse
EOF
}
