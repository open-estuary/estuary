#!/bin/bash

###################################################################################
# print_version <estuary_dir>
###################################################################################
print_version()
{
	local version_regexp="(?<=<project name=\"estuary\" revision=\")([^\"]*)(?=\")"
	local default_xml_file="`dirname $1`/default.xml"
	local current_version=`grep -Po "$version_regexp" $default_xml_file 2>/dev/null | sed 's/.*\///g' 2>/dev/null`
	if [ x"$current_version" = x"" ]; then
		echo "This is a developing version."
	else
		echo "Estuary version is $current_version."
	fi
}

