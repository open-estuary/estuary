#!/bin/bash -xe
set -ex
top_dir=$(cd `dirname $0`; cd ..; pwd)
workspace=$(cd /root/$2 && pwd)

find ${workspace} -type d -iname fedora |xargs rm -rf
echo "clean fedora done."
