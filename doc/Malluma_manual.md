- **Introduction**
- **Install guide**
- **User guide**
- **Uninstall guide**
## Introducation ##
- The malluma software is the performance tuning tool, that could sample the cpu's data include the hardware events and software events by PMU, and scheduling condition's data, and I/O, network and so on. 
- But it could only sample the ARM environment's data. It could help you  find your system bottleneck when you run your program. Maybe your program's bottleneck  is memory , I/O or scheduling, it could help you find  quickly.
## Install guide ##
First you should install the malluma's rpm package. You could use the command  as follows.
```
yum install Malluma-sec.aarch64
```
Second you should install the malluma software,  and specific steps are as follows:
    
<pre>
cd /opt/Malluma-sec-1.0 
sh ./install.sh  --environment //install the external environment
sh ./install.sh  --check //check the environemnt if or not ready
sh ./install.sh  --all //really install process
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

## User Guide ##
For example, you has installded the malluma in the machine, it's ip is 192.168.1.100.
You could visit the 192.16.1.100 by the browser (IE or Google chrome) to use the malluma's functions. When you visit it , you will be asked for the user/password.  
That's default username is "admin", and the default password "Admin12#$". [Details info is here.](https://github.com/open-estuary/estuary/blob/master/doc/Malluma_UserGuide.pdf)
## Uninstall guide##

First you should enter in the malluma's installed directory, then executing the commands as follows.
<pre>
sh uninstall.sh
</pre>
Second you should remove the malluma's rpm package.
<pre>
yum remove Malluma-sec.aarch64
</pre>
