#!/bin/bash
#description: setup PXE environment for deploying estuary.
#author: wangyanliang
#date: October 19, 2015

cwd=`dirname $0`
cd $cwd/../

PRJROOT=`pwd`
PLATFORM=
CFGFILE=$PRJROOT/estuary/estuarycfg.json
BINARY_DIR=
NFS_ROOT=
TFTP_ROOT=

. $PRJROOT/estuary/common.sh

###################################################################################
# 01. Verify distribution
###################################################################################
echo
echo "--------------------------------------------------------------------------------"
echo "Verifying Linux host distribution"

get_host_type host

if [ "$host" != "lucid" -a "$host" != "precise" -a "$host" != "trusty" ]; then
	echo "Unsupported host machine, only Ubuntu 12.04 LTS and Ubuntu 14.04 LTS are supported"
	exit 1
fi
echo "Ubuntu 12.04 LTS and Ubuntu 14.04 LTS is being used, continuing.."
echo "--------------------------------------------------------------------------------"
echo

###################################################################################
# 02. Install host packages
###################################################################################
entry_header() {
cat << EOF
-------------------------------------------------------------------------------
setup package script
This script will make sure you have the proper host support packages installed
This script requires administrator priviliges (sudo access) if packages are to be installed.
-------------------------------------------------------------------------------
EOF
}

exit_footer() {
cat << EOF
--------------------------------------------------------------------------------
Package verification and installation successfully completed
--------------------------------------------------------------------------------
EOF
}

entry_header

packages_to_install="jq isc-dhcp-server syslinux tftpd-hpa tftp-hpa lftp nfs-kernel-server rpcbind build-essential libncurses5-dev openbsd-inetd"
dpkg-query -l $packages_to_install >/dev/null 2>&1
if [ $? -ne 0 ]; then
	sudo apt-get update
	sudo apt-get install -y $packages_to_install
	if [ $? -ne 0 ]; then
		echo -e "\033[31mInstall packages failed!\033[0m" ; exit 1
	fi
fi

# Print the exit statement to the console
exit_footer

###################################################################################
# 03. Get host ethernet info
###################################################################################
echo "Get host sever inet addr, broadcast, netmask, etc."
netcard_count=`ifconfig -a | grep -A 1 eth | grep "inet addr" | grep -v 127.0.0.1 | grep -v "Bcast:0.0.0.0" | wc -l`
if [ $netcard_count -gt 1 ]; then
	echo "netcard_count=$netcard_count"
	echo -e "\nPlease choise the network card needed: \n"
	ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
	echo " "

	NETCARDNUMBER=
	while true; 
	do
		read -p 'Enter Device Number or 'q' to exit: ' NETCARDNUMBER
		echo " "
		if [ "$NETCARDNUMBER" = 'q' ]; then
			exit 1
		fi

		if [ "$NETCARDNUMBER" = "" ]; then
			echo -e "\nPlease choise the network card needed: \n"
			ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
			echo " "
			continue
		fi

		NETCARDNAME=`ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}' | grep "${NETCARDNUMBER})" | awk '{print $2}'`
		if [ -n "$NETCARDNAME" ]; then
			HWaddr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $5}'`
			inet_addr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $7}' | awk 'BEGIN{FS=":"} {print $2}'`
			broad_cast=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $8}' | awk 'BEGIN{FS=":"} {print $2}'`
			inet_mask=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $9}' | awk 'BEGIN{FS=":"} {print $2}'`
			sub_net=`route | grep "$NETCARDNAME" | grep -v default | awk '{print $1}'`
			router=`route | grep "$NETCARDNAME" | grep default | awk '{print $2}'`
			echo "HWaddr=$HWaddr, inet_addr=$inet_addr, broad_cast=$broad_cast, inet_mask=$inet_mask, sub_net=$sub_net, router=$router"
			break
		else
			echo -e "Invalid selection!"
			echo -e "\nPlease choise the network card needed: \n"
			ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
			echo " "
		fi
	done

	echo "$NETCARDNAME was selected"
elif [ $netcard_count -eq 1 ]; then
	echo ""
	echo "netcard_count=$netcard_count"
	NETCARDNUMBER=1
	NETCARDNAME=`ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}' | grep "${NETCARDNUMBER})" | awk '{print $2}'`
	if [ -n "$NETCARDNAME" ]; then
		HWaddr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $5}'`
		inet_addr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $7}' | awk 'BEGIN{FS=":"} {print $2}'`
		broad_cast=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $8}' | awk 'BEGIN{FS=":"} {print $2}'`
		inet_mask=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $9}' | awk 'BEGIN{FS=":"} {print $2}'`
		sub_net=`route | grep "$NETCARDNAME" | grep -v default | awk '{print $1}'`
		router=`route | grep "$NETCARDNAME" | grep default | awk '{print $2}'`
		echo "HWaddr=$HWaddr, inet_addr=$inet_addr, broad_cast=$broad_cast, inet_mask=$inet_mask, sub_net=$sub_net, router=$router"
	else
		echo -e "$NETCARDNAME not exist !!!" ; exit 1
	fi
