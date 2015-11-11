#!/bin/bash
#description: setup PXE environment for deploying estuary.
#author: wangyanliang
#date: October 19, 2015

cwd=`dirname $0`
. $cwd/common.sh

CFGFILE=$cwd/estuarycfg.json

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

packages_to_install="jq isc-dhcp-server syslinux tftpd-hpa tftp-hpa lftp inetutils-inetd nfs-kernel-server build-essential libncurses5-dev openbsd-inetd"

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
begin to parse estuarycfg.json ...
EOM
build_PLATFORM=`jq -r ".system.platform" $CFGFILE`

if [ "$build_PLATFORM" == "D01" ]; then
    TARGET_ARCH=ARM32
else
    TARGET_ARCH=ARM64
fi

DISTROS=()
idx=0
idx_en=0
install=`jq -r ".distros[$idx].install" $CFGFILE`
while [ x"$install" != x"null" ];
do
    if [ x"yes" = x"$install" ]; then
        idx_en=${#DISTROS[@]}
        DISTROS[${#DISTROS[@]}]=`jq -r ".distros[$idx].name" $CFGFILE`
    fi
    name=`jq -r ".distros[$idx].name" $CFGFILE`
    value=`jq -r ".distros[$idx].install" $CFGFILE`
    case $name in
        "Ubuntu")
        ubuntu_en=$value
        ;;
        "Opensuse")
        opensuse_en=$value
        ;;
        "Fedora")
        fedora_en=$value
        ;;
        "Debian")
        debian_en=$value
        ;;
        *)
        ;;
    esac
    let idx=$idx+1
    install=`jq -r ".distros[$idx].install" $CFGFILE`
done

echo "Get host sever inet addr, broadcast, netmask, etc."
netcard_count=`ifconfig -a | grep -A 1 eth | grep "inet addr" | grep -v 127.0.0.1 | grep -v "Bcast:0.0.0.0" | wc -l`
if [ $netcard_count -gt 1 ]; then
    echo "netcard_count=$netcard_count"
    echo -e "\nPlease choise the network card needed: \n"
    ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
    echo " "

    NETCARDNUMBER=
    while true;
    do
        read -p 'Enter Device Number or 'n' to exit: ' NETCARDNUMBER
        echo " "
            if [ "$NETCARDNUMBER" = 'n' ]; then
                    exit 1
            fi

            if [ "$NETCARDNUMBER" = "" ]; then
                echo -e "\nPlease choise the network card needed: \n"
                ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
                echo " "
                continue
            fi
        
        NETCARDNAME=`ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}' | grep "${NETCARDNUMBER})" | awk '{print $2}'`
        if [ -n "$NETCARDNAME" ]
        then
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
                ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
                echo " "
        fi
    done

    echo "$NETCARDNAME was selected"
elif [ $netcard_count -eq 1 ]; then
    echo ""
    echo "netcard_count=$netcard_count"
    NETCARDNUMBER=1
    NETCARDNAME=`ifconfig -a | grep -A 1 eth | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}' | grep "${NETCARDNUMBER})" | awk '{print $2}'`
	if [ -n "$NETCARDNAME" ]
	then
        HWaddr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $5}'`
        inet_addr=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $7}' | awk 'BEGIN{FS=":"} {print $2}'`
        broad_cast=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $8}' | awk 'BEGIN{FS=":"} {print $2}'`
        inet_mask=`ifconfig -a | grep -A 1 "$NETCARDNAME" | awk 'BEGIN{RS="--\n"} {print $9}' | awk 'BEGIN{FS=":"} {print $2}'`
        sub_net=`route | grep "$NETCARDNAME" | grep -v default | awk '{print $1}'`
        router=`route | grep "$NETCARDNAME" | grep default | awk '{print $2}'`
        echo "HWaddr=$HWaddr, inet_addr=$inet_addr, broad_cast=$broad_cast, inet_mask=$inet_mask, sub_net=$sub_net, router=$router"
	else
		echo -e "$NETCARDNAME not exist !!!"
	fi
else
    echo "Please setup NetCard!"
fi

pushd ..
if [ ! -d build/$build_PLATFORM/binary ]
then
    # Make sure that the build.sh file exists
    if [ -f $cwd/estuary/build.sh ]; then
        $cwd/estuary/build.sh -p $build_PLATFORM -d Ubuntu
        echo "execute build.sh"
    else
        echo "build.sh does not exist in the directory"
        exit 1
    fi
fi
popd

cat > /etc/default/isc-dhcp-server << EOM
INTERFACES="$NETCARDNAME"
EOM

net_param=${inet_addr%.*}
cat > /etc/dhcp/dhcpd.conf << EOM
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
fi
sudo rm -f /var/lib/tftpboot/grub.cfg*

idx=0
mac_addr=`jq -r ".boards[$idx].mac" $CFGFILE`
while [ x"$mac_addr" != x"null" ];
do
    grub_suffix=$mac_addr
cat > /var/lib/tftpboot/grub.cfg-$grub_suffix << EOM
set timeout=5
set default=ubuntu
menuentry "ubuntu" --id ubuntu {
        set root=(tftp,${inet_addr})
        linux /Image_D02 rdinit=/init console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 root=/dev/nfs rw nfsroot=${inet_addr}:/targetNFS ip=::::::dhcp
       devicetree /hip05-d02.dtb
}
EOM
    let idx=$idx+1
    mac_addr=`jq -r ".boards[$idx].mac" $CFGFILE`
done

platform=`jq -r ".system.platform" $CFGFILE`
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

platform=`jq -r ".system.platform" $CFGFILE`
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

sudo chmod 777 -R $tftproot
check_status
sudo chown nobody $tftproot
check_status

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


sudo apt-get install nfs-kernel-server
sudo apt-get install rpcbind
dstdefault=/targetNFS

