# Change list for Estuary v2.3:
1. Officially support D02/D03 based on ACPI
2. Linux kernel version upgraded to v4.4.11 (based on Linaro RPB 16.06)
3. Greatly improved stability of D02 SAS disk
4. Enabled KVM (ACPI+DTS) support for D02/D03
5. Improved build script:
	- Split to multi modules
	- Support build instance
	- Avoid to repeat uncessary building
	- Unified prebuild files
6. CI system: ~20% test cases will run in CI system
7. Enable RancherOS distribution
8. Improved mini-rootfs to support full functional ssh server/client
9. Enable LAMP based on docker officially
10. Enable and validate ODP officially
11. Chagne issue tracker system on website
12. Provide mail list feature on website
13. Improved all documents, including project documents and open-estuary.org
14. Fixed most issues found in RPB 16.06 rc and pre-test stage (UEFI, ACPI, KVM, Grub, SAS, PCIe, Ethernet, etc)
15. Enhanced Caliper functionalities
	- Unixbench tool integrated
	- Stress-ng tool integrated
	- CPU benchmarking functionality of sysbench added
	- Various bug fixes

# Remained issues:
1. Website access speed need to be improved
2. HiKey ACPI not supported
3. OpenEmbedded distribution not enabled
4. ARM ACPI not fully supported(e.g. ESL/NOR Flash booting, earlycon)
