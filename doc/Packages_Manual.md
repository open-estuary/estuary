* [Introduction](#1)
* [Packages Installation](#2)
* [Packages Documents](#3)
* [Others](#4)


<h2 id="1">Introduction</h2>

According to the [EstuaryCfg.json](https://github.com/open-estuary/estuary/blob/master/estuarycfg.json) 
packages could be integrated into Estuary accordingly. 

<h2 id="2">Packages Installation</h2>

Typically packages could be installed via two ways:
- RPM/Deb Repositories:
  - As for how to install rpm/deb packages, please refer to [Open-Estuary Repository README](https://github.com/open-estuary/distro-repo/blob/master/README.md)
- Docker Images:
  - Use`docker pull openestuary/<app name>` to install the corresponding docker images. For more information, please refer to the corresponding manuals mentioned below. 

<h2 id="3">Packages Documents</h2>
Currently the following packages are supported on ARM64 platforms:

|Package Name|Estuary Releases|Packages Releases|Install Methods|Notes|
|--|--|--|--|--|
|[Armor Manual](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.4All.md) | 3.0/3.1/5.0| |RPM/Deb| System tools such as perf |
|[OpenJDK](https://github.com/open-estuary/packages/blob/master/openjdk/OpenJdk_Manual.md) | 3.0/3.1/5.0 |1.8 ||Linaro OpenJDK|
|[Docker](https://github.com/open-estuary/estuary/blob/master/doc/Introduction_for_Docker.md)|3.0/3.1/5.0|  |RPM/Deb||Docker tool|
|[MySql(Percona Server)](https://github.com/open-estuary/packages/blob/master/docker_apps/mysql/MySql_Manual.md)|3.0/3.1/5.0|  |RPM/Docker Image||
|[AliSQL](https://github.com/open-estuary/packages/blob/master/docker_apps/alisql/AliSQL_Manual.md)|3.0/3.1/5.0|5.6/5.7|RPM/Docker Image||
|[MariaDB](https://github.com/open-estuary/packages/blob/master/docker_apps/mariadb/MariaDB_Manual.md)|3.0/3.1/5.0|10.1|RPM/Docker Image||
|[Redis](https://github.com/open-estuary/packages/blob/master/docker_apps/redis/Redis_Manual.md)|3.0/3.1/5.0|3.2.4|RPM/Docker Image||
|[PostgreSQL](https://github.com/open-estuary/packages/blob/master/docker_apps/postgresql/PostgreSQL_Manual.md)|3.0/3.1/5.0|9.6|RPM/Docker Image||
|[MongoDB](https://github.com/open-estuary/packages/blob/master/docker_apps/mongodb/MongoDB_Manual.md)|3.0/3.1/5.0|3.4|RPM/Docker Image||
|[LAMP](https://github.com/open-estuary/packages/blob/master/docker_apps/lamp/LAMP_Manual.md)|3.0/3.1/5.0||Docker Image|Linux+Apache+MySQL+PHP|
|[Cassandra](https://github.com/open-estuary/packages/blob/master/docker_apps/cassandra/Cassandra_Manual.md)|3.0/3.1/5.0|3.10|RPM/Docker Image||
|[Ceph](https://github.com/open-estuary/packages/blob/master/docker_apps/ceph/Ceph_Manual.md)|3.0/3.1/5.0|11.1.1|RPM/Docker Image||
|[OpenStack](https://github.com/open-estuary/packages/blob/master/openstack/doc/OpenStack_Manual.md)|3.0/3.1/5.0|  |RPM||
||||  
       
<h2 id="4">Others</h2>

- The yum/deb repositories will be supported officially from Estuary V500 release
- If you come across any issue (such as supporting new packages on ARM64 platform, enhancing packages performance on ARM64 platforms, and so on) during using above packages, please feel free to contact with us by using any of following ways:
  - Visit www.open-estuary.com website, and submit one bug
  - Report one issue in this github issue page
  - Email to sjtuhjh@hotmail.com
