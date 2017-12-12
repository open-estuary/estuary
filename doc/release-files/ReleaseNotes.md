# Estuary v5.0 Release Information:
[Please click here to go to the download page of this release](http://open-estuary.org/estuary-download/)

```
Release Version         : 5.0
Release Date            : 12-Dec-2017
Openstack               : Support Openstack Newton version which based on Linaro ERP1612
   QEMU                 : v2.7.0
   OpenJDK              : v1.8
   Docker               : v1.12.6
   MySQL                : percona-5.7.18
   CI                   : Support NFS/SAS boot testing on D03/D05 board（OS is Ubuntu or CentOS）
   Armor tools          : include perf, gdb, strace... (totally more than 40 tools for system debug\analyses\diagnosis）
Distributions Supported : Ubuntu 16.04,CentOS 7.4.1708,Debian 8.9,mini-rootfs 1.1
Kernel Version          : 4.12.0
Bootloader Info         : UEFI 3.0 + Grub 2.02-beta3
   Boot mode            : PXE, NFS, iBMC Load ISO,IPMI
Boards Supported        : D03(ARM64), D05(ARM64)
Deployment Methods      : Auto ISO file, PXE
```

# Introduction:

Estuary is a development version of the whole software solution which target is the ICT market. It is a long term solution and focus on the combination of the high level components. It is expected to be re-based to top tip kernel /distribution versions/applications at the earliest.

# Changelog:

```
1. UEFI
	- D05 setup menu update(press F2 to enter menu)
        - Support Perf: ddrc,l3c,nm,pmu
        - Add PXM: PCIE,HNS,SAS
2. OS
	- Upgraded Linux kernel version to v4.12.0
3. Distros
	- Added support for CentOS
	- Added support for Debian
	- Added support for Ubuntu
4. Applications
	- Supported standard respository to install packages on CentOS and Ubuntu platform
	- Integrated E-Commerce solution based on Spring Cloud Micro-Service
        - Integrated new application packages
	- Enhance performance tools including perf,bcc,and so on
5. Deployment
	- Fixed various BMC load ISO bugs (distro selection, waiting time)
	- Sort hard disk list in alphabetic order
	- Improved distribution generation speed when building
6. Document
	- Updated project documentation (Readme, Grub, etc)
	- Updated applications user manual (Redis, PostgreSQL, MySQL, MongoDB, etc)
7. CI/Automation
	- Supported basic CI/Automation for D03 (Build, NFS/Hard disk Deployment, Some tests)
	- Supported basic  CI/Automation for D05 (Build, NFS/Hard disk Deployment, Some tests)
```
# Known issues:

```
1. Estuary Debian system failed to config&check TSO
2. lscpu display inaccurate information on ARM platform
```
