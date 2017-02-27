* [Introduction](#1)
* [Grub config file](#2)
* [files structure bootable partition](#3)
* [FAQ](#4)

## <a name="1">Introduction</a>

Grub is a kind of boot loader to load kernel into RAM and run it.

After rebooting board every time, the UEFI will firstly try to download the grub binary and run it firstly.

Then grub binary will load the kernel and start it with cmdline and dtb file according to the configurations in `grub.cfg`.

They include:
```bash
grubaa64.efi    # The grub binary executable program for ARM64 architecture
grubarm32.efi   # The grub binary executable program for ARM32 architecture
grub.cfg        # The grub config file which will be used by grub binary
```
Where to get them, please refer to Readme.txt.

## <a name="2">Grub config file</a>

You can edit a `grub.cfg` file to support various boot mode or multi boot partitions, follow is an example.

You should change them acoording to your real local environment.

```bash
#
# Sample GRUB configuration file
#

# Boot automatically after 0 secs.
set timeout=5

# By default, boot the Euler/Linux
set default=d05_centos_nfs_acpi

# Booting from PXE with mini rootfs
menuentry "D05 minilinux PXE(CONSOLE)" --id d05_minilinux_pxe_console {
    set root=(tftp,192.168.1.107)
    linux /Image pcie_aspm=off pci=pcie_bus_perf
    initrd /mini-rootfs-arm64.cpio.gz
}

menuentry "D05 minilinux PXE(VGA)" --id d05_minilinux_pxe_vga {
    set root=(tftp,192.168.1.107)
    linux /Image pcie_aspm=off pci=pcie_bus_perf console=tty0
    initrd /mini-rootfs-arm64.cpio.gz
}
# Booting from Centos NFS
menuentry "D05 Centos NFS(CONSOLE)" --id d05_centos_nfs_console {
    set root=(tftp,192.168.1.107)
    linux /Image pcie_aspm=off pci=pcie_bus_perf  rootwait  root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/`<user>`/rootfs_ubuntu64,nfsvers=3 ip=dhcp
}

menuentry "D05 Centos NFS(VGA)" --id d05_centos_nfs_vga {
    set root=(tftp,192.168.1.107)
    linux /Image pcie_aspm=off pci=pcie_bus_perf  rootwait  root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/`<user>`/rootfs_ubuntu64,nfsvers=3 ip=dhcp console=tty0
}
# Booting from Centos SATA
menuentry "D05 Centos SATA(CONSOLE)" --id d05_centos_sata_console{
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image pcie_aspm=off pci=pcie_bus_perf rootwait root=PARTUUID=<PARTUUID> rw
}

menuentry "D05 Centos SATA(VGA)" --id d05_centos_sata_vga{
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image pcie_aspm=off pci=pcie_bus_perf rootwait root=PARTUUID=<PARTUUID> rw console=tty0
}
# Booting from PXE with mini rootfs
menuentry "D03 minilinux PXE(CONSOLE)" --id d03_minilinux_pxe_console {
    set root=(tftp,192.168.1.107)
    linux /Image rdinit=/init pci=pcie_bus_perf console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8
    initrd /mini-rootfs-arm64.cpio.gz
}

menuentry "D03 minilinux PXE(VGA)" --id d03_minilinux_pxe_vga {
    set root=(tftp,192.168.1.107)
    linux /Image pci=pcie_bus_perf console=tty0
    initrd /mini-rootfs-arm64.cpio.gz
}
# Booting from Centos NFS
menuentry "D03 Ubuntu NFS(CONSOLE)" --id d03_ubuntu_nfs_console {
    set root=(tftp,192.168.1.107)
    linux /Image pci=pcie_bus_perf rootwait console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8 root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/`<user>`/ubuntu,nfsvers=3 ip=dhcp

}

menuentry "D03 Ubuntu NFS(VGA)" --id d03_ubuntu_nfs_vga {
    set root=(tftp,192.168.1.107)
    linux /Image pci=pcie_bus_perf rootwait console=tty0 root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/`<user>`/ubuntu,nfsvers=3 ip=dhcp

}
# Booting from Centos SATA
menuentry "D03 Ubuntu SATA(CONSOLE)" --id d03_ubuntu_sata_console {
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image pci=pcie_bus_perf rootwait root=PARTUUID=<PARTUUID> rw console=ttyS0,115200 earlycon=hisilpcuart,mmio,0xa01b0000,0,0x2f8
}

menuentry "D03 Ubuntu SATA(VGA)" --id d03_ubuntu_sata_vga {
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image  pci=pcie_bus_perf rootwait root=PARTUUID=<PARTUUID> rw console=tty0
}
# Booting from PXE with mini rootfs
menuentry "minilinux_overdrive" --id minilinux_overdrive {
    set root=(tftp,192.168.1.107)
    linux /Image  plymouth.enable=0 console=ttyAMA0,115200n8 raid=noautodetect
    initrd /mini-rootfs-arm64.cpio.gz
}

# Booting from Centos NFS
menuentry "Centos Overdrive NFS" --id ubuntu_overdrive_nfs {
    set root=(tftp,192.168.1.107)
    linux /Image rdinit=/init raid=noautodetect plymouth.enable=0 console=ttyAMA0,115200n8 root=/dev/nfs rw nfsroot=192.168.1.107:/home/hisilicon/ftp/<user>/Centos,nfsvers=3 ip=dhcp
}

# Booting from Centos SATA
menuentry "Centos Overdrive SATA" --id centos_overdrive_sata {
    search --no-floppy --fs-uuid --set=root <UUID>
    linux /Image root=PARTUUID=<PARTUUID> rootfstype=ext4 rw  rdinit=/init raid=noautodetect plymouth.enable=0 console=ttyAMA0,115200n8
}

# Booting from eMMC with mini rootfs
menuentry "HiKey minilinux eMMC" --id HiKey_minilinux_eMMC {
    linux /Image_HiKey rdinit=/init console=tty0 console=ttyAMA3,115200 rootwait rw loglevel=8 efi=noruntime
    initrd /mini-rootfs.cpio.gz
    devicetree /hi6220-hikey.dtb
}

# Booting from eMMC with Ubuntu
menuentry "HiKey Ubuntu eMMC" --id HiKey_Ubuntu_eMMC {
    linux /Image_HiKey rdinit=/init console=tty0 console=ttyAMA3,115200 root=/dev/mmcblk0p9 rootwait rw loglevel=8 efi=noruntime
    devicetree /hi6220-hikey.dtb
}

# Booting from SD card with Ubuntu
menuentry "HiKey Ubuntu SD card" --id HiKey_Ubuntu_SD {
    linux /Image_HiKey rdinit=/init console=tty0 console=ttyAMA3,115200 root=/dev/mmcblk1p1 rootwait rw loglevel=8 efi=noruntime
    devicetree /hi6220-hikey.dtb
}

menuentry 'HiKey Fastboot mode' {
    chainloader (hd0,gpt6)/fastboot.efi
}

```
Note: You should only select the parts from above sample which are suitable for your real situation.

## <a name="3">files structure bootable partition</a>

Normally they are placed into bootable partition as following structure.
```bash
sdx-------EFI
|       |
|       GRUB2------grubaa64.efi   # grub binary file only for ARM64 architecture
|
|-------------grub.cfg            # grub config file
|
|-------------Image               # kernel Image file only for D02 platform

```
Note: In case of booting by PXE mode:  
1. The grub binary and `grub.cfg` files must be placed in the TFTP root directory.  
2. The names and positions of kernel image and dtb must be consistent with the corresponding grub config file.  
3. The grub binary name (`grubxxx.efi`) must be consistent with the "filename" in `/etc/dhcp/dhcpd.conf`, for more detail, please refer to [Setup_PXE_Env_on_Host.md](https://github.com/open-estuary/estuary/blob/master/doc/Setup_PXE_Env_on_Host.4All.md)  
4. If you use D02 board, you should not input DTB in the `grub.cfg` but you must flash the DTB file into spiflash to avoid a known Mac address duplicate issue.

You can get more information from the `Deploy_Manual.md` guide.

## <a name="4">FAQ</a>

If you want to modify `grub.cfg` command line temporarily. Type "E" key into grub modification menu. You will face problem that the "backspace" key not woking properly. You can fix backspace issue by changing terminal emulator's configuration.

**For gnome-terminal**: Open "Edit" menu, select "Profile preferences".  
In "Compatibility" page, select "Control-H" in "Backspace key generates" listbox.  
**For Xterm**: press Ctrl key and left botton of mouse, and toggle on "Backarrow key (BS/DEL)" in mainMenu.
