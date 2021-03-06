#!/usr/bin/ruby
# Copyright (c) 2013 PolkaSpots Limited
# Use this, change things but don't claim it's yours

class Boxvalues
  
def get_wan_name
  return `/sbin/uci -P/var/state get network.wan.ifname | awk '{printf("%s",$all)}'`
end

def get_wan_ip(device)
 f = `/sbin/ifconfig #{device}`
 return f[/inet addr:(\S+)/,1]
end

def wan_mac(device)
 f = `/sbin/ifconfig #{device}`
 if f.match(/(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)/)
   "#$1:#$2:#$3:#$4:#$5:#$6"
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
  "#$1:#$2:#$3:#$4:#$5:#$6"
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
    uptime = f.gsub(" ", "%20").gsub("\n","")          
    seconds = `cat /proc/uptime`                       
    seconds = seconds.split(' ').first.gsub("\n","")   
    return "#{uptime}, #{seconds}"                     
end

def get_serial
 f = `cat /etc/serial`
 return f.split("\n").first
end

def get_nvs
 file="/etc/nvs"
 if File.file?(file)  
   f = `cat /etc/nvs`
   return f.split("\n").first
  end 
end

def get_wvs
 file="/etc/wvs"
 if File.file?(file)   
   f = `cat /etc/wvs`
   return f.split("\n").first
 end   
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


def get_prefs
 file="/etc/prefs"
  if File.file?(file)
    pref = `cat /etc/prefs`
    pref.gsub("\n","") 
  else 
  return '"not exists"'
  end
end

def ca_checksum                                                                                                                   
  file = "/etc/openvpn/ca.crt"                                                                                                    
  if File.file?(file)                                                                                                             
    cksum = `openssl md5 /etc/openvpn/ca.crt | sed "s/^.*= *//"`                                                                  
    cksum.gsub("\n","")                                                                                                           
  end                                                                                                                             
end

def read_logfile
  file = "/etc/status"
  if File.file?(file)
    log =`cat /etc/status`
    log.gsub("\n",",")
  end
end 



def iwinfo
  `sh /etc/scripts/iwinfo.sh #{get_active_wlan}`
end

def iwdump
  `sh /etc/scripts/iwdump.sh #{get_active_wlan}`
end

def airodump
 `sh /etc/scripts/airodump.sh`
end

end 

def get_icmp_response(ip)
 `ping  -c 1 #{ip}`
 if $? == 0
   return "success"
 else   
  return "failure"
 end      
end 
 
def log_interface_change
  `dmesg | awk -F ] '{"cat /proc/uptime | cut -d \" \" -f 1" | getline st;a=substr( $1,2,length($1) - 1);print strftime("%F %H:%M:%S %Z",systime()-st+a)" -> "$0}' | grep  eth1 | tail -1 | awk ' { print $all  }' >> /etc/status`
end  
 
def log_lost_ip
  `echo \`date\` lost ip address  >> /etc/status`  
end 
 
def log_gateway_failure
  `echo \`date\` Cannot ping to gateway >> /etc/status`
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
