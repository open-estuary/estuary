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
    * [The Format of Yaml](#3.3.1)
* [Architecture & Contribute more benchmarks](#4)
  * [The architecture of Caliper](#4.1)
  * [Add benchmarks to Caliper](#4.2)
    * [the structure of test cases definition](#4.2.1)
    * [Define the benchmark](#4.2.2)
    * [‘Build’ the benchmark](#4.2.3)
    * [‘Run’ the benchmark](#4.2.4)
    * [‘Parser’ the benchmark](#4.2.5)
    * [‘compute the score’ for the benchmark](#4.2.6)
    * [Generate the yaml file](#4.2.7)

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

git clone http://github.com/HTSAT/caliper.git

This will download a directory named caliper in your current operation directory.

Enter the test suite:

cd caliper

Install Caliper (Optional):

sudo python setup.py install

When you install Caliper in your system, the config files locate in the `/etc/caliper/config/` and `/etc/caliper/test_cases_cfg/`.

Not Install Caliper (running Caliper in your home directory).

The config file locate in the config and test_cases_cfg directories under the Caliper root directory.

<h2 id="3">Configure and Run Caliper</h2>

<h3 id="3.1">Configure Caliper</h3>

1. Configure the target

Configure the config/client_config.cfg file to set up the target.

This part includes three sections. CLIENT is the information for Host to connect the Target. The SERVER is the host ip address which is used for connecting the Target. BMCER is used for rebooting the Target: the command is for rebooting the target; the host is the machine which it can execute the command; the user, port and password are used for logging the host. If you don’t want to record your password in the config file, you can copy the pubilc-key of Host to the target and the machine which execute the reboot command.

2. Configure the mail list

Configure the config/email_config.cfg file to determine who will send and receive the mails, the mail contents will be the test reports.

The email_info include the information of the mail, this includes the ‘From’, ‘To’, ‘Subject’ and ‘text’. The login_info is mainly for the user to login his/her mailbox to send test results. This section includes ‘user’, ‘password’ and ‘server’. For 163 mailbox, the server address is ‘smtp.163.com’.

3. Configure the execution way

This means when the processes of building and running occurred error, if caliper will be stopped. The default value of the sections’ key are True.

4. Select the benchmarks you want to run

Configure the config files located in test_cases_cfg/XXXX_cases_cfg.cfg(XXXX can be android, server, arm and common) to select the benchmarks you want to run. When you comment the corresponding sections in XXXX_cases_cfg.cfg, the tools won’t be selected.

5. Configure the test cases you want to run in a benchmark

Configure the test_cases_cfg/XXXX/benchmark_name/benchmark_name_run.cfg(XXXX can be android, server, arm and common) files to select the test cases you want to run.When you comment the corresponding sections in benchmark_name_run.cfg, the test cases of the tools won’t be run.

<h3 id="3.2">Run Caliper</h3>

If you have configured your environment, you can enter the commands of caliperto run caliper, it will compile and execute test cases, parser the output and get the summarization of the outputs.
The command is caliper. You can use caliper -h to show all the commands options. After the process finished, you can view the generated files, including the log files, binary files, test results and so on. The logs and the test results will locate in the ~/.caliper if you have installed caliper. Otherwise, they will locate in the Caliper root directory when you run caliper from the Caliper source code.

<h3 id="3.3">Caliper output</h3>

After the caliper -option command has been finished, the results generated are
in the results folder, the results folder contains all the results. The logs
will be in caliper_build and caliper_exec folder. Each benchmarks has two
related log files about the execution and parsering, named XXX_output.log and
XXX_parser.log. In addtion, all result of selected benchmarks’ test points are
stored in the yaml file, which located in results/yaml.

You can see the comparision figures in the results/test_results.tar.gz, the tarball is a webpage tarball. If it is not there, maybe you have a wrong when generating the webpages or you have not select the option to generate the webpage. Or you can see the specific values of Test Cases and scores in results/yaml/your_machine_name.yaml,
results/yaml/your_machine_name_score.yaml and
results/yaml/your_machine_name_score_post.yaml.

<h4 id="3.3.1">The Format of Yaml</h4>
name: your_machine_name
......
results:
  Performance:
    latency:
      process:
        Point_Scores:
          lat_proc_exec: 5.77
          lat_proc_fork: 5.95
          lat_proc_shell: 2.34
          lat_sig_catch: 2.86
          lat_sig_install: 4.69
          .....
    network:
      latency:
        Point_Scores:
          lat_connect: 0
          lat_pipe: 2.97
          ......

The Performance means a Test Item; the latency, memory and network are Test Sub-Items which belong to the Performance; In the Test Sub-Item of memory, the bandwidth is a Test Point; in bandwidth, some Test Cases has been tested, so in the Point Scores has some key-value pairs, such as bw_mem_bzero: 246.7238.
Note: in some key-value pairs, the value of ‘0’ means that the test case is failed.

<h2 id="4">Architecture & Contribute more benchmarks</h2>

<h3 id="4.1">The architecture of Caliper</h3>

There are several files and folders in the test suite, they are listed in the follow.
benchmarks client common.pyc frontend README.md setup.py caliper common.py config __init__.py server test_cases_cfg

benchmarks: store the benchmarks, they can be downloaded or written by yourself.

caliper: run ./caliper, the benchmarks which was configured in the test_cases_cfg/XXXX_cases_def.cfg(XXXX can be common and some like that) will be compiled and generate the executable files in the build directory. Then the Host will scp the generated execution files to the Target, and then control the Target to run the commands which has been configured in the test_cases_cfg/XXXX/benchmark_name/benchmark_name_run.cfg and get the results of the command, then the host will parser the outputs. Caliper will run the commands and parser the commands one by one

server: This directory contains the scripts for dispatching the build, run and parser on the Host and remote login in the Target. Also part of scripts in server directory will use the function in the directory named of client. The thought of clientand server is borrowed from the Autotest.
```
.
├── build
├── common.py
├── compute_model
├── hosts
├── __init__.py
├── parser_process
├── run
├── test_host.py
└── utils.py
```
The build directory is for building the benchmarks in Caliper.
The compute_model directory mainly include the method to get the score from the parser output, the method of scoring mainly in the scores_method.py. The parser_process is mainly about the process of parsering the output of benchmarks, traverse the output to the score and draw the diagrams for Caliper.
The run directory mainly includes the test_run.py, it is the main code to execute the commands in benchmarks and the parser function defined by each benchmarks.
The hosts directory mainly contains the class of hosts and how to use hosts.

test_cases_cfg: benchmarks which will be compiled and run are defined in this directory.

<h3 id="4.2"> Add benchmarks to Caliper</h3>

If a benchmark need to be added in Caliper, some steps should be done.

<h4 id="4.2.1">the structure of test cases definition</h4>

The directory named of test_cases_def is the key of how to build, run and parser. The tree of it is listed in the follow. If you want to add a benchmark, you not only need to add the section about it in XXX_cases_def.cfg (XXX can be common, server arm, or android, this depends on your classfication of the test cases), but also need to define the build process of build, the config file of run, and the parser scripts used to get results.
```
.
├── android
├── android_cases_def.cfg
├── arm
├── arm_cases_def.cfg
├── common
├── common_cases_def.cfg
├── README
├── server
└── server_cases_def.cfg
```
The architecture of common directory looks like below. Namely, the build script, the run config file should be added in the directory. If the test cases need server and client, then you need to have a more XXX_server_run.cfg, it is used to run the server’s commands. In addition, the parser file of a benchmark, which named iperf_parser.py or something like that, should be added in the client/parser/.
```
.
├── iperf
│   ├── iperf_build.sh
│   ├── iperf_run.cfg
│   └── iperf_server_run.cfg
└── rttest
    ├── rttest_build.sh
    └── rttest_run.cfg
```
<h4 id="4.2.2">Define the benchmark</h4>

Add the corresponding information in test_cases_cfg/test_cases_define.cfg. The format of the info is listed below.

[lmbench]
build = lmbench_build.sh
run = lmbench_run.cfg
parser = lmbench_parser.py

The options of build, run and parser are indispensable. The values in the section are all files which need to be located in the classfication folder(common, arm, server and so on).

<h4 id="4.2.3">‘Build’ the benchmark</h4>

The script file which is specified by the build option can compile the benchmark. The exsiting shell script of other benchmarks can be referenced. The path should be taken into consideration. Take the scimark build for example.

the scimark build scripts:
```
1 build_scimark() {
2     set -e
3     SrcPath=${BENCH_PATH}"402.scimark"
4     myOBJPATH=${INSTALL_DIR}/bin
5     pushd $SrcPath
6     if [ $ARCH = "x86_32" -o $ARCH = "x86_64" ]; then
7         make CC=$GCC CFLAGS="-msse4"
8         cp scimark2 $myOBJPATH/
9         make CC=$GCC clean
10     fi
11     if [ $ARCH = "arm_32" ]; then
12         make CC=$GCC CFLAGS=" -mfloat-abi=hard -mfpu=vfpv4 -mcpu=cortex-a15 "
13         cp scimark2 $myOBJPATH/
14         make CC=$GCC clean
15     fi
16     if [ $ARCH = "arm_64" ]; then
17         make CC=$GCC
18         cp scimark2 $myOBJPATH
19         make CC=$GCC clean
20     fi
21
22     if [ $ARCH = "android" ]; then
23         ndk-build
24         cp libs/armeabi-v7a/scimark2 $myOBJPATH/
25         ndk-build clean
26         rm -rf libs/ obj/
27     fi
28     popd
29 }
30 
31 build_scimark
```

You should change the value of SrcPath and myOBJPATH, to use your benchmaarks name to replace 402.scimarkand use your expected name to resplace bin.
Then you can define the build commands in the later space. For different arch, you can use different commands.

 <h4 id="4.2.4">‘Run’ the benchmark</h4>
 
When you run caliper, if the build process finished, caliper will scp the binary files to the remote target, and then run the commans you defined in the XXX_run.cfg on the remote target. The run option illustrates the configuration of running the benchmark.

The content of the configuration file is like this:
```
1 [scimark]
2 category = Performance cpu multicore_float scimark
3 scores_way =  compute_speed_score 1
4 command = ./bin/scimark2
5 parser = scimark_parser
```
Each section in the configuration is a Test Case. The category key set the value of the Test Cases category. The scores_way is set to compute the score of the Test Case. The method set in the scores_way can be found in scores_method.py in the compute_model directory which locates in server directory. New computation method can be added in that file. The command is the instruction which will be run on the target. The parser set the method to parser the output of the command, the parser must be implemented in the parser file.

Note: the commands in the command must can be found in the binary files directory, it should have the expected name in the commands.

Also, we support the different length of category. Why we use so many kinds of category, it is because one test case may include many values which belong to different kinds of categories.

1). One
```
1 [lmbench]
2 category = Performance     (lmbench covers some subsytem, such as cpu, network, and so on)
3 scores_way = compute_speed_score 2
4 command = 'cd lmbench; ./lmbench CONFIG'
5 parser = lmbench_parser
```
2).Two
```
1 [nbench]
2 category = Performance cpu  (nbench covers sincore_int and sincore_float)
3 scores_way =  compute_speed_score 1
4 command = "pushd nbench; ./nbench; popd"
5 parser = nbench_parser
```
3).Three
```
1 [iozone]
2 category = Performance disk bandwidth  (iozone cover the read, write and so on in bandwidth)
3 scores_way =  compute_speed_score 5
4 command = "cd bin; ./iozone -s5g -r1M -I; cd .."
5 parser = iozone_parser
```
4).Four
```
1 [scimark]
2 category = Performance cpu multicore_float scimark
3 scores_way =  compute_speed_score 1
4 command = ./bin/scimark2
5 parser = scimark_parser
```
<h4 id="4.2.5">‘Parser’ the benchmark</h4>

The parser method has been set, and it must be implemented, in the above example of code, the function of scimark_parser must be in the file of scimark_parser.py. This file should be located in the client/parser folder.

8 def scimark_parser(content, outfp):
9     value = -1
     ...
22    return value

Notes: the funtion of parser must have two args: the first represents the output of executing commands, it is come from fd.read(); the second is the file pointer which writes the parser log file. In addtion the parser must return an number, which is needed for the later score computing.

Notes: According to the length of the category in XXX_run.cfg, the parser needs to return different values.

1) Return Three embedded dictionary (the length of category is 1)

1 [lmbench]
2 category = Performance   
3 scores_way = compute_speed_score 2

The parser need to return a dictionary. the CPU part is dic[‘cpu’], memory is dic[‘memory’], etc. Each element of the list is a dictionary, it looks like this: {multicore_int:{key1:value1, key2: value2 …}, multicore_float:{}}.

But if some values are about latency while others are about bandwidth in the dictionary, it is not scientific to use one formula to get the score for latency and bandwidth, they need different compute methods. The function of compute_speed_score is suitable for the bandwidth and is not suitable for latency.

2) Return Two embedded dictionary (the length of category is 2)

1 [nbench]
2 category = Performance cpu

In this kind, the category only shows it belongs to the ‘Performance cpu’, the parser will return a dictionary, the dictionary looks like ‘{‘sincore_int’:{key1:value1, key2: value2 ….}}’, so that in yaml file, the category can be interpreted to ‘performance cpu sincore_int key1’. If the parser return a dictionary, then all values in the dictionary will use the function to do the normalisation.

3) Return a dictionary (the length of category is 3)

1 [iozone]
2 category = Performance disk bandwidth  (iozone cover the read, write and so on in bandwidth)
3 scores_way =  compute_speed_score 5 

The parser will return a dictionary, it looks like {‘read’:’1234’, ‘write’: ‘780’, …}. All the value in the dictionary will be computed by the ‘compute_speed_score 5 ‘ later.

4) Return a number (the length of category is 4)

1 [scimark]
2 category = Performance cpu multicore_float scimark
3 scores_way =  compute_speed_score 1
If the command is executed successfully, the function of parser return a float number; or the 0 should be returned.

<h4 id="4.2.6">‘compute the score’ for the benchmark</h4>

6.1 For latency, we can provide the exp_score_compute to compute, it has two parameter, one is base, and the other is a index.
It has the function of score = (value/(10**base))** index, the index is a negtive number.

6.2 For the values that is the more, the better, we provide the function of compute_speed_score, it has the same function of score = value / (10**parameter)

<h4 id="4.2.7">Generate the yaml file</h4>

The values generated by the run and parser will be stored in the yaml file, the hoatname.yaml store the original values. the hostname_score.yaml store the normalized values, the compute method is defined in the scores_way = compute_speed_score 5. The hostname_score_post.yaml has got the total value from each point scores. It will be used for drawing graph.
