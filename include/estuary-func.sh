#!/bin/bash

###################################################################################
# string get_estuary_version <estuary_dir>
###################################################################################
get_estuary_version()
{
    local version_regexp="(?<=<project name=\"estuary\" revision=\")([^\"]*)(?=\")"
    local default_xml_file="$1/default.xml"
    local current_version=`grep -Po "$version_regexp" $default_xml_file 2>/dev/null | sed 's/.*\///g' 2>/dev/null`
    current_version=${current_version:-master}
    echo $current_version
}

###################################################################################
# print_version <estuary_dir>
###################################################################################
print_version()
{
    local estuary_dir=$1
    local current_version=`get_estuary_version $estuary_dir`
    if [ x"$current_version" = x"master" ]; then
        echo "This is a developing version."
    else
        echo "Estuary version is $current_version."
    fi
}

