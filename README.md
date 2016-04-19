* [Introduction](#1)
* [Obtain and build](#2)
* [Deployment](#3)
* [Prebuilt binaries](#4)
* [Contact us](#5)
* [Change list compared with previous version](#6)
* [CPPYRIGHT](#7)
* [TODO](#8)

 <h2 id="1">Introduction</h2>
=================
 These are the release notes for the Estuary new version. Please read them carefully, as they tell you what this is all about, explain how to get, build, and run it.

  Estuary is a totally open source version of the whole software solution which target is the ICT market. It is a long term solution and focus on the combination of the high level components. And It is expected to be rebased from the newest version of the community quickly.
  More detail information about Estuary, please refer to http://open-estuary.org/estuary.

<h2 id="2"> Obtain and build</h2>
================
  To obtain and build system, please refer to http://open-estuary.org/estuary-user-manual/.

<h2 id="3"> Deployment</h2>
================
  More detail information about deployment, please refer to documents in "<project root>/build/<platform>/doc" directory after building.
  
  Detail description about what is in `<project root>/build/<platform>/doc`please refer to https://github.com/open-estuary/estuary/tree/master/doc

<h2 id="4"> Prebuilt binaries</h2>
================
To use prebuilt binaries directly, please refer to http://download.open-estuary.org/.

NOTE:
  
 `releases` directory is formal version which all binary files located in.
  
 `pre-releases` directory is nonformal version like Estuary 2.2 rc<number> which all binary files located in. 

 <h2 id="5"> Contact us</h2>
================
About the technical support, you can contact us by http://open-estuary.org/contact-us.

<h2 id="6"> Change list compared with previous version</h2>
================
Please refer to [changelist.md](https://github.com/open-estuary/estuary/blob/master/README.md) in this project.

<h2 id="7"> COPYRIGHT</h2>

==================
There is a homepage at http://download.open-estuary.org/ for using prebuilt binaries directly.

 **prebuilt binaries for D01**

  UEFI_D01.fd      //UEFI_D01.fd is the UEFI bios for D01 platform.

 .text and .monitor  // boot wrapper files to take responsible of switching into HYP mode.

  grubarm32.efi      //grubarm32.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.
 
  grub.cfg          // grub.cfg is used by grubaa64.efi to config boot options.
 
  zImage           // zImageis the compressed kernel executable program.
 
  hip04-d01.dtb    // hip04-d01.dtb is the device tree binary.
 
 .kernel           //.kernel is the file combining zImage and hip04-d01.dtb.
 
 .filesystem      //.filesystem is a special rootfs for D01 booting from NORFLASH.

 **prebuilt binaries for D02**

 UEFI_D02.fd       //UEFI_D02.fd is the UEFI bios for D02 platform.

 CH02TEVBC_V03.bin //CH02TEVBC_V03.bin is the CPLD binary for D02 board.

 grubaa64.efi  //grubaa64.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.

 grub.cfg      //grub.cfg is used by grubaa64.efi to config boot options.

 Image_D02     //Image is the kernel executable program for D02.

 hip05-d02.dtb //hip05-d02.dtbis the device tree binary.
 
 **prebuilt binaries for D03**

UEFI_D03.fd    //UEFI_D03.fd is the UEFI bios for D03 platform.

CH02TEVBC_V03.bin //CH02TEVBC_V03.bin is the CPLD binary for D03 board, the others are binaries for trust firmware.

grubaa64.efi  //grubaa64.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.

grub.cfg      //grub.cfg is used by grubaa64.efi to config boot options.

Image_D03  //Image_D03 is the kernel executable program.

hip06-d03.dtb //hip06-d03.dtb is the device tree binary.

 **prebuilt binaries for HiKey**

l-loader.bin //l-loader.binused to switch from aarch32 to aarch64 and boot.

fip.bin   // firmware package.

ptable-linux.img // partition tables for Linux images. 

Image_HiKey //Image_HiKey is the kernel executable program.

hi6220-hikey.dtb //hi6220-hikey.dtb is the device tree binary.

grubaa64.efi  //grubaa64.efi is used to load kernel image and dtb files from SATA, SAS, USB Disk, or NFS into RAM and start the kernel.

grub.cfg      //grub.cfg is used by grubaa64.efi to config boot options.

**Copyright**: (c) 2016, Hisilicon Limited
     
**License**: GPLv2+

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.



<h2 id="8"> TODO</h2>
================
  Further more platforms will be supported in the esturay.
  More detail information about estuary, please refer to
  http://open-estuary.org

