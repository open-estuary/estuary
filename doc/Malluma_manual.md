* [Introduction](#1)
* [Install guide](#2)
* [User guide](#3)
* [Uninstall guide](#4)

<h2 id="1">Introduction</h2>

- The malluma software is the performance tuning tool, that could sample the cpu's data include the hardware events and software events by PMU, and scheduling condition's data, and I/O, network, LLC/DDR and so on. 
- But it could only sample the ARM environment's data. It could help you  find your system bottleneck when you run your program. Maybe your program's bottleneck  is memory, I/O, LLC/DDR or scheduling, it could help you find  quickly.

<h2 id="2">Install guide</h2>

First, it is necessary to setup the repository. Please refer to [https://github.com/open-estuary/distro-repo/blob/master/README.md](https://github.com/open-estuary/distro-repo/blob/master/README.md) CentOS repo adding part。

Second, you should install the malluma's rpm package. You could use the command  as follows.
```
yum install Malluma.aarch64
```

Third, you should install the malluma software, and specific steps are as follows:
    
<pre>
cd /opt/Malluma-2.0 
yum install -y strace // install strace as a dependency, avoid this operation in next malluma version
sh ./install.sh  --environment //install the external environment
sh ./install.sh  --check //check the environemnt if or not ready
sh ./install.sh  --all //really install process
Note:you should guarantee that the capacity of the installation directory is more than 50G.
</pre>

- **Maybe installing qeustion**
- Question 1: 
<pre>
Error info:
cc:error: ../deps/hiredis/libhiredis.a: no such file or directory
cc:error: ../deps/lua/src/liblua.a: no such file or directory
cc:error: ../deps/geohash-int/geohash.o: no such file or directory
...
Solution:
cd /usr/local/src/redias/deps
make geohash-int hiredis jemalloc linenoise lua
</pre>
- Question 2:
<pre>
When you run the third step "sh ./install.sh --check", maybe has some erros such as "./install.sh:line 475: 4*100+16*10+:syntax error:operand expected (error token is '+')". 
You could ignore it, this type error would not affect the normal function about the Malluma.
</pre>

<h2 id="3">User guide</h2>

For example, you has installded the malluma in the machine, it's ip is 192.168.1.100.
You could visit the 192.16.1.100 by the browser (***only Google chrome***) to use the malluma's functions. When you visit it , you will be asked for the user/password.  That's default username is "admin", and the default password "Admin12#$". [Details info is here.](https://github.com/open-estuary/estuary/blob/master/doc/Malluma_UserGuide.pdf)

<h2 id="4">Uninstall guide</h2>

First you should enter in the malluma's installed directory, then executing the commands as follows.
<pre>
sh uninstall.sh
</pre>
Second you should remove the malluma's rpm package.
<pre>
yum remove Malluma.aarch64
</pre>