else
	echo "Please setup NetCard!" ; exit 1
fi

###################################################################################
# 04. Set up DHCP server
###################################################################################
cat > /tmp/isc-dhcp-server << EOM
INTERFACES="$NETCARDNAME"
EOM

sudo mv /tmp/isc-dhcp-server /etc/default/isc-dhcp-server

net_param=${inet_addr%.*}
cat > /tmp/dhcpd.conf << EOM
authoritative;
default-lease-time 600;
max-lease-time 7200;
ping-check true;
ping-timeout 2;
allow booting;
allow bootp;
subnet ${sub_net} netmask ${inet_mask} {
    range ${net_param}.210 ${net_param}.250;
    option subnet-mask ${inet_mask};
    option domain-name-servers ${router};
    option time-offset -18000;
    option routers ${router};
    option subnet-mask ${inet_mask};
    option broadcast-address ${broad_cast};
    default-lease-time 600;
    max-lease-time 7200;
    next-server ${inet_addr};
    filename "grubaa64.efi";
}
EOM

sudo mv /tmp/dhcpd.conf /etc/dhcp/dhcpd.conf

###################################################################################
# 05. Set tftp server
###################################################################################
tftproot=
tftpcfg=/etc/default/tftpd-hpa
tftprootdefault=/var/lib/tftpboot

tftp() {
	cat > /tmp/inetd.conf << EOM
tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s $tftproot
EOM
	sudo mv /tmp/inetd.conf /etc/inetd.conf
}

echo "--------------------------------------------------------------------------------"
echo "Which directory do you want to be your tftp root directory?(if this directory does not exist it will be created for you)"
read -p "[ $tftprootdefault ] " tftproot

if [ ! -n "$tftproot" ]; then
	tftproot=$tftprootdefault
fi
echo $tftproot > $cwd/../.tftproot
echo "--------------------------------------------------------------------------------"

echo
echo "--------------------------------------------------------------------------------"
echo "This step will set up the tftp server in the $tftproot directory."
echo
echo "Note! This command requires you to have administrator priviliges (sudo access) "
echo "on your host."
read -p "Press return to continue" REPLY

sudo mkdir -p $tftproot 2>/dev/null
check_status

cat > /tmp/tftpd-hpa << EOM
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="$tftproot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="-l -c -s"
EOM

sudo mv /tmp/tftpd-hpa /etc/default/tftpd-hpa

if [ -f $tftpcfg ]; then
	echo "$tftpcfg already exists.."
	tmp=\"$tftproot\"
	if [ "`cat $tftpcfg | grep TFTP_DIRECTORY | cut -d= -f2 | sed 's/^[ ]*//'`" \
	  = "$tmp" ]; then
		echo "$tftproot already exported for TFTP, skipping.."
		tftp
	else
		echo "Copying old $tftpcfg to $tftpcfg.old"
		sudo cp $tftpcfg $tftpcfg.old
		check_status
		tftp
	fi
else
	tftp
fi

sudo chmod 777 -R $tftproot
check_status
sudo chown nobody $tftproot
check_status

TFTP_ROOT=$tftproot

###################################################################################
# 06. Set up NFS server
###################################################################################
dstdefault=/targetNFS
echo "--------------------------------------------------------------------------------"
echo "In which directory do you want to install the target filesystem?(if this directory does not exist it will be created)"
read -p "[ $dstdefault ] " dst

if [ ! -n "$dst" ]; then
	dst=$dstdefault
fi

echo
echo "--------------------------------------------------------------------------------"
echo "This step will export your target filesystem for NFS access."
echo
echo "Note! This command requires you to have administrator priviliges (sudo access) "
echo "on your host."
read -p "Press return to continue" REPLY

sudo mkdir -p $dst
sudo chmod 777 $dst

grep $dst /etc/exports > /dev/null
if [ "$?" -eq "0" ]; then
	echo "$dst already NFS exported, skipping.."
else
	sudo chmod 666 /etc/exports
	check_status
	sudo echo "$dst *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)" >> /etc/exports
	check_status
	sudo chmod 644 /etc/exports
	check_status
fi

echo
sudo /etc/init.d/nfs-kernel-server stop
check_status
sleep 1
sudo /etc/init.d/nfs-kernel-server start
check_status

NFS_ROOT=`mktemp -d $dst/rootfs.XXXXXX`

###################################################################################
# 07. Copy binary files
###################################################################################
platform=`jq -r ".system.platform" $CFGFILE`
binary_dir=$PRJROOT/build/$platform/binary

echo "--------------------------------------------------------------------------------"
echo "Copy binary to NFS root......"
echo "--------------------------------------------------------------------------------"

