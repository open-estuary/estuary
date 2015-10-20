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
            apt-get install sysstat  # sar
            apt-get install gdb  
            apt-get install iptables  
           
            #INT02
            apt-get install dstat  
            apt-get install iotop  
            apt-get install blktrace  
            apt-get install nicstat  
            apt-get install libconfig9  
            apt-get install lldpad  
            apt-get install oprofile  
            apt-get install latencytop 
            apt-get install systemtap  
            apt-get install crash 
	    #Install perf tool
	    apt-get install linux-tools-3.19.0-23 
            ;;
           
        Fedora) #echo "Fedora Distribution"
            #INT01
            dnf install sysstat.aarch64 # sar
            dnf install dmidecode.aarch64
            dnf install tcpdump.aarch64
            dnf install ethtool.aarch64
           
            #INT02
            dnf install dstat
            dnf install tiptop.aarch64
            dnf install iotop.noarch
            dnf install blktrace.aarch64
            dnf install nicstat.aarch64
            dnf install lldpad.aarch64
            dnf install oprofile.aarch64
            dnf install latencytop.aarch64
            dnf install systemtap.aarch64
            dnf install crash.aarch64
            ;;
         
        OpenSuse) #echo "OpenSuse Distribution"
            #INT01
            zypper install ltrace
            zypper install pcp-import-iostat2pcp # for sar, iostat etc.
            zypper install dmidecode
            zypper install strace
            zypper install net-tools-deprecated
            zypper install net-tools
            
            #INT02
            zypper install dstat 
            zypper install procps
            zypper install iotop
            zypper install blktrace
            zypper install oprofile
            zypper install systemtap
            ;;
        esac
        echo "Finished installation of Armor tools packages" 
    fi

