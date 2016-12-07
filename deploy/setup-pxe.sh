#!/bin/bash
###################################################################################
# Notice: Only support grubaa64.efi at present
# setup-pxe.sh --tftproot=/var/lib/tftpboot --nfsroot=/var/lib/nfsroot --net=eth0
###################################################################################

###################################################################################
# Global args
###################################################################################
TFTP_ROOT=
NFS_ROOT=

NETCARD_NAME=
HWADDR=
INET_ADDR=
BROAD_CAST=
INET_MASK=
SUB_NET=
ROUTER=

###################################################################################
# Usage
###################################################################################
Usage()
{
cat << EOF
###################################################################
# mkisoimg.sh usage
###################################################################
Usage: setup-pxe.sh --tftproot=xxx --nfsroot=xxx --net=xxx
	-h, --help              display this help and exit
	--tftproot              TFTP server root directory
    --nfsroot               NFS server root directory
	--net                   wich ethernet card that the device will connect to (eth0, eth1 ...)

for example:
	setup-pxe.sh --tftproot=/var/lib/tftpboot --nfsroot=/var/nfsroot --net=eth0

EOF
}

###################################################################################
# string calculate_subnet(string host_ip, string netmask)
###################################################################################
calculate_subnet() {
	(
	host_ip=$1
	netmask=$2
	ip_addr=(`echo $host_ip | sed 's/\./ /g'`)
	netmasks=(`echo $netmask | sed 's/\./ /g'`)
	subnet=()
	for ((index=0; index<4; index++)); do
		subnet[$index]=$[${ip_addr[index]}&${netmasks[index]}]
	done
	echo ${subnet[*]} | tr ' ' '.'
	)
}

###################################################################################
# Check host
###################################################################################
host=`lsb_release -a 2>/dev/null | grep Codename: | awk {'print $2'}`
if [ "$host" != "lucid" -a "$host" != "precise" -a "$host" != "trusty" ]; then
	echo "Unsupported host machine, only Ubuntu 12.04 LTS and Ubuntu 14.04 LTS are supported"
	exit 1
fi

###################################################################################
# Get/Check parameters
###################################################################################
while test $# != 0
do
	case $1 in
		--*=*) ac_option=`expr "X$1" : 'X\([^=]*\)='` ; ac_optarg=`expr "X$1" : 'X[^=]*=\(.*\)'` ; ac_shift=:
			;;
		*) ac_option=$1 ; ac_optarg=$2 ; ac_shift=shift
			;;
	esac
	
	case $ac_option in
		-h | --help) Usage ; exit ;;
		--tftproot) TFTP_ROOT=$ac_optarg ;;
		--nfsroot) NFS_ROOT=$ac_optarg ;;
		--net) NETCARD_NAME=$ac_optarg ;;
		*) echo "Unknow option $ac_option!" ; Usage ; exit 1 ;;
	esac

	shift
done

if [ x"$TFTP_ROOT" = x"" ] || [ x"$NFS_ROOT" = x"" ] || [ x"NETCARD_NAME" = x"" ]; then
	echo "Tftp root, NFS root and Ethernet card must be specified!"
	Usage ; exit 1
fi

###################################################################################
# Install pxe packages
###################################################################################
dhcp_pkgs="isc-dhcp-server syslinux"
tftp_pkgs="openbsd-inetd tftpd-hpa tftp-hpa lftp"
nfs_pkgs="nfs-kernel-server nfs-common rpcbind portmap"

pxe_pkgs="$dhcp_pkgs $tftp_pkgs $nfs_pkgs"
if ! dpkg-query -l $pxe_pkgs >/dev/null 2>&1; then
	sudo apt-get update
	if ! sudo apt-get install -y $pxe_pkgs; then
		echo "Install $pxe_pkgs failed!" ; exit 1
	fi
fi

