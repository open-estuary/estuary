# Change list for Estuary v2.3:
1. Officially support D02/D03 based on ACPI
2. Completely compatible for HiKey\D02 and D03 boards
3. Improve boot speed for D03 board
4. Linux kernel version upgraded to v4.4.11 (based on Linaro RPB 16.06)
5. Enabled KVM (ACPI+DTS) support for D02/D03
6. Improved build script:
	- Split to multi modules
	- Support build instance
	- Avoid to repeat uncessary building
	- Unified prebuild files
7. CI system: ~20% test cases will run in CI system
8. Enable RancherOS distribution
9. Improved mini-rootfs to support full functional ssh server/client
10. Enable LAMP based on docker officially
11. Enable and validate ODP officially
12. Chagne issue tracker system on website
13. Provide mail list feature on website
14. Improved all documents, including project documents and open-estuary.org
15. Fixed most issues found in RPB 16.06 rc stage (UEFI, ACPI, KVM, Grub, SAS, etc)
16. Enhanced Caliper functionalities
	- Unixbench tool integrated
	- Stress-ng tool integrated
	- CPU benchmarking functionality of sysbench added
	- Various bug fixes

# Remained issues:
1. Website access speed need to be improved
2. HiKey ACPI not supported
3. OpenEmbedded distribution not enabled
4. ARM ACPI not fully supported(e.g. ESL/NOR Flash booting, earlycon)
