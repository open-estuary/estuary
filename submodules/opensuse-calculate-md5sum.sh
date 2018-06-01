#!/bin/bash -xe

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag

workspace=${build_dir}/out/release/${version}/OpenSuse

. ${top_dir}/include/checksum-func.sh

rm -f $workspace/*.MD5SUM
cal_md5sum ${workspace}
