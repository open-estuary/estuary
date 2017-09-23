#!/bin/bash -xe


top_dir=$(cd `dirname $0`; cd ..; pwd)
workspace=${top_dir}/build

find ${workspace} -type d -name debian |xargs rm -rvf
echo "clean debian done."
