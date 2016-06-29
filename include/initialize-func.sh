#!/bin/bash

###################################################################################
# install_dev_tools <arch>
###################################################################################
install_dev_tools()
{
	local arch=$1
	if [ x"$arch" = x"x86_64" ]; then
		local dev_tools="wget automake1.11 make bc libncurses5-dev libtool libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 bison flex uuid-dev build-essential iasl jq genisoimage libssl-dev"
	else
		local dev_tools="wget automake1.11 make bc libncurses5-dev libtool libc6 libncurses5 libstdc++6 bison flex uuid-dev build-essential iasl acpica-tools jq genisoimage libssl-dev"
	fi

	if ! (automake --version 2>/dev/null | grep 'automake (GNU automake) 1.11' >/dev/null); then
		sudo apt-get remove -y --purge automake*
	fi

	if ! (dpkg-query -l $dev_tools >/dev/null 2>&1); then
		sudo apt-get update
		if ! (sudo apt-get install -y --force-yes $dev_tools); then
			return 1
		fi
	fi
	
	return 0
}

###################################################################################
# update_acpica_tools
###################################################################################
update_acpica_tools()
{
	if [ ! -d acpica ]; then
		git clone https://github.com/acpica/acpica.git
	fi

	(cd acpica/generate/unix && make -j${corenum} && sudo make install)
}

