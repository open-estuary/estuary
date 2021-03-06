# Estuary v5.2 Release Information:
[Please click here to go to the download page of this release](http://open-estuary.org/estuary-download/)

```
Release Version         : 5.2
Release Date            : 29-May-2018
   QEMU                 : v2.7.0
   OpenJDK              : v1.8
   Docker               : v1.12.6
   MySQL                : percona-5.7.18
   CI                   : Support NFS/PXE boot testing on D03/D05 board（OS is Ubuntu,CentOS,Debian）
   Armor tools          : include perf, gdb, strace... (totally more than 40 tools for system debug\analyses\diagnosis）
Distributions Supported : Ubuntu 16.04.4,CentOS 7.5,Debian 9,Fedora 26,OpenSuse 42.3,mini-rootfs 1.1
Kernel Version          : 4.16.3
Bootloader Info         : UEFI 3.0 + Grub 2.02-beta3
Boot mode               : PXE, NFS, iBMC Load ISO
Boards Supported        : D03(ARM64), D05(ARM64)
Deployment Methods      : Auto ISO file load, PXE
```

# Introduction:

Estuary is a development version of the whole software solution which target is the ICT market. It is a long term solution and focus on the combination of the high level components. It is expected to be re-based to top tip kernel /distribution versions/applications at the earliest.

# Changelog:

```
1. UEFI
       - Increase the function of Raid card(type 3008,type 3108)
2. OS
       - Upgraded Linux kernel version to v4.16.3
3. Distros
       - Added support for Fedora
       - Added support for OpenSuse
4. Applications
       - Integrated new tool : Malluma
5. Deployment
       - Support standard network installation, ISO installation, and compatible with the original NFS deployment
       - Build scripts support parallel compiling of CentOS, Ubuntu, Debian, Fedora, OpenSuse and common modules
6. Document
       - Updated project documentation (Readme, Grub, deploy_manual,etc)
7. CI/Automation
       - Supported basic CI/Automation for D03 (Build, NFS/PXE Deployment, Some tests)
       - Supported basic CI/Automation for D05 (Build, NFS/PXE Deployment, Some tests)
```
# Known issues:

```
1. Malluma can not install with default path
2. After upgrade the bios,cannot find the option to boot OpenSuse&&Fedora
3. OS can not install by BMC
```
