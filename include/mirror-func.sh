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
