* [Introduction](#1)
* [List of supported Tools in Armor](#2)
 * [Ubuntu](#2.1)
 * [Fedora](#2.2)
 * [OpenSuse](#2.3)
 * [Debian](#2.4)
 * [CentOS](#2.5)
 * [Miscelleneous Tools](#2.6)
 
<h2 id="1">Introduction</h2>
 
 This document presents the information of the supported Armor tools on D02 and Open-Estuary. 
 
<h2 id="2">List of supported Tools in Armor</h2>

<h3 id="2.1">Ubuntu</h3>
 
 1. Perf integrated with LLC, MN and DDR
 
   version - 3.19.8
   
 2. strace - trace system calls and signals
 
    version - 4.8
 3. ltrace - library call tracer.
 
   version - 0.7.3
   
 4. netstat   
 
   version - 1.42
   
 5. top - display Linux tasks. 
 
   version - 3.3.9 
   
 6. pidstat - Report statistics for Linux tasks.
 
   version - 11.0.1 
   
 7. vmstat - Report virtual memory statistics.
 
   version - 3.3.9
   
 8. ftrace
 
 9. iostat -  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS). 
 
    version - 11.0.1

 10. tcpdump - dump traffic on a network.

     version - 4.6.2
    
 11. ethtool - query or control network driver and hardware settings, particularly for wired Ethernet devices. 

    version - 3.16    
    
 12. swapon, swapoff : enable/disable devices and files for paging and swapping. 

    version - 2.25.2   
    
 13. gdb: gnu debugger

    version - 7.9
   
 14. iptables - administration tool for IPv4 packet filtering and NAT.

    version - 1.4.21
    
 15. dmidecode - DMI table decoder

    version - 2.12
   
 16. fsck - is used to check and optionally repair a Linux file system.

   version - 2.25.2
    
 17. lscpu - display information about the CPU architecture. 

    version - 2.25.2 
   
 18. lspci - List all PCI devices. 

    version - 3.2.1 
   
 19. setpci - utility for querying and configuring PCI devices.  

   version - 3.2.1 
   
 20. dstat - versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.

    version - 0.7.2
   
 21. procps - procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.

    version - 3.3.9
   
 22. tiptop - display hardware performance counters for Linux tasks.

    version - 2.3
   
 23. iotop - simple top-like I/O monitor.

    version - 0.6
   
 24. blktrace - generate traces of the i/o traffic on block devices.

   version - 2.0.0
   
 25. nicstat - Show Network Interface Card Statistics.

    version - 1.95
    
 26. lldptool - manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

    version - 0.9.46
    
 27. oprofile - a system-wide profiler, capable of profiling all running code at low overhead.

    version - 1.0.0
   
 28. latencytop - a tool for developers to visualize system latencies.

    version - 0.5
   
 29. kgdb: Kernel gnu debugger.

 30. kdb: kernel debugger.

 31. systemtap - SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system. 

 32. kprobes  

 33. crash - Analyze Linux crash dump data or a live system.

    version - 7.1.3
   
 34. memwatch - memory leak detection tool.

    version - 2.69
   
 35. LTTNG - Linux Trace Toolkit Next Generation.

    version - 2.5.0
   
 36. powertop - program help to analyse the power consumption.

   version - 2.6.1
   
 37. slabtop - display kernel slab cache information.

   version - procps-ng 3.3.9
   
 38. ktap - script based dynamic tracing tool for Linux.

   version - 0.4
   
 39. gprof - performance analysis tool.

   version - 2.25
   
 40. valgrind - instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc. 

   version - 3.10.1
   
 41. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.

  Sample scripts are available online.
  
 42. packETHcli - packETHcli is the command line packet generator tool for ethernet. It allows you to create and send any possible packet or sequence of packets on the ethernet link. 

<h3 id="2.2">Fedora</h3>

1. Perf integrated with LLC

   version - 4.0.4-301.fc22.aarch64
   
2. strace - trace system calls and signals

   version - 4.1
   
3. ltrace - library call tracer.

   version - 0.7.91
   
4. netstat  

   version - net-tools 2.10-alpha
   
5. top - display Linux tasks.

   version - 3.3.10(proc-ps-ng) 
   
6. pidstat - Report statistics for Linux tasks.

   version - 11.1.2 
   
7. vmstat - Report virtual memory statistics.

   version - 3.3.10(proc-ps-ng) 
   
8. ftrace

9. iostat -  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS).

   version - 11.1.2
   
10. tcpdump - dump traffic on a network.

   version - 4.7.4
   
11. ethtool - query or control network driver and hardware settings, particularly for wired Ethernet devices. 

   version - 3.18
   
12. swapon, swapoff : enable/disable devices and files for paging and swapping.

   version - util-linux 2.26.2 
   
13. gdb: gnu debugger

   version - 7.9.1-17.fc22 
   
14. iptables - administration tool for IPv4 packet filtering and NAT.

   version - 1.4.21 
   
15. dmidecode - DMI table decoder

   version - 2.12 
   
16. fsck - is used to check and optionally repair a Linux file system.

   version - util-linux 2.26.2 
   
17. lscpu - display information about the CPU architecture.

   version - util-linux 2.26.2 
   
18. lspci - List all PCI devices.

   version - 3.3 
   
19. setpci - utility for querying and configuring PCI devices.

   version - 3.3 
   
20. dstat - versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.

   version - 0.7.2
    
21. procps - procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.

   version - 3.3.10 
    
22. tiptop - display hardware performance counters for Linux tasks.

   version - 2.3
   
23. iotop - simple top-like I/O monitor.

   version - 0.6
   
24. blktrace - generate traces of the i/o traffic on block devices.

   version - 2.0
   
25. nicstat - Show Network Interface Card Statistics.

   version - 1.95
   
26. lldptool - manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

   version - 0.9.46
   
27. oprofile - a system-wide profiler, capable of profiling all running code at low overhead.

   version - 1.0.0
   
28. latencytop - a tool for developers to visualize system latencies.

   version - 0.9.46
   
29. kgdb: Kernel gnu debugger.

30. kdb: kernel debugger.

31. systemtap - SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system.

32. kprobes

33. crash - Analyze Linux crash dump data or a live system.

   version - 7.1.0-1.fc22
   
34. memwatch - memory leak detection tool.

   version - 2.69
   
35. LTTNG - Linux Trace Toolkit Next Generation.

   version - 2.6.0 - Gaia 
   
36. powertop - program help to analyse the power consumption.

   version - 2.8 
   
37. slabtop - display kernel slab cache information.

   version - procps-ng  3.3.10 
   
38. ktap - script based dynamic tracing tool for Linux.

   version - 0.4
   
39. gprof - performance analysis tool.

   version - 2.25-8.fc22 
   
40. valgrind - instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc.

   version - 3.10.1
   
41. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.

   Sample scripts are available online.
   
42. packETHcli - packETHcli is the command line packet generator tool for ethernet. It allows you to create and send any possible packet or sequence of packets on the ethernet link. 
    
<h3 id="2.3">OpenSuse</h3>

1. Perf integrated with LLC

   version - 4.2.3

2. strace - trace system calls and signals

   version - 4.1

3. ltrace - library call tracer.

   version - 0.7.91

4. netstat

   version - 1.42

5. top - display Linux tasks.

   version - 3.3.11 
   
6. pidstat - Report statistics for Linux tasks.

   version - 11.0.8(sysstat)
   
7. vmstat - Report virtual memory statistics.

   version - 3.3.11 
   
8. ftrace

9. iostat -  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS).

   version - 11.0.8(systat)
   
10. tcpdump - dump traffic on a network.

   version - 4.7.4
   
11. ethtool - query or control network driver and hardware settings, particularly for wired Ethernet devices.

   version - 4.2
   
12. swapon, swapoff : enable/disable devices and files for paging and swapping.

    version - 2.27.1  
    
13. gdb: gnu debugger
 
    version - 7.9 

14. iptables - administration tool for IPv4 packet filtering and NAT.
 
    version - 1.4.21  

15. dmidecode - DMI table decoder.

    version - 3.0  
    
16. fsck - is used to check and optionally repair a Linux file system.

    version - 2.27.1  
    
17. lscpu - display information about the CPU architecture.

    version - 2.27.1  
    
18. lspci - List all PCI devices.

    version - 3.4 
    
19. setpci - utility for querying and configuring PCI devices.

    version - 3.4  
    
20. dstat - versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.

    version - 0.7.2
    
21. procps - procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.

    version - 3.3.11

22. tiptop - display hardware performance counters for Linux tasks.

    version - 2.3
    
23. iotop - simple top-like I/O monitor.

    version - 0.6
    
24. blktrace - generate traces of the i/o traffic on block devices.

    version - 2.0
    
25. nicstat - Show Network Interface Card Statistics.

    version - 1.95
    
26. lldptool - manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

    version - 1.0.1
    
27. oprofile - a system-wide profiler, capable of profiling all running code at low overhead.

    version - 1.0.0
    
28. latencytop - a tool for developers to visualize system latencies.

    version - 0.5
    
29. kgdb: Kernel gnu debugger.

30. kdb: kernel debugger.

31. systemtap - SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system.

32. kprobes

33. crash - Analyze Linux crash dump data or a live system.

   version - 7.1.3
   
34. memwatch - memory leak detection tool.

   version - 2.69
   
35. LTTNG - Linux Trace Toolkit Next Generation.

   version - 2.8.0-pre/2.7.0-rc1-354  
   
36. powertop - program help to analyse the power consumption.

   version - 2.8 
   
37. slabtop - display kernel slab cache information.

   version - procps-ng 3.3.11 
   
38. ktap - script based dynamic tracing tool for Linux.

   version - 0.4 
   
39. gprof - performance analysis tool.

   version - 2.25 
   
40. valgrind - instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc.

   version - 3.10.1 
   
41. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.

   Sample scripts are available online.
   
42. packETHcli - packETHcli is the command line packet generator tool for ethernet. It allows you to create and send any possible packet or sequence of packets on the ethernet link. 

<h3 id="2.4">Debian </h3>

1. Perf integrated with LLC

   version - 3.19.8

   Note: Only minimal testing done.
   
2. strace - trace system calls and signals

   version - 4.9
   
3. ltrace - library call tracer.

   version - 0.7.3
   
4. netstat   

   version - 1.42
   
5. top - display Linux tasks. 

   version - 3.3.9 
   
6. pidstat - Report statistics for Linux tasks.

   version - 11.0.8 
   
7. vmstat - Report virtual memory statistics.

   version - 3.3.9
   
8. ftrace

9. iostat -  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS). 

   version - 11.0.1
   
10. tcpdump - dump traffic on a network.

    version - 4.6.2
    
11. ethtool - query or control network driver and hardware settings, particularly for wired Ethernet devices. 

   version - 3.16    
   
12. swapon, swapoff : enable/disable devices and files for paging and swapping. 

   version - 2.25.2    
    
13. gdb: gnu debugger

   version - 7.7.1
   
14. iptables - administration tool for IPv4 packet filtering and NAT.

   version - 1.4.21
   
15. dmidecode - DMI table decoder.

   version - 2.12
   
16. fsck - is used to check and optionally repair a Linux file system.

   version - 2.25.2 
   
17. lscpu - display information about the CPU architecture. 

   version - 2.25.2 
   
18. lspci - List all PCI devices. 

   version - 3.2.1 
   
19. setpci - utility for querying and configuring PCI devices.

   version - 3.2.1 
   
20. dstat - versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.

   version - 0.7.2
    
   Note: some test cases are not working.
   
21. procps - procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.

   version - 3.3.9
   
22. tiptop - display hardware performance counters for Linux tasks.

   version - 2.3
   Note: Some test cases are not working.
   
23. iotop - simple top-like I/O monitor.

   version - 0.6
   
24. blktrace - generate traces of the i/o traffic on block devices.

   version - 2.0.0. 
   
25. nicstat - Show Network Interface Card Statistics.

   version - 1.95
   
26. lldptool - manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

   version - 0.9.46
   
27. oprofile - a system-wide profiler, capable of profiling all running code at low overhead.

   version - 1.0.0
   
28. latencytop - a tool for developers to visualize system latencies.

   version - 0.5
   
29. kgdb: Kernel gnu debugger.

30. kdb: kernel debugger.

31. systemtap - SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system. 

32. kprobes  

33. crash - Analyze Linux crash dump data or a live system.

   version - 7.1.3
   
34. memwatch - memory leak detection tool.

   version - 2.69
    
35) LTTNG - Linux Trace Toolkit Next Generation.

   version - 2.5.0
   
36. powertop - program help to analyse the power consumption.

   version - 2.6.1
   
37. slabtop - display kernel slab cache information.

   version - procps-ng 3.3.9
   
38. ktap - script based dynamic tracing tool for Linux.

   version - 0.4
   
39. gprof - performance analysis tool.

   version - 2.25
   
40. valgrind - instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc. 

   version - 3.10.0
   
41. sysdig  

   version - 0.1.89
   
42. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.

   Sample scripts are available online.
   
43. packETHcli - packETHcli is the command line packet generator tool for ethernet. It allows you to create and send any possible packet or sequence of packets on the ethernet link. 

<h3 id="2.5">CentOS </h3>

1. Perf integrated with LLC

   version - 4.2.0.26.el7.1.aarch64.debug.gbbb5
   
2. strace - trace system calls and signals

   version - 4.8
   
3. ltrace - library call tracer.

   version - 0.7.91
   
4. netstat  

   version - net-tools 2.10-alpha
   
5. top - display Linux tasks.

   version - 3.3.10(proc-ps-ng) 
   
6. pidstat - Report statistics for Linux tasks.

   version - 10.1.5 
   
7. vmstat - Report virtual memory statistics.

   version - 3.3.10(proc-ps-ng) 
   
8. ftrace

9. iostat -  Report CPU statistics and input/output statistics for devices, partitions and network filesystems (NFS).

   version - 10.1.5
   
10. tcpdump - dump traffic on a network.

   version - 4.5.1
   
11. ethtool - query or control network driver and hardware settings, particularly for wired Ethernet devices. 

   version - 3.15
   
12. swapon, swapoff : enable/disable devices and files for paging and swapping.

   version - util-linux 2.26.2 
   
13. gdb: gnu debugger

   version - 7.6.1-80.el7 
   
14. iptables - administration tool for IPv4 packet filtering and NAT.

   version - 1.4.21 
   
15. dmidecode - DMI table decoder

   version - 2.12 
   
16. fsck - is used to check and optionally repair a Linux file system.

   version - util-linux 2.23.2 
   
17. lscpu - display information about the CPU architecture.

   version - util-linux 2.23.2 
   
18. lspci - List all PCI devices.

   version - 3.2.1 
   
19. setpci - utility for querying and configuring PCI devices.

   version - 3.2.1 
   
20. dstat - versatile tool for generating system resource statistics. Replacement for vmstat, iostat and ifstat.

   version - 0.7.2
    
21. procps - procps is the package that has a bunch of small useful utilities that give information about processes using the /proc filesystem.

   version - 3.3.10 
   
22. tiptop - display hardware performance counters for Linux tasks.

   version - 2.3
    
23. iotop - simple top-like I/O monitor.

   version - 0.6
    
24. blktrace - generate traces of the i/o traffic on block devices.

   version - 2.0
    
25. nicstat - Show Network Interface Card Statistics.

   version - 1.95
    
26. lldptool - manage the LLDP settings and status of lldpad (Link Layer Discovery Protocol).

   version - 1.0.1-2
    
27. oprofile - a system-wide profiler, capable of profiling all running code at low overhead.
 
    version - 0.9.9
    
28. latencytop - a tool for developers to visualize system latencies.

   version - 0.5
    
29. kgdb: Kernel gnu debugger.

30. kdb: kernel debugger.

31. systemtap - SystemTap provides free software (GPL) infrastructure to simplify the gathering of information about the running Linux system.

   version - 2.8
    
32. kprobes

33. crash - Analyze Linux crash dump data or a live system.

   version - 7.1.2
    
34. memwatch - memory leak detection tool.

   version - 2.69
    
35. powertop - program help to analyse the power consumption.

   version - 2.8 
    
36. slabtop - display kernel slab cache information.

   version - procps-ng 3.3.10 
    
37. ktap - script based dynamic tracing tool for Linux.

   version - 0.4
    
38. gprof - performance analysis tool.

   version - 2.23.52.0.1 
    
39. valgrind - instrumentation framework for buiding dynamic analysis tools, which can detect memory management and threading bugs,does profiling etc.

   version - 3.10.0
    
40. pktgen - Linux packet generator is a tool to generate packets at very high speed in the kernel.Monitoring and controlling is done via /proc.

   Sample scripts are available online.
    
41. packETHcli - packETHcli is the command line packet generator tool for ethernet. It allows you to create and send any possible packet or sequence of packets on the ethernet link. 


<h3 id="2.6">Miscelleneous Tools </h3>

1. mkfs - build a Linux file system on a device, usually a hard disk partition.

2. mount - mount a file system.

3. du - estimates the file space usage.

4. df - report file system disk space usage.

5. tail - this utility outputs the last part of the files.

6. grep - tool searches the named input files for lines contains a match to the given pattern.

7. awk - pattern scanning and processing language.

8. sed - is a stream editor, used to perform basic text transformations.

