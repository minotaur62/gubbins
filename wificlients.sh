#!/bin/sh
# This script will give you a nice json output of connected wireless clients list
# Script name : wificlients.sh
# /etc/scripts/wificlients.sh
source /usr/share/libubox/jshn.sh
json_init
for interface in `iw dev | grep Interface | cut -f 2 -s -d" "`
do
	json_add_object "$interface"
	maclist=`iw dev $interface station dump | grep Station | cut -f 2 -s -d" "`
	for mac in $maclist
	do
		ip="UNKN"
		host=""
		ip=`cat /tmp/dhcp.leases | cut -f 2,3,4 -s -d" " | grep $mac | cut -f 2 -s -d" "`
		host=`cat /tmp/dhcp.leases | cut -f 2,3,4 -s -d" " | grep $mac | cut -f 3 -s -d" "`
		var=$ip" "$host" "$mac
		echo $var
		json_add_string "$mac" "$var"
		done
done
json_close_object
MSG=`json_dump`
echo $MSG





