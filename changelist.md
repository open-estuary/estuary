# Change list for Estuary v2.3:
1. Supported D03 board with 50MHz crystal officially
2. Officially supported D02/D03 based on ACPI
3. Linux kernel version upgraded to v4.4.11 (based on Linaro RPB 16.06)
4. Greatly improved stability of D02 SAS disk (UUID, Grub loading)
5. Enabled KVM(ACPI+DTS) support for D02/D03
6. Firstly support BMC load ISO
7. Fixed most major issues found in rc0 & rc1, include but not limited to: UEFI, USB speed, build, distribution, etc
8. Improved build script:
	- Split to multi modules
	- Support build instance
	- Add compatibility with v2.2 and previous build commands
9. Improved website functionalities:
	- Issue tracker anonymous login removed due to security issue
	- Binary download mirror for China to improve the speed of download for China Users
10. Enhanced Caliper functionalities
	- Automatic test report generation in excel and linking of the same in the report
	- Caliper automation script updates
	- Caliper Multi target support from single host
	- Caliper incremental build on multi targets
	- Caliper integration on Jenkins
	- Report re-organization and formatting
11. Improved mini-rootfs to support full functional ssh server/client
12. Enabled LAMP based on docker officially
13. Updated documentation on project and website

# Remained issues:
1. ARM ACPI not fully supported(e.g. ESL/NOR Flash booting, earlycon)
2. HiKey ACPI not supported
