* [How to Use Caliper?](#1)
  * [Work Mode](#1.1)
    * [Environment Installation Requirements](#1.1.1)
    * [Host OS installation](#1.1.2)
    * [Toolchain installation](#1.1.3)
* [Download and Install](#2)
* [Configure and Run Caliper](#3)
  * [Configure Caliper](#3.1)
  * [Run Caliper](#3.2)
  * [Caliper output](#3.3)
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

It supports x86_64 CentOS6, OpenSUSE and Ubuntu platform, you need install 64bit CentOS system or Ubuntu system on your PC or server platform.

<h4 id="1.1.3">Toolchain installation</h4>

To build arm/android target binary, it requires arm/android toolchain deployment. We can download the existing compiled toolchains from some website.
Here is website to download ARM toolchains:

https://releases.linaro.org/13.10/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.8-2013.10_linux.tar.bz2, which is for the target that is arm_32.

https://releases.linaro.org/13.10/components/toolchain/binaries/gcc-linaro-aarch64-linux-gnu-4.8-2013.10_linux.tar.bz2, which is for the target that is arm_64.

For ubuntu, you can directly use the following commands to install the toolchains.
```shell
sudo apt-get install gcc-aarch64-linux-gnu -y
sudo apt-get install gcc-arm-linux-guneabihf -y
```

Note: Current building for x86_32 platform is not supported now. For cross compiler, the path of tool-chain need to be added in the $PATH in the Host.*

<h2 id="2">Download and Install</h2>


