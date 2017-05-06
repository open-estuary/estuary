* [Introduction](#1)
* [Packages Installation](#2)
* [Packages Documents](#3)

<h2 id="1">Introduction</h2>
According to [EstuaryCfg.json](https://github.com/open-estuary/estuary/blob/master/estuarycfg.json), Estuary could integrate packages accordingly. 

<h2 id="1">Packages Installation</h2>

Typically packages could be installed via two ways:
- RPM/Deb Repositories:
  - RPM (CentOS): 
    Firstly it is necessary to add yum repository as below. Then the corresponding package could be installed `yum install <package-name>`. Especially there might be multiple versions for the same package, it could use `yum install <package-name>-<specific-version>` to install required package. 
    ```
    sudo wget -O /etc/yum.repos.d/estuary.repo https://raw.githubusercontent.com/open-estuary/distro-repo/master/utils/estuary.repo
    sudo chmod +r /etc/yum.repos.d/estuary.repo
    yum clean dbcache
    ```
  - Deb (Ubuntu/Debian):
   ```
   TBD
   ```
- Docker Images:
  Use`docker pull openestuary/<app name>` to install the corresponding docker images. For more information, please refer to the corresponding manuals mentioned below. 

<h2 id="2">Packages Documents</h2>
Currently the following packages are supported on ARM64 platforms:

- [Armor Manual](https://github.com/open-estuary/estuary/blob/master/doc/Armor_Manual.4All.md) 
- [OpenJDK](https://github.com/open-estuary/packages/blob/master/openjdk/OpenJdk_Manual.md) 
- [Docker](https://github.com/open-estuary/estuary/blob/master/doc/Introduction_for_Docker.md)
- [Docker App]
    - [MySql(Percona Server)](https://github.com/open-estuary/packages/blob/master/docker_apps/mysql/MySql_Manual.md)
    - [AliSQL](https://github.com/open-estuary/packages/blob/master/docker_apps/alisql/AliSQL_Manual.md)
    - [MariaDB](https://github.com/open-estuary/packages/blob/master/docker_apps/mariadb/MariaDB_Manual.md)
    - [Redis](https://github.com/open-estuary/packages/blob/master/docker_apps/redis/Redis_Manual.md)
    - [PostgreSQL](https://github.com/open-estuary/packages/blob/master/docker_apps/postgresql/PostgreSQL_Manual.md)
    - [MongoDB](https://github.com/open-estuary/packages/blob/master/docker_apps/mongodb/MongoDB_Manual.md)
    - [LAMP](https://github.com/open-estuary/packages/blob/master/docker_apps/lamp/LAMP_Manual.md)
    - [Cassandra](https://github.com/open-estuary/packages/blob/master/docker_apps/cassandra/Cassandra_Manual.md)
    - [Ceph](https://github.com/open-estuary/packages/blob/master/docker_apps/ceph/Ceph_Manual.md)
    - [OpenStack](https://github.com/open-estuary/packages/blob/master/openstack/doc/OpenStack_Manual.md)
