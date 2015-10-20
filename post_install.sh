#!/bin/bash
post_install_flag=`cat /home/estuary_init | grep "post_install_done"`
if [ -z $post_install_flag ]; then
    echo "post_install is beginning ..."
    echo "post_install_done=yes" >> /home/estuary_init
else
    echo "post_install is already done."
fi

# Install Armor Tools packages
# Uncomment below line to install Armor tool's packages.
#INSTALL_ARMOR_TOOLS="YES"
if [ "$INSTALL_ARMOR_TOOLS" = 'YES' ]; then
    Distribution=`cat /etc/issue| cut -d' ' -f 1`
    echo $Distribution
    echo "Install debug tools packages..." 

    case "$Distribution" in
        Ubuntu) #echo "Ubuntu Distribution"
            #INT01
            apt-get install -y sysstat  # sar
            apt-get install -y gdb  
            apt-get install -y iptables  
           
            #INT02
            apt-get install -y  dstat  
            apt-get install -y iotop  
            apt-get install -y blktrace  
            apt-get install -y nicstat  
            apt-get install -y libconfig9  
            apt-get install -y lldpad  
            apt-get install -y oprofile  
            apt-get install -y latencytop 
            apt-get install -y systemtap  
            apt-get install -y crash 
	    #Install perf tool
	    apt-get install -y linux-tools-3.19.0-23 
            ;;
           
        Fedora) #echo "Fedora Distribution"
            #INT01
            dnf install -y sysstat.aarch64 # sar
            dnf install -y dmidecode.aarch64
            dnf install -y tcpdump.aarch64
            dnf install -y ethtool.aarch64
           
            #INT02
            dnf install -y dstat
            dnf install -y tiptop.aarch64
            dnf install -y iotop.noarch
            dnf install -y blktrace.aarch64
            dnf install -y nicstat.aarch64
            dnf install -y lldpad.aarch64
            dnf install -y oprofile.aarch64
            dnf install -y latencytop.aarch64
            dnf install -y systemtap.aarch64
            dnf install -y crash.aarch64
            ;;
         
        OpenSuse) #echo "OpenSuse Distribution"
            #INT01
            zypper install -y ltrace
            zypper install -y pcp-import-iostat2pcp # for sar, iostat etc.
            zypper install -y dmidecode
            zypper install -y strace
            zypper install -y net-tools-deprecated
            zypper install -y net-tools
            
            #INT02
            zypper install -y dstat 
            zypper install -y procps
            zypper install -y iotop
            zypper install -y blktrace
            zypper install -y oprofile
            zypper install -y systemtap
            ;;
        esac
        echo "Finished installation of Armor tools packages" 
    fi

