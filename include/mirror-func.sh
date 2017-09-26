set_debian_mirror()
{
	if [ -n "${DEBIAN_MIRROR}" ]; then
		sed -i "s#http://.*/debian#${DEBIAN_MIRROR}#" /etc/apt/sources.list
		apt update
	fi
}
