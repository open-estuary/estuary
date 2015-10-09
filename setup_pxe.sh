#!/bin/bash

cwd=`dirname $0`
. $cwd/common.sh

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

packages_to_install="isc-dhcp-server syslinux apache2 tftpd-hpa tftp-hpa lftp openbsd-inetd inetutils-inetd nfs-kernel-server build-essential libncurses5-dev"

cmd="sudo apt-get install "

# Check and only install the missing packages
for i in $packages_to_install; do
	is_it_installed=`dpkg-query -l $i 2>/dev/null`
    if [ "$?" -ne "0" ]; then
		needs_installation=`echo $needs_installation`" "$i
		new_cmd=`echo $cmd`" "$i
		cmd=$new_cmd
	fi
done

if [ "$needs_installation" = "" ]; then
    echo "System has required packages!"
else
    echo "System requires packages $needs_installation to be installed"

    echo "Installation requires you to have administrator priviliges (sudo access) "
    echo "on your host. Do you have administrator privilieges?"

    # Force the user to answer.  Maybe the user does not want to continue
    while true;
    do
        read -p "Type 'y' to continue or 'n' to exit the installation: " REPLY
        if [ "$REPLY" = 'y' -o "$REPLY" = 'n' ]; then
            break;
        fi
    done

    if [ "$REPLY" = 'n' ]; then
        echo "Installation is aborted by user"
        exit 1
    fi

    echo "Performing $cmd"
    $cmd
    check_status
fi
# Print the exit statement to the console
exit_footer

cat << EOM
start to parse  estuary.cfg ...
EOM
while read line
do
    name=`echo $line | awk -F '=' '{print $1}'`
    value=`echo $line | awk -F '=' '{print $2}'`
    case $name in
        "arch")
        TARGET_ARCH=$value
        ;;
        "platform")
        build_PLATFORM=$value
        ;;
        "distro")
        build_DISTRO=$value
        ;;
        "ubuntu")
        ubuntu_en=$value
        ;;
        "opensuse")
        opensuse_en=$value
        ;;
        "fedora")
        fedora_en=$value
        ;;
        *)
        ;;
    esac
done < estuary.cfg

dhcp_interface=/etc/default/isc-dhcp-server
cat > dhcp_interface << EOM
INTERFACES="eth0"
EOM

cat > /etc/dhcp/dhcpd.conf << EOM
authoritative;
default-lease-time 600;
max-lease-time 7200;
subnet 192.168.3.0 netmask 255.255.255.0 {
    range 192.168.3.210 192.168.3.250;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 192.168.3.1;
    option routers 192.168.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.3.255;
    filename "grubaa64.efi";
    #next-server 192.168.3.100
    #
}
EOM

tftpcfg=/etc/default/tftpd-hpa
tftprootdefault=/var/lib/tftpboot

tftp() {
cat > /etc/inetd.conf << EOM
tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /var/lib/tftpboot
EOM
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

if [ -d $tftproot ]; then
    echo
    echo "$tftproot already exists, not creating.."
else
    sudo mkdir -p $tftproot
    check_status
    sudo chmod 777 $tftproot
    check_status
    sudo chown nobody $tftproot
    check_status
fi
sudo rm -f /var/lib/tftpboot/grub.cfg*
read -p "[ Please input MAC address of D02 boards ] " grub_suffix

cat > /var/lib/tftpboot/grub.cfg-$grub_suffix << EOM
set timeout=5
set default=ubuntu
menuentry "minilinux" --id minilinux {
        set root=(tftp,192.168.1.107)
        linux /wangyanliang/Image rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000
        initrd /wangyanliang/hulk-hip05.cpio.gz
        devicetree /wangyanliang/hip05-d02.dtb
}
menuentry "ubuntu" --id ubuntu {
        set root=(tftp,192.168.3.211)
        linux /Image_D02 rdinit=/init console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/wangyanliang/ubuntu ip=192.168.1.156:192.168.1.107:192.168.1.1:255.255.255.0::eth0:dhcp
       devicetree /hip05-d02.dtb
}
menuentry "opensuse" --id opensuse {
        set root=(tftp,192.168.1.107)
        linux /wangyanliang/Image rdinit=/init console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/wangyanliang/opensuse ip=192.168.1.156:192.168.1.107:192.168.1.1:255.255.255.0::eth0:dhcp
       devicetree /wangyanliang/hip05-d02.dtb
}
EOM

platform=`cat estuary.cfg | grep -e "^platform=" | cut -d= -f2`
kernelimage="Image_""$platform"
kernelimagesrc=`ls -1 $cwd/../build/$platform/binary/$kernelimage`
if [ -f $tftproot/$kernelimage ]; then
    echo
    echo "$tftproot/$kernelimage already exists. The existing installed file can be renamed and saved under the new name."
    echo "(r) rename (o) overwrite (s) skip copy "
    read -p "[r] " exists
    case "$exists" in
      s) echo "Skipping copy of $kernelimage, existing version will be used"
         ;;
      o) sudo cp $kernelimagesrc $tftproot
         check_status
         echo
         echo "Successfully overwritten $kernelimage in tftp root directory $tftproot"
         ;;
      *) dte="`date +%m%d%Y`_`date +%H`.`date +%M`"
         echo "New name for existing kernelimage: "
         read -p "[ $kernelimage.$dte ]" newname
         if [ ! -n "$newname" ]; then
             newname="$kernelimage.$dte"
         fi
         sudo mv "$tftproot/$kernelimage" "$tftproot/$newname"
         check_status
         sudo cp $kernelimagesrc $tftproot
         check_status
         echo
         echo "Successfully copied $kernelimage to tftp root directory $tftproot as $newname"
         ;;
    esac
