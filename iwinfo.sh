#!/bin/sh
# This script will give you a nice json output of `iwinfo wlan0 info`
# Script name : iwinfo.sh
# /etc/scripts/iwinfo.sh

get_iwinfo() {
iwinfo $interface info > /tmp/iwinfo
ssid_name=`cat /tmp/iwinfo | grep ESSID | tr -d '"'| cut -d ':' -f2`
device_mac=`cat /tmp/iwinfo | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
ap_channel_mode=`cat /tmp/iwinfo | grep "Mode:" | awk '{ print $4}'`
tx_power_link_quality=`cat /tmp/iwinfo | grep "Tx-Power:" | awk '{ print $2 "," $6}'`
signal_noise=`cat /tmp/iwinfo | grep "Signal" | awk '{ print $2 "," $4$5}'`
bit_rate=`cat /tmp/iwinfo | grep "Bit Rate:" | awk '{ print $3}'`
encryption=`cat /tmp/iwinfo | grep "Encryption:" | awk '{print $2}'`
type_HW_mode=`cat /tmp/iwinfo | grep  "Type:" | awk '{ print $2 " " $5}'`
hardware=`cat /tmp/iwinfo | grep "Hardware:" | awk '{ print $2 $3 " " $4 $5}'`
tx_power=` cat /tmp/iwinfo | grep "TX power" | awk '{print $4}'`
frequency=`cat /tmp/iwinfo | grep "Frequency" | awk '{print $3}'`
support_wpa=`cat /tmp/iwinfo | grep "Supports" | awk '{print $3}'`
result=`echo $ssid_name,$device_mac,$ap_channel_mode,$tx_power_link_quality,$signal_noise,$bit_rate,$encryption,$type_HW_mode,$hardware,$tx_power,$frequency,$support_wpa`

echo $result
rm -rf /tmp/iwinfo
}

source /usr/share/libubox/jshn.sh
json_init
#json_add_object "iwinfo"
for var in "$@"
do
interface=`echo $var`
result=$(get_iwinfo $interface)
json_add_string "$var" "$result"
done
json_close_object
iwinfo=`json_dump`
printf %s $iwinfo
