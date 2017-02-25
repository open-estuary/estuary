# Change list for Estuary v3.0:
1. Hardware boards support
	- Supported D05 board(Hi1616) officially
	- Supported D03/D05 boards based on ACPI
	- Added basic support for AMD Overdrive board
2. UEFI
	- Upgraded UEFI components to Linaro ERP 16.12
	- Added support for BMC boot device ipmi protocol
	- Fixed 2TB+ disk support bug
3. OS
	- Upgraded Linux kernel version to v4.9.0 (based on Linaro ERP 16.12)
	- Removed DT(Device Tree) support all boards
	- Added support for more PCIe devices in D03/D05: SSD, RAID(LSI 2308/3008/3108), Intel 82599 NIC
	- Supported CentOS native build for open-estuary source
	- Supported NUMA on D05 board officially
	- Support Perf L3 cache / MN features
4. Distros
	- Improved mini-rootfs for better Lmbench stream performance
	- Upgraded CentOS AltArch to 7.3
	- Upgraded Ubuntu to 16.04
	- Fixed DHCP boot conflict issue when passing ip=dhcp in kernel command line
5. Applications
	- Upgraded QEMU to v2.8.0
	- Enabled OpenJDK 1.8
	- Enabled MySQL(Percona Server) docker image
	- Enabled Redis docker image
	- Enabled PostgreSQL docker image
6. Deployment
	- Supported USB Flash disk script-type installation
	- Supported BMC load ISO both by web or VGA monitor
	- Supported multiple distros in USB install Disk method
7. Website
	- News Scroller added
	- New Collaboration Feature added
8. Document
	- Added D05 documents and update all project documents

# Remained issues:
	- Armor utilities are not fully support
