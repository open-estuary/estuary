* [Introduction](#1)
* [List of Tools](#2)

<h2 id="1">Introduction</h2>

This document presents the basic information of the supported Armor tools. 

<h2 id="2">List of Tools</h2>

1. Perf integrated with LLC, MN and DDR

   a. Integrated LLC statistics registers access via perf, including DDR counter information. 
   
   b. Support counter overflow interrupt support for LLC counters. 
   
   c. Register Read/Get interface from Linux Kernel for LLC and Bus Registers for P660.
   
   d. LLC statistics registers integration to perf for P660.

2. strace : trace system calls and signals
 
   strace is a diagnostic, debugging and instructional Linux user space utility. 
   
   It is used to monitor interactions between processes and the Linux kernel, 
   
   which include system calls, signal deliveries, and changes of process state. 


3. ltrace : library call tracer.
   ltrace intercepts and records the dynamic library calls which are called by the executed process and 
   the signals which are received by that process.
   It can also intercept and print the system calls executed by the program.

4. netstat : 
   netstat prints network connections, routing tables, interface statistics, masquerade connections, and multicast memberships.

5. sar : Collect, report, or save system activity information.

6. top : display Linux tasks. 
   top shows how much CPU processing power and memory are being used, as well as other information about the running processes.

7. pidstat: Report statistics for Linux tasks.
   pidstat command is used for monitoring individual tasks currently being managed by the Linux kernel.
   pidstat writes to standard output activities for every task selected with option -p or 
   for every task managed by the Linux kernel if option -p ALL has been used.  

8. vmstat : Report virtual memory statistics.
   vmstat reports information about processes, memory, paging, block IO, traps, and CPU activity.

9. ftrace: is the Linux kernel internal tracer that was included in the Linux kernel in 2.6.27.
   ftrace supports function tracing, latency tracing, event tracing etc.

10. iostat :  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS). 

11. tcpdump:dump traffic on a network.
    Tcpdump prints out the headers of packets on a network interface. 
    It can also be run with the -w flag, which causes it to save the packet data to a file for later analysis, 
    and with the -r flag, which causes it to read from a saved packet file rather than to read packets from a network interface. 

12. ethtool :  query or control network driver and hardware settings, particularly for wired Ethernet devices. 

13. swapon, swapoff : enable/disable devices and files for paging and swapping, 
    used to specify devices on which paging and swapping are to take place. 

14. kdump/kexec :
    Kdump is a kexec based crash dumping mechanism for Linux.
    Kexec is a mechanism of the Linux kernel that allows "live" booting of a new kernel "over" the currently running kernel.
    Note: kdump/kexec is not verified for D02. The user space kexec-tools and kdump-tools components may need to build for arm64.  

15. gdb: gnu debugger
    Gdb supports many features including the following,
    a. put break points, watch points
    b. single stepping
    c. disassemble
    d. printing value of variables, registers.
    e. call traces 
16. iptables : administration tool for IPv4 packet filtering and NAT.
    Iptables is used to set up, maintain, and inspect the tables of IP packet filter rules in the Linux kernel.

17. mkfs : build a Linux file system on a device, usually a hard disk partition.

18. mount : mount a file system. 

19. du : estimates the file space usage.
    The du summarize he disk usage of each file, recursively for directories.     

20. df : report file system disk space usage.
    The df displays the amount of disk space available on the file system containing each filename argument.
    If no file system name is given, the spac available on all currently mounted file systems are shown.

21. dmidecode : DMI table decoder
    dmidecode tool dump DMI(SMBIOS) table contents in a human readable format. 
    This table contains description of the system's hardware components, other information such as
    serial numbers and BIOs version.   

22. fsck : is used to check and optionally repair a Linux file system.

23. lscpu : display information about the CPU architecture. 

24. lspci : List all PCI devices. 
    This utility display information about the PCI buses in the system and devices connected to them. 

25. setpci : utility for querying and configuring PCI devices.  

26. tail : this utility outputs the last part of the files. 

27. grep : tool searches the named input files for lines contains a match to the given pattern.   

28. awk : pattern scanning and processing language.

29. sed : is a stream editor, used to perform basic text transformations.

30. dstat: versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.
   dstat allows you to view all of your system resources instantly, 
   for example you can compare disk usage in combination with interrupts from your IDE controller, or 
   compare the network bandwidth numbers directly with the disk throughput (in the same interval). 

31. procps: procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.
   The procps package includes the programs ps, top, vmstat, w, kill, free, slabtop, and skill.

32. tiptop: display hardware performance counters for Linux tasks.
   Some of the features of tiptop are 
   - No root privilege needed
   - No patch to OS
   - Any event supported by the hardware such as 
   - some predefined: instructions, cycles, LLC misses (easy)
   - any hardware supported event (slightly harder)
   - two running modes - Live mode and batch mode.
33. iotop: simple top-like I/O monitor.
   iotop watches I/O usage information output by the Linux kernel and 
   displays a table of current I/O usage by processes or threads on the system.

34. blktrace:  generate traces of the i/o traffic on block devices.
    The blktrace utility extracts event traces from the kernel.
    - blktrace receives data from the kernel in buffers passed up through the debug file system (relay).
       Each device being traced has a file created in the mounted directory for the debugfs, which defaults to /sys/kernel/debug 
    - blktrace defaults to collecting all events that can be traced. To limit the events being captured, 
       you can specify one or more filter masks via the -a option.

35. nicstat: Show Network Interface Card Statistics.
   nicstat prints out network statistics for all network interface cards (NICs), 
   including packets, kilobytes per second, average packet sizes and more. 

36. lldptool: manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

37. oprofile: a system-wide profiler, capable of profiling all running code at low overhead.
   Supported features are
   - Unobtrusive, no special recompilations, wrapper libraries or the like are necessary.  
   - System-wide profiling
   - Single process profiling
   - Event counting
   - Performance counter support
   - Call-graph support
   - Low overhead
   - Post-profile analysis
   - System support 

38. latencytop: a tool for developers to visualize system latencies.
39. kgdb: Kernel gnu debugger.
    kgdb is one of the debugger front ends of the kernel which interface to the debug core.
    Kgdb is intended to be used as a source level debugger for the Linux kernel. It is used along with gdb to debug a Linux kernel.
    The expectation is that gdb can be used to "break in" to the kernel to inspect memory, variables and look through call stack information 
    similar to the way an application developer would use gdb to debug an application.It is possible to place breakpoints in kernel code and 
    perform some limited execution stepping.

40. kdb: kernel debugger.
    kdb is one of the debugger front ends of the kernel which interface to the debug core.
    Kdb is shell-style interface which you can use on a system console with a keyboard or serial console. 
    kdb can be used to inspect memory, registers, process lists, dmesg, and even set breakpoints to stop in a certain location. 
    Kdb is not a source level debugger, although you can set breakpoints and execute some basic kernel run control.
    Kdb is mainly aimed at doing some analysis to aid in development or diagnosing kernel problems.

41. systemtap: SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system. 
    SystemTap (stap) is a scripting language and tool for dynamically instrumenting running production Linux kernel-based operating systems. 
    System administrators can use SystemTap to extract, filter and summarize data in order to enable diagnosis of complex performance or functional problems.

42. kprobes: Kprobes enables you to dynamically break into any kernel routine and 
    collect debugging and performance information non-disruptively.
    Kernel Dynamic Probes (Kprobes) provides a lightweight interface for kernel modules to implant probes and register corresponding probe handlers. 
    A probe is an automated breakpoint that is implanted dynamically in executing (kernel-space) modules without the need to modify their underlying source.

43. crash : Analyze Linux crash dump data or a live system.
    Crash is a tool for interactively analyzing the state of the Linux system while it is running, or after a kernel crash has occurred 
    and a core dump has been created by the netdump, diskdump, LKCD, kdump, xendump or kvmdump facilities.

44. memwatch: A memory leak detection tool. memwatch source files to be integrated and build as part of the code to be tested.

45. LTTNG: Linux Trace Toolkit Next Generation. LTTng consists of kernel modules (for Linux kernel tracing) and dynamically loaded libraries (for user application and library tracing). 
    It is controlled by a session daemon, which receives commands from a command line interface.

46. powertop: program help to analyse the power consumption.

47) slabtop: display kernel slab cache information.

48. ktap: script based dynamic tracing tool for Linux.

49. gprof: performance analysis tool.

50. valgrind: instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc.

51. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.
    Sample scripts are available online.

52. packETHcli - packETHcli is the command line packet generator tool for ethernet. 
    It allows you to create and send any possible packet or sequence of packets on the ethernet link.

