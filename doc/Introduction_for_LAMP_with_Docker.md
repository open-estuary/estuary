How to Build LAMP Service with Docker Images?

This doc is designed to build LAMP service by using Docker Images.

LAMP is an archetypal model of web service solution stacks, which contains four parts: the Linux operating system, the Apache HTTP Server, MySQL, and the PHP programming language. Docker helps developers focus on the web project, not the running environment.

Two Docker Images: openestuary/mysql and openestuary/apache have been developed which are stored in Docker Hub. About how to build lamp service is shown as follow: 

You are supposed to have installed Docker successfully and enable Docker service automatically. Then you should pull related Docker Images which will take some time, please be patient. Just type as follows:
```shell
$ docker pull openestuary/apache
$ docker pull openestuary/mysql
```

After finished above operation, you can start Docker container by using the pulled Images. Just type as follows:
```shell
$ docker run -d -p 32775:80 --name apache -v /x/xx:/var/www/html openestuary/apache
$ docker run -d -p 32776:3306 --name mysql openestuary/mysql
```
	
Using the two containers named apache and mysql, you only need the source code of the web project. Suppose the web project is stored under /x/xx, we can use the command "-v" to mount the local files into the specified path of the container. The local host will assign a free port to the default port 80 of apache service. Using "-p", you should check the port is free firstly. It is the same for mysql when assigning a local port mapping the default port 3306 of mysql service.

Mysql container use default username "mysql" and password "123456". Of course, you can change the configuration of mysql with the following commands
```shell
$ docker run -d -P --name mysql \
      -e MYSQL_USER=xxx \
      -e MYSQL_PASSWORD=xxx \
      -e MYSQL_DATABASE=xxx \
      openestuary/mysql
```

In order to make it more specific, The use of a PHP page with mysql connection will be demonstrated. If PHP page display normally, the two images are proven to work well. Suppose the local IP is 192.168.1.220. The content of the PHP page named index.php is as follows:
```shell
<?php
$con = mysql_connect("192.168.1.220:32776","mysql","123456");
if (!$con)
{
die('Could not connect: ' . mysql_error());
}
else
	echo "hello world!";
mysql_close($con);
?>
```
Everything goes well if you see the output "hello world!" at website http://192.168.1.220:32775/index.php. Please enjoy the lamp service offered by the two containers named mysql and apache.
