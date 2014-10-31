#!/bin/sh
# This script will give you a nice json output of `iw wlan0/1/2 scan`
# Script name : iwscan.sh
# /etc/scripts/iwscan.sh
source /usr/share/libubox/jshn.sh
json_init
interface=$1
printf %s `iwinfo $interface scan` > /tmp/scan
printf %s `iwinfo $interface scan` >> /tmp/scan

if [ -s /tmp/scan ];then
	
	sed -i s/Cell[0-9][0-9]-/\\n/g /tmp/scan
	sed -i 's/Address://g' /tmp/scan
	sed -i 's/ESSID:/ /g' /tmp/scan
	sed -i 's/Mode:/ /g' /tmp/scan
	sed -i 's/Channel:/ /g' /tmp/scan
	sed -i 's/Signal:/ /g' /tmp/scan
	sed -i 's/Quality:/ /g' /tmp/scan
	sed -i 's/Encryption:/ /g' /tmp/scan
	awk '!x[$1]++' /tmp/scan > /tmp/r_scan
	rm -rf /tmp/scan
	sed -i '/^\s*$/d' /tmp/r_scan
	sed -i ':a;N;$!ba;s/\n/,/g' /tmp/r_scan
	
	while read line
	do
		json_add_string "scan:" "$line"
		scan_result=`json_dump`
		printf %s $scan_result
	done < /tmp/r_scan
	
else
	json_add_string "scan:" "No results"
	scan_result=`json_dump`
	printf %s $scan_result
fi
rm -rf /tmp/r_scan
