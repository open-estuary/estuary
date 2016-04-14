* [How to Use Caliper?](#1)
  * [Work Mode](#1.1)
    * [Environment Installation Requirements](#1.1.1)
    * [Host OS installation](#1.1.2)
    * [Toolchain installation](#1.1.3)
* [Download and Install](#2)
* [Configure and Run Caliper](#3)
  * [ Work Mode](#3.1)
  * [ Work Mode](#3.2)
  * [ Work Mode](#3.3)
    * [The Format of Yaml](#1.1.1)
* [Architecture & Contribute more benchmarks](#4)
   
<h2 id="1">How to Use Caliper?</h2>

The test suite mainly includes performance test cases, it can be used to test the performance of machine, and now we have not integrated many functional tests. The test suite can run on Linux, the machines can belong to x86_64, arm_32, arm_64. Here is steps to setup testbed.

<h3 id="1.1">Work Mode</h3>

The host and the target all run Linux. The Host can access the Target with SSH, you should better scp the public key of Host to the Linux target so that the host can access the target without password. Also you need to install the compiling chain in the host for the Linux target.

<h4 id="1.1.1">Environment Installation Requirements</h4>

 * Python 2.7
 * Linux
 * SSH for Linux devices
 * Compilation Chain for Linux devices

<h4 id="1.1.2">Host OS installation</h4>
<h4 id="1.1.3">Toolchain installation</h4>
