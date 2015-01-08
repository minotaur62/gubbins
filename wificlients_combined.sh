#!/bin/sh
# This script will give you a nice json output of connected wireless clients list
# Script name : wificlients.sh
# /etc/scripts/wificlients.sh
source /usr/share/libubox/jshn.sh
json_init
json_add_string "version" "0.1"
json_add_string "timestamp" `date +%s`
json_add_object "interfaces"
for interface in `iw dev | grep Interface | cut -f 2 -s -d" "`
do
        json_add_object "$interface"
        maclist=`iw dev $interface station dump | tee -a /tmp/wifi_clients | grep Station | cut -f 2 -s -d" "`
        sed -i 's/ //g' /tmp/wifi_clients
				sed -i ':a;N;$!ba;s/\n/,/g' /tmp/wifi_clients
				sed -i 's/Station\+/\n&/g' /tmp/wifi_clients
				sed -i '/^\s*$/d'  /tmp/wifi_clients
				sed -i 's/\t//g' /tmp/wifi_clients
        for mac in $maclist
        do
                ip="UNKN"
                host=""
                dump=`iw dev $interface station get $mac | sed 's/\t//g'`
                ip=`cat /tmp/dhcp.leases | cut -f 2,3,4 -s -d" " | grep $mac | cut -f 2 -s -d" "`
                host=`cat /tmp/dhcp.leases | cut -f 2,3,4 -s -d" " | grep $mac | cut -f 3 -s -d" "`
                var=$ip","$host","$dump
                json_add_string "$mac" "$var"
                done
        json_close_object
				rm -rf /tmp/wifi_clients
done

json_close_object
MSG=`json_dump`
printf %s $MSG