###################################################################################
# Get netcard info
###################################################################################
HWADDR=`ifconfig $NETCARD_NAME 2>/dev/null | grep -Po "(?<=HWaddr )([^ ]*)"`
INET_ADDR=`ifconfig $NETCARD_NAME 2>/dev/null | grep -Po "(?<=inet addr:)([^ ]*)"`
BROAD_CAST=`ifconfig $NETCARD_NAME 2>/dev/null | grep -Po "(?<=Bcast:)([^ ]*)"`
INET_MASK=`ifconfig $NETCARD_NAME 2>/dev/null | grep -Po "(?<=Mask:)([^ ]*)"`
SUB_NET=`calculate_subnet $INET_ADDR $INET_MASK`
ROUTER=`route | grep "$NETCARD_NAME" | grep default | awk '{print $2}'`
if [ x"$ROUTER" = x"" ]; then
	ROUTER=$INET_ADDR
fi

###################################################################################
# Set up DHCP server
###################################################################################
cat > /tmp/isc-dhcp-server << EOM
INTERFACES="$NETCARD_NAME"
EOM

sudo mv /tmp/isc-dhcp-server /etc/default/isc-dhcp-server

net_param=${INET_ADDR%.*}
cat > /tmp/dhcpd.conf << EOM
authoritative;
default-lease-time 600;
max-lease-time 7200;
ping-check true;
ping-timeout 2;
allow booting;
allow bootp;
subnet ${SUB_NET} netmask ${INET_MASK} {
    range ${net_param}.210 ${net_param}.250;
    option subnet-mask ${INET_MASK};
    option domain-name-servers ${ROUTER};
    option time-offset -18000;
    option routers ${ROUTER};
    option subnet-mask ${INET_MASK};
    option broadcast-address ${BROAD_CAST};
    default-lease-time 600;
    max-lease-time 7200;
    next-server ${INET_ADDR};
    filename "grubaa64.efi";
}
EOM

sudo mv /tmp/dhcpd.conf /etc/dhcp/dhcpd.conf

###################################################################################
# Set tftp server
###################################################################################
sudo mkdir -p $TFTP_ROOT
tftp_root=`cd $TFTP_ROOT; pwd`
tftpcfg=/etc/default/tftpd-hpa

cat > /tmp/tftpd-hpa << EOM
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="$tftp_root"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="-l -c -s"
EOM
sudo mv /tmp/tftpd-hpa /etc/default/tftpd-hpa || exit 1

if ! grep -E "^(TFTP_DIRECTORY=\"$tftp_root\")" $tftpcfg 2>/dev/null; then
	sudo cp $tftpcfg $tftpcfg.old 2>/dev/null
	if ! sudo sed -i "s/^\(TFTP_DIRECTORY=\"\)\([^\"]*\)\(\"\)/\1$tftp_root\3/g" tftpd-hpa $tftpcfg; then
		exit 1
	fi
fi

cat > /tmp/inetd.conf << EOM
tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s $TFTP_ROOT
EOM
sudo mv /tmp/inetd.conf /etc/inetd.conf || exit 1

sudo chmod 777 -R $tftp_root || exit 1
sudo chown nobody $tftp_root || exit 1
TFTP_ROOT=$tftp_root

###################################################################################
# Set up NFS server
###################################################################################
sudo mkdir -p $NFS_ROOT
nfs_root=`cd $NFS_ROOT; pwd`

sudo chmod 777 $nfs_root
if ! grep $nfs_root /etc/exports >/dev/null 2>&1; then
	sudo chmod 666 /etc/exports || exit 1
	sudo echo "$nfs_root *(rw,nohide,insecure,no_subtree_check,async,no_root_squash)" >> /etc/exports
	sudo chmod 644 /etc/exports || exit 1
fi

###################################################################################
# Restart PXE server
###################################################################################
sudo /etc/init.d/nfs-kernel-server stop ; sleep 1
sudo /etc/init.d/nfs-kernel-server start || exit 1

sudo update-inetd --enable BOOT
sudo service openbsd-inetd stop
sudo service tftpd-hpa stop ; sleep 1
sudo service openbsd-inetd restart || exit 1
sudo service tftpd-hpa restart || exit 1

sudo service isc-dhcp-server stop
sudo service isc-dhcp-server restart || exit 1
