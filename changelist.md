# Change list for Estuary v2.3rc1:
1. Supported D03 board with 50MHz crystal officially
2. Firstly support BMC load ISO (Engineering mode)
3. Improved website functionalities:
	- Issue tracker anonymous login removed due to security issue
	- Binary download from China enabled
	- New collaboration feature added
4. Improved build script:
	- Add compatibility with v2.2 and previous build commands
	- Use release binaries configuration file in ftp server now
	- Various bug fixes
5. Fix packages/app building issues found in v2.3rc0
6. Deployed CI System officially
	- OpenLab 2 CI deployed
	- Regular CI test report email supported
	- Added Fedora/CentOS virtualization test case support
7. Upgraded Ubuntu ARM64 distro to 16.04
8. Support running QEMU with Estuary image
9. Updated documentation on project and website

# Remained issues:
1. OpenEmbedded distribution not enabled
2. HiKey ACPI not supported
3. ARM ACPI not fully supported(e.g. ESL/NOR Flash booting, earlycon)
