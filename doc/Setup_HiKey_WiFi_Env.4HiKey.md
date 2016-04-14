* [Config WiFi On mini-rootfs systerm](#1)
* [Config WiFi On Ubuntu & Debian systerm](#2)
* [Fedora && CentOS wifi configure](#3)
* [OpenSuse Wifi configure](#4)

This is a guide to setup a WiFi environment on your HiKey board.

When HiKey board can boot into mini-rootfs systerm or Ubuntu systerm in Estuary project, you can config WiFi function. If you can not boot into this systerm, you can get more information from DeployManual.txt file.

<h2 id="1">Config WiFi On mini-rootfs systerm</h2>

   On serial console, you should see some debug message which can show if the Hikey board have
   boot into mini-rootfs systerm successfully. You can config this WiFi according to this follow
   instruction:
   
   ```shell
    $ echo 0 > /sys/kernel/debug/ieee80211/phy0/wlcore/sleep_auth
    $ ifconfig wlan0 up

    ## Use the following command to know if WiFi is ok ##
    $ iw wlan0 scan | grep SSID

    ## to create a wpa_supplicant.conf ##
    $ wpa_passphrase <ssid> <passphrase> > /etc/wpa_supplicant.conf
   ``` 
  eg: wpa_passphrase admin admin > /etc/wpa_supplicant.conf
   
  ```shell
   $ wpa_supplicant -B -iwlan0 -c/etc/wpa_supplicant.conf -Dnl80211

   ## wait a while for wpa_supplicant to link ##
   $ iw wlan0 link

   ## config ip and route ##
   $ ifconfig wlan0 <IP address>
   $ route add default gw <IP address>
   $ echo "nameserver <IP address>" >> /etc/resolv.conf
  ```
   eg: ifconfig wlan0 192.168.2.80<br>
   eg: route add default gw 192.168.2.1<br>
   eg: echo "nameserver 192.168.2.1" >> /etc/resolv.conf

  NOTE: In order to test this WiFi function, you can use "ping www.baidu.com" website to verify it.

<h2 id="2">Config WiFi On Ubuntu & Debian systerm</h2>

 On serial console, you should see some debug message which can show if the Hikey board have
   boot into ubuntu systerm successfully. You can config this WiFi according to this follow
   instruction:

   Supposed the login user is peter.
   
1. Find out the wireless device name ##
     `$ iw dev`
      >  phy#0
      >  Interface wlan0
      >	 ifindex 3
      >	 type managed
	   
   The above output shows that the system has 1 physical WiFi card, designated as phy#0.
   The device name is wlan0. The type specifies the operation mode of the wireless device.
   managed means the device is a WiFi station or client that connects to an access point.
	
2. configure the wifi data for the wifi device you selected
     ```shell
	 cd /etc/wpa_supplicant
         vi wpa_supplicant.con
       ```
   then you should remove all the existed entries parenthesized by'network={'; those entries are original configures, probably not suitable
   for your network environment, so you can delete them.
    
    Now, you can configure your own wifi data:
  
   `wpa_passphrase CTS 88888888 >> /etc/wpa_supplicant/wpa_supplicant.conf`
  
   Please note that you should replace the 'CTS', '88888888' with your AP
   configuring parameters. If you want to more info about this command,
   please refer to wpa_passphrase manual.
    
   To be more security, you can remove the '#psk=xxxx' from the
   wpa_supplicant.conf;
    
   If your AP is hidden SSID, add thise option just following the configure
   line of 'ssid="???"' :
   scan_ssid=1
   
3. configure the wifi interface

  You must configure a corresponding wifi interface to make wifi enabled during the booting.
  ```shell
   cd /etc/network/interfaces.d
   cp -Pp wlan0.cfg.template xxxx.cfg
   ```
  You should replace the 'xxxx' as your wifi device name, such as wlan0.
  Modify the new xxx.cfg, add these configurations:
    ```shell
    auto xxxx
    iface xxxx inet dhcp
    ```
 You also need to replace the 'xxxx' with your wifi device name.
 Here, we only use dhcp as the defualt network mode, if you want to
 configure others, please do it yourself.

 You also need to update the configure relevant to the sys configure file
 of sleep_auth, just modify the file path correspond to your wifi device:
 `pre-up echo 0 > /sys/kernel/debug/ieee80211/phy0/wlcore/sleep_auth`

 This configure matchs to wlan0. If your device is not wlan0, please check
 what is the right path based on the output of the above 'iw dev xxxx' (
 here, xxxx is the wifi device name), you can find what is the phy index,
 then replace the phy0 with the correct phy index.

 If your envinorment has not any wired network device, you can rename the eth3.cfg in `/etc/network/interfaces.d` as eth3.cfg.template;
    
4. reboot the system adn verify the wifi status

   At first, please reboot the system.

   After the system is ready, you can check whether the wifi is ready:
    
   a. Check whether the wireless device is up.

   `$ ip link show wlan0`
   
      3: wlan0: (BROADCAST,MULTICAST) mtu 1500 qdisc noop state DOWN mode DEFAULT qlen 1000
     link/ether 74:e5:43:a1:ce:65 brd ff:ff:ff:ff:ff:ff
	    
    Look for the word "UP" inside the brackets in the first line of the output.

   b. enable the wireless device

   In the above example, wlan0 is not UP. Execute the following command to bring it up:

     `$ sudo ip link set wlan0 up`

     `[sudo] password for peter`:
     
   Note: you need root privilege for the above operation.

   If you run the show link command again, you can tell that wlan0 is now UP.

	 `$ ip link show wlan0`
	 
        wlan0: (NO-CARRIER,BROADCAST,MULTICAST,UP) mtu 1500 qdisc mq state DOWN mode DEFAULT
	qlen 1000
	link/ether 74:e5:43:a1:ce:65 brd ff:ff:ff:ff:ff:ff
      
   c. Check the connection status.

	 `$ iw wlan0 link`
	 
     you can found the connect is ok now.

	  `$ ip addr show wlan0`
	  
	   wlan0:  mtu 1500 qdisc mq state UP qlen 1000
	   link/ether 74:e5:43:a1:ce:65 brd ff:ff:ff:ff:ff:ff
	   inet 192.168.1.113/24 brd 192.168.1.255 scope global wlan0
	   inet6 fe80::76e5:43ff:fea1:ce65/64 scope link
	   valid_lft forever preferred_lft forever
	  
  NOTE: In order to test this WiFi function, you can use "ping www.baidu.com" website to verify it.
   
<h2 id="3">Fedora && CentOS wifi configure</h2>

 Please run 'iw dev' to collect the wifi device information as the first step.
 You at least need to know what is the device name of your wifi.

1. configure the wpa_supplicant environment
   ```shell
   cd /etc/sysconfig

    vi wpa_supplicant
  ```
   You should add your wifi device name and the relative driver in that file,
   such as -iwlan0, -Dnl80211;

2. Configure the wpa_supplicant.conf

  wpa_passphrase CTS 88888888 >> /etc/wpa_supplicant/wpa_supplicant.conf

  Then edit the wpa_supplicant.conf just as what you done in Debian or Ubuntu.

3. Create a wifi connection

  You need to create a corresponding wifi connection file in `/etc/sysconfig/network-scripts`.
  
  nmcli dev wifi connect CTS password 88888888 wep-key-type key ifname wlan0 name wlan0 hidden yes
  
  this command will create the wifi connection in `/etc/sysconfig/network-scripts`
  
  You should replace the 'CTS' '88888888' with your own wifi AP configurations.
  
  If your wifi device is not 'wlan0', please replace it with right name too.
  
  If your AP is not hidden ssid, please remove 'hidden yes'

  This command must be sucessful. It will enable the wifi link.
  sometimes, this command will get failed for conflicting with previous scan,
  you should run it again in some times.

  Since your had configure the password in the above command, the #psk in
  wpa_supplicant.conf is not needed since it will disclose to the others. It is
  better to remove that line in /etc/wpa_supplicant/wpa_supplicant.conf

  --remove that line '#psk="88888888"'

4. reboot your system and verify it

  After your system is booted, check the wifi link and the IP address:

  iw wlan0 link

  ip addr show wlan0

  When the above are ok, you can do some pings to external website.
  
<h2 id="4">OpenSuse Wifi configure</h2>

1. modify the wifi connection file (such as ifcfg-xxx)

  ```shell
  cd /etc/sysconfig/network

  cp -Pp template-ifcfg-wlan0 ifcfg-xxx
 ```
  you should replace xxx with your wifi device name you pick up.

  update these configure items with your local AP settings:

   ```shell
   WIRELESS_ESSID='xxxx'
   WIRELESS_WPA_PSK='yyyyyyyy'
   ```

   The 'xxxx' 'yyyyyyyy' should be replaced with your wifi SSID and KEY.
   If your AP is hidden ssid, add this option:
   WIRELESS_HIDDEN_SSID='yes'

   Please note that, the current configuration in ifcfg-xxx is for PSK. If your
  wifi AP configuration is different, please make the relevant modifications by
  yourself.

2. reboot the system and verify it

Same as the operation on other distributions.

All the above configure should be done for the first time. If you change the AP configurations, please
update those configure files above with correct options. Otherwise, the wifi
should be ok every booting.
