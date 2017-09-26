#!/bin/bash -xe

set -ex

top_dir=$(cd `dirname $0`; cd ..; pwd)
build_dir=$(cd /root/$2 && pwd)
version=$1 # branch or tag

workspace=${build_dir}/out/release/${version}/debian

. ${top_dir}/include/checksum-func.sh

cal_md5sum ${workspace}
