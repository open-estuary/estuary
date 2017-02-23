#!/bin/bash

###################################################################################
# get_pxe_tftproot <__tftproot>
###################################################################################
get_pxe_tftproot()
{
    local __tftproot=$1
    local tftproot=""
    echo "--------------------------------------------------------------------------------"
    echo "Which directory do you want to be your tftp root directory? (if this directory does not exist it will be created for you)"
    echo "--------------------------------------------------------------------------------"
    read -p "[ /var/lib/tftpboot ] " tftproot
    if [ x"$tftproot" = x"" ]; then
        tftproot="/var/lib/tftpboot"
    fi

    eval $__tftproot="$tftproot"
    return 0
}

###################################################################################
# get_pxe_nfsroot <__nfsroot>
###################################################################################
get_pxe_nfsroot()
{
    local __nfsroot=$1
    local nfsroot=""
    echo "--------------------------------------------------------------------------------"
    echo "Which directory do you want to be your nfs root directory? (if this directory does not exist it will be created for you)"
    echo "--------------------------------------------------------------------------------"
    read -p "[ /var/lib/nfsroot ] " nfsroot
    if [ x"$nfsroot" = x"" ]; then
        nfsroot="/var/lib/nfsroot"
    fi

    eval $__nfsroot="'$nfsroot'"
    return 0
}

###################################################################################
# get_pxe_interface <__interface>
###################################################################################
get_pxe_interface() {
    local __interface=$1
    local netcard_name=
    local netcard_idx=1
    local netcard_count=`ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | \
        grep -v "Bcast:0.0.0.0" | grep -P "^(eth).*" | wc -l`
    if [ $netcard_count -eq 0 ]; then
        echo "Please setup netcard at first!" ; exit 1
    elif [ $netcard_count -gt 1 ]; then
        echo "--------------------------------------------------------------------------------"
        echo "Which network card do you want to bind to the PXE (the board will connect into the same local area network)"
        echo "--------------------------------------------------------------------------------"
        while true; do
            echo -e "\nPlease choise the network card needed: \n"
            ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}'
            echo " "
            read -p 'Enter Device Number or 'q' to exit: ' netcard_idx
            echo " "
            if expr $netcard_idx + 0 &>/dev/null; then
                if [ $netcard_idx -ge 1 ] && [ $netcard_idx -le $netcard_idx ]; then
                    break
                fi
            elif [ x"$netcard_count" = x"q" ]; then
                return 1
            fi
        done
    fi

    netcard_name=`ifconfig -a | grep -A 1 eth | grep -B 1 "inet addr" | grep -v "Bcast:0.0.0.0" | awk 'BEGIN{FS="\n";OFS=") ";RS="--\n"} {print NR,$0}' | \
        grep -Po "(?<=${netcard_idx}\) )(eth[^ ]*)"`
    if [ x"$netcard_name" = x"" ]; then
        return 1
    else
        eval $__interface="'$netcard_name'"
        return 0
    fi
}
