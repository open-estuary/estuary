#!/bin/bash -xe
set -ex
top_dir=$(cd `dirname $0`; cd ..; pwd)
workspace=$(cd /root/$2 && pwd)

# Update fedora repo
. ${top_dir}/include/mirror-func.sh
set_fedora_mirror

dnf install -y findutils
find ${workspace} -type d -iname fedora |xargs rm -rvf
echo "clean fedora done."