echo "--------------------------------------------------------------------------------"
echo "In which directory do you want to install the target filesystem?(if this directory does not exist it will be created)"
read -p "[ $dstdefault ] " dst

if [ ! -n "$dst" ]; then
    dst=$dstdefault
fi
echo "--------------------------------------------------------------------------------"

echo
echo "--------------------------------------------------------------------------------"
echo "This step will extract the target filesystem to $dst"
echo
echo "Note! This command requires you to have administrator priviliges (sudo access) "
echo "on your host."
read -p "Press return to continue" REPLY

#copy/paste programs
cp_progress ()
{
	CURRENTSIZE=0
	while [ $CURRENTSIZE -lt $TOTALSIZE ]
	do
		TOTALSIZE=$1;
		TOHERE=$2;
		CURRENTSIZE=`sudo du -c $TOHERE | grep total | awk {'print $1'}`
		echo -e -n "$CURRENTSIZE /  $TOTALSIZE copied \r"
		sleep 1
	done
}

extract_fs() {
    fstar=`ls -1 udisk_images/udisk_*.tar.gz`
    me=`whoami`
    sudo mkdir -p $1
    check_status
    sudo tar -xzf $fstar -C $1
    check_status
    sudo chown $me:$me $1
    check_status
    sudo chown -R $me:$me $1/home $1/usr $1/etc $1/lib $1/boot
    check_status

    # Opt isn't a standard Linux directory. First make sure it exist.
    if [ -d $1/opt ];
    then
            sudo chown -R $me:$me $1/opt
            check_status
    fi

    echo
    echo "Successfully extracted `basename $fstar` to $1"
    
    
    mkdir -p $1/sys_setup/boot/EFI/GRUB2 2> /dev/null
    mkdir -p $1/sys_setup/distro 2> /dev/null
    mkdir -p $1/sys_setup/bin 2> /dev/null
    cp -a $cwd/../build/$build_PLATFORM/binary/grubaa64* $1/sys_setup/boot/EFI/GRUB2
    cp -a $cwd/../build/$build_PLATFORM/binary/Image_$build_PLATFORM $1/sys_setup/boot/Image
    cp -a $cwd/../build/$build_PLATFORM/binary/hip05-d02.dtb $1/sys_setup/boot
    if [ "$ubuntu_en" == "yes" ]; then
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH 2> /dev/null
        TOTALSIZE=`sudo du -c ../distro/Ubuntu_"$TARGET_ARCH".tar.gz | grep total | awk {'print $1'}`
        cp -af $cwd/../distro/Ubuntu_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH &
        cp_progress $TOTALSIZE $1/sys_setup/distro/$build_PLATFORM/ubuntu$TARGET_ARCH
    fi
    if [ "$fedora_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d Fedora
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../distro/Fedora_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/fedora$TARGET_ARCH
    fi
    if [ "$debian_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d Debian
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../distro/Debian_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/debian$TARGET_ARCH
    fi
    if [ "$opensuse_en" == "yes" ]; then
        pushd ..
        if [ -f $PWD/estuary/build.sh ]; then
            $PWD/estuary/build.sh -p $build_PLATFORM -d OpenSuse
        fi
        popd
        mkdir -p $1/sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH 2> /dev/null
        cp -a $cwd/../distro/OpenSuse_"$TARGET_ARCH".tar.gz $1/sys_setup/distro/$build_PLATFORM/opensuse$TARGET_ARCH
    fi

    cp -a sys_setup.sh $1/sys_setup/bin
    cp -a functions.sh $1/sys_setup/bin
    cp -a find_disk.sh $1/sys_setup/bin
    cp -a estuarycfg.json $1/sys_setup/bin

    touch $1/etc/profile.d/antoStartUp.sh
    chmod a+x $1/etc/profile.d/antoStartUp.sh
cat > $1/etc/profile.d/antoStartUp.sh << EOM
#!/bin/bash

pushd /sys_setup/bin
sudo ./sys_setup.sh
popd
EOM
}

if [ ! -d $cwd/udisk_images ]; then
    mkdir $cwd/udisk_images 2> /dev/null
else
    if [ ! -f  udisk_images/udisk_rootfs.tar.gz ]
    then
        wget -P udisk_images/ -c http://7xjz0v.com1.z0.glb.clouddn.com/dist/udisk_rootfs.tar.gz
    fi
fi

if [ -d $dst ]; then
    echo "$dst already exists"
    echo "(r) rename existing filesystem (o) overwrite existing filesystem (s) skip filesystem extraction"
    read -p "[r] " exists
    case "$exists" in
      s) echo "Skipping filesystem extraction"
         echo "WARNING! Keeping the previous filesystem may cause compatibility problems if you are upgrading the SDK"
         ;;
      o) sudo rm -rf $dst
         echo "Old $dst removed"
         extract_fs $dst
         ;;
      *) dte="`date +%m%d%Y`_`date +%H`.`date +%M`"
         echo "Path for old filesystem:"
         read -p "[ $dst.$dte ]" old
         if [ ! -n "$old" ]; then
             old="$dst.$dte"
         fi
         sudo mv $dst $old
         check_status
         echo
         echo "Successfully moved old $dst to $old"
         extract_fs $dst
         ;;
    esac
else
    extract_fs $dst
fi
echo $dst > $cwd/../.targetfs
echo "--------------------------------------------------------------------------------"

platform=`jq -r ".system.platform" $CFGFILE`
echo
echo "--------------------------------------------------------------------------------"
echo "This step will export your target filesystem for NFS access."
echo
echo "Note! This command requires you to have administrator priviliges (sudo access) "
echo "on your host."
read -p "Press return to continue" REPLY

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
echo "--------------------------------------------------------------------------------"
