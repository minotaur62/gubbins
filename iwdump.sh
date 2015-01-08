#!/bin/sh
# This script will give you a nice json output of `iw wlan0 station dump`
# Script name : iwdump
# /etc/scripts/iwdump.sh

get_iwdump() {

iw dev $interface station dump > /tmp/connected_clients
#if [[ -s /tmp/wireless_clients ]] ; then
#echo "NO clients connected so file is empty"
#fi space  sed 's/ //g'
sed -i 's/\t//g' /tmp/connected_clients
sed -i 's/tx//g' /tmp/connected_clients
sed -i 's/rx//g' /tmp/connected_clients
sed -i 's/bitrate://g' /tmp/connected_clients
sed -i 's/failed://g' /tmp/connected_clients
sed -i 's/signal avg://g' /tmp/connected_clients
sed -i 's/TDLS peer:/ /g' /tmp/connected_clients
sed -i 's/MFP:/ /g' /tmp/connected_clients
sed -i 's/preamble:/ /g' /tmp/connected_clients
sed -i 's/authenticated:/ /g' /tmp/connected_clients
sed -i 's/authorized:/ /g' /tmp/connected_clients
sed -i 's/bitrate://g' /tmp/connected_clients
sed -i 's/inactive time:/ /g' /tmp/connected_clients
sed -i 's/bytes://g' /tmp/connected_clients
sed -i 's/retries://g' /tmp/connected_clients
sed -i 's/signal://g' /tmp/connected_clients
sed -i 's/packets://g' /tmp/connected_clients
sed -i 's/retries://g' /tmp/connected_clients
sed -i 's/inactive time://g' /tmp/connected_clients
sed -i 's/preamble:/ /g' /tmp/connected_clients
sed -i 's/WMM\/WME:/ /g' /tmp/connected_clients
sed -i ':a;N;$!ba;s/\n//g' /tmp/connected_clients
sed -i 's/MBit\/s MCS//g' /tmp/connected_clients
sed -i 's/dBm//g' /tmp/connected_clients
sed -i 's/MBit\/s//g' /tmp/connected_clients
sed -i 's/ms//g' /tmp/connected_clients
sed -i 's/:space://g' /tmp/connected_clients
sed -i 's/,//g' /tmp/connected_clients
sed -i 's/)//g' /tmp/connected_clients
sed -i 's/Station\+/\n&/g' /tmp/connected_clients
sed -i '/^\s*$/d' /tmp/connected_clients


while read line
do
print_station_mac=`echo $line | grep Station | awk '{print $2}'`
print_single_line=`echo $line | awk '{for (i = 5; i <= NF; i++) printf $i "," }'`
echo $print_station_mac,$print_single_line
done < /tmp/connected_clients
rm -rf /tmp/connected_clients
}

source /usr/share/libubox/jshn.sh
json_init
for var in "$@"
do
interface=`echo $var`
result=$(get_iwdump $interface)
json_add_string "$var" "$result"
done	
MSG=`json_dump`
printf %s $MSG

