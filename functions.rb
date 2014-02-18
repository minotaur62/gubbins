#!/usr/bin/ruby
# Copyright (c) 2013 PolkaSpots Limited
# Use this, change things but don't claim it's yours

def get_wan_name
  return `/sbin/uci -P/var/state get network.wan.ifname`
end

def get_wan_ip(device)
 f = `/sbin/ifconfig #{device}`
 return f[/inet addr:(\S+)/,1]
end

def wan_mac(device)
 f = `/sbin/ifconfig #{device}`
 if f.match(/(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)/)
  return "#$1:#$2:#$3:#$4:#$5:#$6"
 end
end

def wan_status
  @eth = $wan_name.split(' ').join('')
  a = `dmesg | grep #{@eth} | tail -1`
  return a[/link (\S+)/,1]
end

def get_lan_name
 return `/sbin/uci -P/var/state get network.lan.ifname`
end

def lan_mac(device)
 f = `/sbin/ifconfig #{device}`
 if f.match(/(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)/)
  return "#$1:#$2:#$3:#$4:#$5:#$6"
 end
end

def get_tun_ip(device)
 begin
  f = `/sbin/ifconfig #{device}`
  f = f[/inet addr:(\S+)/,1]
  f.match(/(\S+)\.(\S+)\.(\S+)\.(\S+)/)
  return f
 rescue
  f = 'no_vpn'
 end
end

def get_machine_type
 f = `cat /proc/cpuinfo`
 return f[/machine			: (.*)/, 1]
end

def get_system_type
 f = `cat /proc/cpuinfo`
 f = f[/system type		: (.*)/, 1]
 return f.split[0..1].join " "
end

def uptime
 f = `uptime`
 return f.gsub(" ", "%20")
end

def get_serial
 f = `cat /etc/serial`
 return f.split("\n").first
end

def get_nvs
 f = `cat /etc/nvs`
 return f.split("\n").first
end

def get_wvs
 f = `cat /etc/wvs`
 return f.split("\n").first
end

def get_sync
 f = `cat /etc/sync`
 return f.split("\n").first
end

def chilli_list
  system `chilli_query list | awk '{printf ("%s,", $1 "%20" $2 "%20" $3 "%20" $4 "%20" $6 "%20" $8 "%20" $9)}' > /tmp/chilli_list`
  hash = File.open("/tmp/chilli_list", "rb").read
  return hash
  hash.close
end

def firmware
  f = `cat /etc/openwrt_version | awk '{printf("%s",$all)}'`
end

def get_active_wlan
  w = `echo \`ls /sys/class/net | grep w\` | awk '{ print $all }'`
end   
  
def gateway
 `route | grep default | awk ' { print $2 } '`
end

def iwinfo
  `sh /etc/scripts/iwinfo.sh #{get_active_wlan}`
end

def iwdump(interface)
  `sh /etc/scripts/iwdump.sh`
end

def airodump
 `sh /etc/scripts/airodump.sh`
end

$wan_name = get_wan_name
$lan_name = get_lan_name
$wan_mac = wan_mac($wan_name)
$lan_mac = lan_mac($lan_name)
$serial = get_serial
$system_type = get_system_type
$machine_type = get_machine_type
$nvs = get_nvs
$wvs = get_wvs
$sync = get_sync
$version = '1.3'
