
* [Mehtod 1](#1)
 * [Mehtod 1 introduction](#1.1)
 * [Setup DHCP server on Ubuntu](#1.2)
 * [Setup TFTP server on Ubuntu](#1.3)
 * [Put files in the TFTP root path](#1.4)
 * [Setup NFS server on Ubuntu](#1.5)
* [Mehtod 2](#2)
 * [Mehtod 1 introduction](#2.1)
 * [Put the D02 binaries into some `<netboot>` directory](#2.2)
 * [Get and build a patched Grub](#2.3)
 * [Get PyPXE](#2.4)
 * [Run the PyPXE server](#2.5)
 * [Boot the D02 board and enjoy](#2.6)
 
<h2 id="1">Mehtod 1</h2>

This is a guide to setup a PXE environment on host machine.

<h3 id="1.1">Mehtod 1 introduction</h3>


PXE boot depends on DHCP, TFTP and NFS services. So before verifing PXE, you need to setup a working DHCP, TFTP, NFS server on one of your host machine in local network. In this case, my host OS is Ubuntu 12.04.

<h3 id="1.2">Setup DHCP server on Ubuntu</h3>

Refer to https://help.ubuntu.com/community/isc-dhcp-server . For a simplified direction, try these steps:

* Install DHCP server package

  `sudo apt-get install -y isc-dhcp-server syslinux`

* Edit /etc/dhcp/dhcpd.conf to suit your needs and particular configuration.

   Make sure filename is consistent with the file in tftp root directory. 
    Here is an example: This will enable board to load "grubaa64.efi" from TFTP root to target board and run it, when you boot from PXE in UEFI Boot Menu. 
    ```shell
    $ cat /etc/dhcp/dhcpd.conf
    # Sample /etc/dhcpd.conf
    # (add your comments here)
    default-lease-time 600;
    max-lease-time 7200;
    subnet 192.168.1.0 netmask 255.255.255.0 {
        range 192.168.1.210 192.168.1.250;
        option subnet-mask 255.255.255.0;
        option domain-name-servers 192.168.1.1;
        option routers 192.168.1.1;
        option subnet-mask 255.255.255.0;
        option broadcast-address 192.168.1.255;
        # Change the filename according to your real local environment and target board type.
        # And make sure the file has been put in tftp root directory.
        # grubaa64.efi is for ARM64 architecture.
        # grubarm32.efi is for ARM32 architecture.
        filename "grubaa64.efi";
        #filename "grubarm32.efi";
        #next-server 192.168.1.107
    }
    #
    ```
* Edit /etc/default/isc-dhcp-server to specify the interfaces dhcpd should listen to. By default it listens to eth0.

   INTERFACES=""
   
* Use these commands to start and check DHCP service
  sudo service isc-dhcp-server restart

    Check status with "netstat -lu"

   Expected output:
    Proto Recv-Q Send-Q Local Address           Foreign Address         State      
    udp        0      0 *:bootpc                *:*                                

<h3 id="1.3">Setup TFTP server on Ubuntu</h3>

* Install TFTP server and TFTP client(optional, tftp-hpa is the client package)

  `sudo apt-get install -y openbsd-inetd tftpd-hpa tftp-hpa lftp`
  
* Edit /etc/inetd.conf

  Remove "#" from the beginning of tftp line or add if it’s not there under “#:BOOT:” comment as follow.
 
  `tftp    dgram   udp wait    root    /usr/sbin/in.tftpd  /usr/sbin/in.tftpd -s /var/lib/tftpboot`
 
* Enable boot service for inetd
  `sudo update-inetd --enable BOOT`
  
* Configure the TFTP server, update /etc/default/tftpd-hpa like follows:
  ```shell
    TFTP_USERNAME="tftp"
    TFTP_ADDRESS="0.0.0.0:69"
    TFTP_DIRECTORY="/var/lib/tftpboot"
    TFTP_OPTIONS="-l -c -s"
 ```
* Set up TFTP server directory
  ```shell
    sudo mkdir /var/lib/tftpboot
    sudo chmod -R 777 /var/lib/tftpboot/
  ```
* Restart inet & TFTP server
  ```shell
    sudo service openbsd-inetd restart
    sudo service tftpd-hpa restart
   ``` 
    Check status with "netstat -lu"
    
    Expected output:
    ```
   Proto Recv-Q Send-Q Local Address           Foreign Address         State 
    udp        0      0 *:tftp                  *:*                          
   ```
   
<h3 id="1.4">Put files in the TFTP root path</h3>

Put the corresponding files into TFTP root directory, they are:

The files include: grub binary file, grub configure file, kernel Image and dtb file. 
In my case, they are grubaa64.efi, Image_D02 and grub.cfg-01-xx-xx-xx-xx-xx-xx, hip05-d02.dtb.

Note: 

   1. The name of grub binary "grubaa64.efi" or "grubarm32.efi" must be as same as the DHCP configure file in `/etc/dhcp/dhcpd.conf`.<br>
   2. The grub configure file’s name must comply with a special format, e.g. grub.cfg-01-xx-xx-xx-xx-xx-xx, it starts with "grub.cfg-01-" and ends with board’s MAC address.<br>
   3. The gurb binary and grub.cfg-01-xx-xx-xx-xx-xx-xx files must be placed in the TFTP root directory.<br>
   4. The names and positions of kernel image and dtb must be consistent with the corresponding grub config file.<br>

To get and config grub and grub config files, please refer to [Grub_Manual.md](https://github.com/open-estuary/estuary/blob/master/doc/Grub_Manual.4All.md).

To get kernel and dtb file, please refer to Readme.md.

<h3 id="1.5">Setup NFS server on Ubuntu</h3>

* Install NFS server package
        
    sudo apt-get install nfs-kernel-server nfs-common portmap
                
* Modify configure file `/etc/exports` for NFS server

    Add following contents at the end of this file.
                      
    </rootnfs> *(rw,sync,no_root_squash)
                                    
    Note: `</rootnfs>` is your real shared directory of rootfs of distributions for NFS server.

* Uncompress a distribution to `</rootnfs>`

    To get them, please refer to [Distributions_Guider.md](https://github.com/open-estuary/estuary/blob/master/doc/Distributions_Guide.4All.md)

* Restart NFS service
    
    sudo service nfs-kernel-server restart

<h2 id="2">Mehtod 2</h2>

This is a guide to setup a PXE environment on host machine with PyPXE (https://github.com/psychomario/PyPXE.git).

<h3 id="2.1">Mehtod 2 introduction</h3>

It is an alternative to the setup described above.

It works well if you already have a DHCP server on your local network. Only one Python tool is needed (PyPXE) so you don't need to install and configure the DHCP and TFTP servers on the host (but, you may still want to
install the NFS server to mount root over NFS).

<h3 id="2.2">Put the D02 binaries into some netboot directory</h3>

For instance <netboot> = `~/work/d02/netboot`

Get the binaries from open-estuary.org or build them. See Readme.md.
You need:
  ```shell
  <netboot>/grubaa64.efi # You MUST rebuild it, see below
  <netboot>/grub.cfg     # Make sure you set your IP address:
                         # edit root = (tftp,x.x.x.x)
  <netboot>/Image_arm64
  <netboot>/mini-rootfs-arm64.cpio.gz # Or a distribution (Debian_ARM64.tar.gz...)
                                      # See NFS below
  ```
<h3 id="2.3">Get and build a patched Grub</h3>

You cannot use the pre-built grubaa64.efi because a patch [1] is needed, ("efinet: get bootstrap info from proxy offer packet") 
which is currently not upstream nor on open-estuary.org. The patch has been posted on the Grub development list [2] so it

may be upstream soon.

[1] https://github.com/jforissier/grub/commit/e0f3bc4554ee79111f6ef6f6910c662d02b981dd

[2] http://lists.gnu.org/archive/html/grub-devel/2016-04/msg00051.html
 ```shell
  git clone -b efinet-dhcp-proxy-offer-fix https://github.com/jforissier/grub
  cd grub
  ./autogen.sh
  ./configure --with-platform=efi --target=aarch64-linux-gnu
   make
  ./grub-mkimage -o grubaa64.efi --format=arm64-efi --prefix=/ --directory=grub-core boot chain configfile efinet ext2 fat gettext help hfsplus loadenv lsefi normal normal ntfs ntfscomp part_gpt part_msdos read search search_fs_file search_fs_uuid search_label terminal terminfo tftp linux
```
Then copy grubaa64.efi to <netboot>.

<h3 id="2.4">Get PyPXE</h3>
`git clone -b development https://github.com/psychomario/PyPXE.git`

<h3 id="2.5">Run the PyPXE server</h3>
```shell
 export MYIP=$(hostname -I)
 export NETBOOT=~/work/d02/netboot # put your own directory here
 cd pypxe
 sudo python -m pypxe.server --dhcp-proxy --dhcp-server-ip $MYIP --dhcp-fileserver $MYIP \
 --netboot-dir $NETBOOT --netboot-file grubaa64.efi
```

<h3 id="2.6">Boot the D02 board and enjoy</h3>

If you want to use a distribution root FS over NFS instead of using mini-rootfs-arm64.cpio.gz initrd, follow these steps.

* Extract the root FS tarball
 ```shell
   cd <netboot>
   mkdir Debian_ARM64
   (cd Debian_ARM64 ; sudo tar xf ../Debian_ARM64.tar.gz)
 ```
* Install the NFS server
  
  `sudo apt-get install nfs-kernel-server nfs-common portmap`

* Configure the NFS server

  `/path/to/netboot/Debian_ARM64 *(rw,sync,no_root_squash)`
  
* Restart the NFS server
  `sudo service nfs-kernel-server restart`

* Make sure grub.cfg contains an entry with the following line

 `linux /Image_arm64 rdinit=/init root=/dev/nfs rw nfsroot=192.168.1.10:/path/to/your/netboot/Debian_ARM64 console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp`


