#!/bin/bash
post_install_flag=`cat /home/estuary_init | grep "post_install_done"`
if [ -z $post_install_flag ]; then
    echo "post_install is beginning ..."
    echo "post_install_done=yes" >> /home/estuary_init
else
    echo "post_install is already done."
fi
