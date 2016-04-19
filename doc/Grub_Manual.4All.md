
* [Grub manual](#1)
* [Grub config file](#2)
* [files structure bootable partition](#3)

<h2 id="1">Introduction</h2>

Grub is a kind of boot loader to load kernel\OS into RAM and run it.

After rebooting board every time, the UEFI will firstly try to download the grub binary and run it firstly.

Then grub binary will load the kernel and start it with cmdline and dtb file according to the configurations in grub.cfg. 

They include:
```shell
    grubaa64.efi    # The grub binary executable program for ARM64 architecture
    grubarm32.efi   # The grub binary executable program for ARM32 architecture
    grub.cfg        # The grub config file which will be used by grub binary
```

Where to get them, please refer to Readme.txt.

<h2 id="2">Grub config file</h2>

You can edit a grub.cfg file to support various boot mode or multi boot partitions, follow is an example.

You should change them acoording to your real local environment.

```shell
#
    # Sample GRUB configuration file
    #
    
    # Boot automatically after 0 secs.
    set timeout=5
    
    # By default, boot the Euler/Linux
    set default=d03_ubuntu_hd
     
    # Booting from PXE with mini rootfs
    menuentry "D03-test-minilinux" --id d03-minilinux {
       set root=(tftp,192.168.1.107)
       linux /Image_D03 rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8
       initrd /mini-rootfs-arm64.cpio.gz
    }

   # Booting from NFS with Ubuntu rootfs
   menuentry "D03-nfs" --id d03-NFS {
       set root=(tftp,192.168.1.107)
       linux /Image_D03 rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8  root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/user/ubuntu64 ip=dhcp
    }

   # Booting from disk with ubuntu rootfs
   menuentry "D03 Ubuntu HD" --id d03_ubuntu_hd {
        set root=(hd0,gpt1)
        linux /Image_D03 rdinit=/init root=/dev/sda2 rootfstype=ext4 rw rdinit=/init console=ttyS1,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8  ip=dhcp
   }

    # Booting from eMMC with mini rootfs
    menuentry "Hikey minilinux eMMC" --id HiKey_minilinux_eMMC {
        set root=(hd0,gpt6)
	linux /Image_Hikey rdinit=/init console=tty0 console=ttyAMA3,115200 rootwait rw loglevel=8 efi=noruntime
        initrd /mini-rootfs.cpio.gz
        devicetree /hi6220-hikey.dtb
    }
    
    # Booting from eMMC with Ubuntu
    menuentry "Hikey Ubuntu eMMC" --id HiKey_Ubuntu_eMMC {
        set root=(hd0,gpt6)
	linux /Image_Hikey rdinit=/init console=tty0 console=ttyAMA3,115200 root=/dev/mmcblk0p7 rootwait rw loglevel=8 efi=noruntime
        devicetree /hi6220-hikey.dtb
    }
    
    # Booting from SD card with Ubuntu
    menuentry "Hikey Ubuntu SD card" --id HiKey_Ubuntu_SD {
        set root=(hd0,gpt6)
	linux /Image_Hikey rdinit=/init console=tty0 console=ttyAMA3,115200 root=/dev/mmcblk1p1 rootwait rw loglevel=8 efi=noruntime
        devicetree /hi6220-hikey.dtb
    }

    menuentry 'HiKey Fastboot mode' {
        set root=(hd0,gpt6)
        chainloader (hd0,gpt6)/fastboot.efi
    }    

    # Booting from PXE with mini rootfs
    menuentry "D02 minilinux PXE" --id d02_minilinux_pxe {
        set root=(tftp,192.168.1.107)
        linux /Image_D02 rdinit=/init crashkernel=256M@32M console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp
        initrd /mini-rootfs.cpio.gz
    }
    
    # Booting from NFS with Ubuntu rootfs
    menuentry "D02 Ubuntu NFS" --id d02_ubuntu_nfs {
        set root=(tftp,192.168.1.107)
        linux /Image_D02 rdinit=/init console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 root=/dev/nfs rw nfsroot=192.168.1.107:/home/ftp/user/rootfs_ubuntu64 ip=dhcp
    }
    
    # Booting from SATA with Ubuntu rootfs in /dev/sda2
    menuentry "D02 Ubuntu SATA" --id d02_ubuntu_sata {
        set root=(hd1,gpt1)
        linux /Image_D02 rdinit=/init root=/dev/sda2 rootfstype=ext4 rw console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp
    }

    # Booting from SATA with Fedora rootfs in /dev/sda3
    menuentry "D02 Fedora SATA" --id d02_fedora_sata {
        set root=(hd1,gpt1)
        linux /Image_D02 rdinit=/init root=/dev/sda3 rootfstype=ext4 rw console=ttyS0,115200 earlycon=uart8250,mmio32,0x80300000 ip=dhcp
    }

    # Booting from Norflash with mini rootfs
    menuentry "D01 minilinux Norflash" --id d01_minilinux_nor {
        devicetree (hd0,msdos1)/hip04-d01.dtb
        linux (hd0,msdos1)/zImage_D01 console=ttyS0,115200 earlyprintk initrd=0x10d00000,0x1800000 rdinit=/linuxrc ip=dhcp
    }

    # Booting from SATA with Ubuntu rootfs in /dev/sda4
    menuentry "D01 Ubuntu SATA" --id d01_ubuntu_sata {
        devicetree (hd0,msdos1)/hip04-d01.dtb
        linux (hd0,msdos1)/zImage_D01 console=ttyS0,115200 earlyprintk root=/dev/sda4 rootfstype=ext4 rw ip=dhcp
    }

    # Booting from SATA with OpenSuse rootfs in /dev/sda5
    menuentry "D01 OpenSuse" --id d01_opensuse_sata {
        devicetree (hd0,msdos1)/hip04-d01.dtb
        linux (hd0,msdos1)/zImage_D01 console=ttyS0,115200 earlyprintk root=/dev/sda5 rootfstype=ext4 rw ip=dhcp
    }

    # Booting from NFS with Ubuntu rootfs
    menuentry "D01 Ubuntu NFS" --id d01_ubuntu_nfs {
        devicetree (hd0,msdos1)/hip04-d01.dtb
        linux (hd0,msdos1)/zImage_D01 console=ttyS0,115200 earlyprintk rootfstype=nfsroot root=/dev/nfs rw nfsroot=192.168.1.107:/home/ftp/user/rootfs_ubuntu32 ip=dhcp 
    }
```
Note: You should only select the parts from above sample which are suitable for your real situation.

<h2 id="3">files structure bootable partition</h2>

Normally they are placed into bootable partition as following structure.
```
-------EFI
|       |
|       GRUB2------grubaa64.efi   # grub binary file only for ARM64 architecture
|           |
|           |
|            ------grubarm32.efi  # grub binary file only for ARM32 architecture
|
|-------------grub.cfg          # grub config file
|
|-------------Image_D02         # kernel Image file only for D02 platform
|
|-------------zImage_D01        # kernel zImage file only for D01 platform
|
|-------------hip04-d01.dtb     # kernel data tree binary file only for D01 platform
```
Note: In case of booting by PXE mode:

   1. The gurb binary and grub.cfg files must be placed in the TFTP root directory.

   2. The names and positions of kernel image and dtb must be consistent with the corresponding grub config file.

   3. The grub binary name (grubxxx.efi) must be consistent with the "filename" in /etc/dhcp/dhcpd.conf, for more detail, please refer to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.md).

   4. If you use D02 board, you should not input DTB in the grub.cfg but you must flash the DTB file into spiflash to avoid a known Mac address duplicate issue.

  You can get more information from the Deploy_Manual.txt guide.
  
