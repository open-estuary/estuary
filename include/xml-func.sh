#!/bin/bash

###################################################################################
# string[] get_field_content <xml_file> <field>
###################################################################################
get_field_content()
{
	local xml_file=$1
	local field=$2
	local xml_content=(`sed -n "/<$field>/,/<\/$field>/p" $xml_file 2>/dev/null | sed -e '/^$/d' | sed 's/ //g'`)
	unset xml_content[0]
	unset xml_content[${#xml_content[@]}]
	echo ${xml_content[*]}
}