else
    sudo cp $kernelimagesrc $tftproot
    check_status
    echo
    echo "Successfully copied $kernelimage to tftp root directory $tftproot"
fi

platform=`cat estuary.cfg | grep -e "^platform=" | cut -d= -f2`
dtbfiles=`cd $cwd/../build/$platform/binary/;ls -1 *.dtb`
prebuiltimagesdir=`cd $cwd/../build/$platform/binary/ ; echo $PWD`

for dtbfile in $dtbfiles
do
    if [ -f $tftproot/$dtbfile ]; then
        echo
        echo "$tftproot/$dtbfile already exists. The existing installed file can be renamed and saved under the new name."
        echo "(o) overwrite (s) skip copy "
        read -p "[o] " exists
        case "$exists" in
          s) echo "Skipping copy of $dtbfile, existing version will be used"
             ;;
          *) sudo cp "$prebuiltimagesdir/$dtbfile" $tftproot
             check_status
             echo
             echo "Successfully overwritten $$dtbfile in tftp root directory $tftproot"
             ;;
        esac
    else
        sudo cp "$prebuiltimagesdir/$dtbfile" $tftproot
        check_status
        echo
        echo "Successfully copied $dtbfile to tftp root directory $tftproot"
    fi
done

grub_efi=grubaa64.efi
grub_efisrc=`ls -1 $cwd/../build/$platform/binary/$grub_efi`
if [ -f $tftproot/$grub_efi ]; then
    echo
    echo "$tftproot/$grub_efi already exists. The existing installed file can be renamed and saved under the new name."
    echo "(r) rename (o) overwrite (s) skip copy "
    read -p "[r] " exists
    case "$exists" in
      s) echo "Skipping copy of $grub_efi, existing version will be used"
         ;;
      o) sudo cp $grub_efisrc $tftproot
         check_status
         echo
         echo "Successfully overwritten $grub_efi in tftp root directory $tftproot"
         ;;
      *) dte="`date +%m%d%Y`_`date +%H`.`date +%M`"
         echo "New name for existing kernelimage: "
         read -p "[ $grub_efi.$dte ]" newname
         if [ ! -n "$newname" ]; then
             newname="$grub_efi.$dte"
         fi
         sudo mv "$tftproot/$grub_efi" "$tftproot/$newname"
         check_status
         sudo cp $grub_efisrc $tftproot
         check_status
         echo
         echo "Successfully copied $grub_efi to tftp root directory $tftproot as $newname"
         ;;
    esac
else
    sudo cp $grub_efisrc $tftproot
    check_status
    echo
    echo "Successfully copied $grub_efi to tftp root directory $tftproot"
fi

echo
if [ -f $tftpcfg ]; then
    echo "$tftpcfg already exists.."
    tmp=\"$tftproot\"
    #Use = instead of == for POSIX and dash shell compliance
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

sudo update-inetd --enable BOOT
sudo apt-get install openbsd-inetd

cat > /etc/default/tftpd-hpa << EOM
# /etc/default/tftpd-hpa

TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="-l -c -s"
EOM

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