# Copy distributions
index=0
install=`jq -r ".distros[$index].install" $CFGFILE 2>/dev/null`
while [ x"$?" = x"0" ] && [ x"$install" != x"null" ] && [ x"$install" != x"" ];
do
	if [ x"yes" = x"$install" ]; then
		idx=${#distributions[@]}
		distro=`jq -r ".distros[$index].name" $CFGFILE`
		echo "copy distribution ${distro}_ARM64.tar.gz to $NFS_ROOT ......"
		cp $binary_dir/${distro}_ARM64.tar.gz $NFS_ROOT/
	fi
	((index = index + 1))
	install=`jq -r ".distros[$index].install" $CFGFILE 2>/dev/null`
done

# Copy kernel, grub to NFS root......
echo "copy kernel related files to $NFS_ROOT......"
cp $binary_dir/grub*.efi $NFS_ROOT/
cp $binary_dir/hip*.dtb $NFS_ROOT/
cp $binary_dir/Image* $NFS_ROOT/
echo "--------------------------------------------------------------------------------"
echo "Copy binary to NFS root done!"
echo "--------------------------------------------------------------------------------"

# Copy kernel, grub to TFTP root......
# echo "copy kernel related files to $TFTP_ROOT......"
# cp $binary_dir/grub*.efi $TFTP_ROOT/
# cp $binary_dir/hip*.dtb $TFTP_ROOT/
# cp $binary_dir/Image* $TFTP_ROOT/

PLATFORM=$platform
BINARY_DIR=$binary_dir

###################################################################################
# initrd.gz
###################################################################################
user=`whoami`
group=`groups | awk '{print $1}'`

mkdir workspace
cp $binary_dir/mini-rootfs-arm64.cpio.gz workspace/
cp $binary_dir/deploy-utils.tar.bz2 workspace/
cp ./estuary/setup.sh workspace/
cp ./estuary/estuarycfg.json workspace/

pushd workspace

# rootfs start
mkdir rootfs ; pushd rootfs
zcat ../mini-rootfs-arm64.cpio.gz | sudo cpio -dimv
sudo chown -R ${user}:${group} *
if ! (grep "/usr/bin/setup.sh" etc/init.d/rcS); then
	echo "/usr/bin/setup.sh" >> etc/init.d/rcS
fi

cp ../estuarycfg.json ./usr/bin/
mv ../setup.sh ./usr/bin/
sed -i "s/\(INSTALL_TYPE=\"\).*\(\"\)/\1NFS\2/g" ./usr/bin/setup.sh
sudo chmod 755 ./usr/bin/setup.sh
tar jxvf ../deploy-utils.tar.bz2 -C ./
sudo chown -R root:root *
find | sudo cpio -o -H newc | gzip -c > ../initrd.gz
popd
# rootfs end
cp initrd.gz $TFTP_ROOT/
popd
sudo rm -rf workspace

###################################################################################
#
###################################################################################
sudo rm -f $tftproot/grub.cfg*
if [ x"D02" = x"$PLATFORM" ]; then
	cmd_line="rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 root=/dev/nfs rw nfsroot=${inet_addr}:$NFS_ROOT ip=dhcp"
else
	cmd_line="rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 root=/dev/nfs rw nfsroot=${inet_addr}:$NFS_ROOT ip=dhcp"
fi

pushd $BINARY_DIR
Image="`ls Image*`"
Dtb="`ls hip*.dtb`"
Grub="`ls grub*.efi`"
popd

cp $BINARY_DIR/$Image $TFTP_ROOT/
cp $BINARY_DIR/$Dtb $TFTP_ROOT/
cp $BINARY_DIR/$Grub $TFTP_ROOT/

idx=0
mac_addr=`jq -r ".boards[$idx].mac" $CFGFILE`
sudo rm -f $tftproot/grub.cfg*
while [ x"$mac_addr" != x"null" ];
do
	grub_suffix=$mac_addr
cat > $tftproot/grub.cfg-$grub_suffix << EOM
set timeout=5
set default=minilinux
menuentry "Install estuary" --id minilinux {
        set root=(tftp,${inet_addr})
        linux /$Image $cmd_line
        initrd /initrd.gz
        # devicetree /$Dtb
}
EOM
	let idx=$idx+1
	mac_addr=`jq -r ".boards[$idx].mac" $CFGFILE`
done

###################################################################################
# 08. Stat all services
###################################################################################
sudo update-inetd --enable BOOT

echo
echo "Restarting tftp server"
sudo service isc-dhcp-server stop
sudo service openbsd-inetd stop
sudo service tftpd-hpa stop
check_status
sleep 1
sudo service isc-dhcp-server start
sudo service openbsd-inetd start
sudo service tftpd-hpa start
check_status
echo "--------------------------------------------------------------------------------"

exit 0


