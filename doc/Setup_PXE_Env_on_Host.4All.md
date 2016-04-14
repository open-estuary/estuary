
* [Introduction](#1)
* [Setup DHCP server on Ubuntu](#2)
* [Setup TFTP server on Ubuntu](#3)
* [Put files in the TFTP root path](#4)
* [Setup NFS server on Ubuntu](#5)

This is a guide to setup a PXE environment on host machine.

<h2 id="1">Introduction</h2>

PXE boot depends on DHCP, TFTP and NFS services. So before verifing PXE, you need to setup a working DHCP, TFTP, NFS server on one of your host machine in local network. In this case, my host OS is Ubuntu 12.04.

<h2 id="2">Setup DHCP server on Ubuntu</h2>

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

<h2 id="3">Setup TFTP server on Ubuntu</h2>

* Install TFTP server and TFTP client(optional, tftp-hpa is the client package)

  `sudo apt-get install -y openbsd-inetd tftpd-hpa tftp-hpa lftp`
  
* Edit /etc/inetd.conf

  Remove "#" from the beginning of tftp line or add if it’s not there under “#:BOOT:” comment as follow.
 
  tftp    dgram   udp wait    root    /usr/sbin/in.tftpd  /usr/sbin/in.tftpd -s /var/lib/tftpboot
 
* Enable boot service for inetd
  `sudo update-inetd --enable BOOT`
  
* Configure the TFTP server, update /etc/default/tftpd-hpa like follows:

    TFTP_USERNAME="tftp"
    TFTP_ADDRESS="0.0.0.0:69"
    TFTP_DIRECTORY="/var/lib/tftpboot"
    TFTP_OPTIONS="-l -c -s"

* Set up TFTP server directory

    sudo mkdir /var/lib/tftpboot
    sudo chmod -R 777 /var/lib/tftpboot/

* Restart inet & TFTP server

    sudo service openbsd-inetd restart
    sudo service tftpd-hpa restart
    
    Check status with "netstat -lu"
    
    Expected output:
    Proto Recv-Q Send-Q Local Address           Foreign Address         State 
    udp        0      0 *:tftp                  *:*                          

<h2 id="4">Put files in the TFTP root path</h2>

Put the corresponding files into TFTP root directory, they are:

The files include: grub binary file, grub configure file, kernel Image and dtb file. 
In my case, they are grubaa64.efi, Image_D02 and grub.cfg-01-xx-xx-xx-xx-xx-xx, hip05-d02.dtb.

Note: 
    1. The name of grub binary "grubaa64.efi" or "grubarm32.efi" must be as same as the DHCP configure file in /etc/dhcp/dhcpd.conf.<br>
    2. The grub configure file’s name must comply with a special format, e.g. grub.cfg-01-xx-xx-xx-xx-xx-xx, it starts with "grub.cfg-01-" and ends with board’s MAC address.<br>
    3. The gurb binary and grub.cfg-01-xx-xx-xx-xx-xx-xx files must be placed in the TFTP root directory.<br>
    4. The names and positions of kernel image and dtb must be consistent with the corresponding grub config file.<br>

To get and config grub and grub config files, please refer to [Grub_Manual.md]().
To get kernel and dtb file, please refer to [Readme.md]().

<h2 id="5">Setup NFS server on Ubuntu</h2>

* Install NFS server package
        
    sudo apt-get install nfs-kernel-server nfs-common portmap
                
* Modify configure file /etc/exports for NFS server

    Add following contents at the end of this file.
                      
    </rootnfs> *(rw,sync,no_root_squash)
                                    
    Note: </rootnfs> is your real shared directory of rootfs of distributions for NFS server.

* Uncompress a distribution to </rootnfs>

    To get them, please refer to Distributions_Guider.txt

* Restart NFS service
    
    sudo service nfs-kernel-server restart
