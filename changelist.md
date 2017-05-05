# Change list for Estuary v3.1:
1. UEFI
	- Added HiKey support in UEFI
2. OS
	- Upgraded Linux kernel version to v4.9.20
	- Supported HiKey with v4.9.20 kernel
3. Distros
	- Fixed minirootfs devramfs confliction with mdev
	- Added support for OpenEmbedded
	- Added support for RancherOS
4. Applications
	- Added OpenStack Newton initial support
	- Enabled HHVM for ARM64
	- Enabled MongoDB docker image
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

# Remained issues:
1. Armor utilities are not fully support
