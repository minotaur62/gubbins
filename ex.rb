#!/usr/bin/ruby

require 'zlib'

class DataCollector
  
  def initialize
    $wan_name = get_wan_name
    $lan_name = get_lan_name
    $wan_mac = interface_mac($wan_name)
    $lan_mac = interface_mac($lan_name)
    $system_type = get_system_type
    $machine_type = get_machine_type
    $external_server = "8.8.8.8"
    $version = '1.3.5'
    $api_url = "https://api.polkaspots.com"
    $health_url = "http://health.polkaspots.com/api/v1/health"
    @serial = get_serial
    @nvs = get_nvs
    @wvs = get_wvs
    @sync = get_sync
    @firmware = firmware
    @ca = ca_checksum
    @prefs= get_prefs
    @logs= read_logfile
    @tun_ip = get_tun_ip("tun5")
    @iwinfo = iwinfo
    @iwscan = iwscan
    @wifi_clients = wifi_clients
  end  
  
  def get_wan_name
    f = `/sbin/uci -P/var/state get network.wan.ifname`
    if ($? !=0) || (f.include?("not"))
      `jffs2reset -y || firstboot && /sbin/reboot`
    end
    f.split("\n").first
  end
   
  def get_lan_name
    return `/sbin/uci -P/var/state get network.lan.ifname`
  end
  
  def interface_mac(device)
    f = `/sbin/ifconfig #{device}`
    if f.match(/(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)/)
      "#$1:#$2:#$3:#$4:#$5:#$6"
    end
  end

  def get_system_type
    f = `cat /proc/cpuinfo`
    f = f[/system type		: (.*)/, 1]
    f.split[0..1].join " "
  end 

  def get_machine_type
    f = `cat /proc/cpuinfo`
    f[/machine			: (.*)/, 1]
  end 

  def get_wan_ip(device)
    f = `/sbin/ifconfig #{device}`
    f[/net addr:(\S+)/,1]
  end

  def get_lan_name
    return `/sbin/uci -P/var/state get network.lan.ifname`
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
    f[/machine			: (.*)/, 1]
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
    f.split("\n").first
  end

  def get_nvs
    file="/etc/nvs"
    if File.file?(file)
      f = `cat /etc/nvs`
      f.split("\n").first
    end
  end

  def get_wvs
    file="/etc/wvs"
    if File.file?(file)
      f = `cat /etc/wvs`
      f.split("\n").first
    end
  end

  def get_sync
    f = `cat /etc/sync`
    f.split("\n").first
  end

  def chilli_list
    system `chilli_query list | awk '{printf ("%s,", $1 "%20" $2 "%20" $3 "%20" $4 "%20" $6 "%20" $8 "%20" $9)}' > /tmp/chilli_list`
    file = File.open("/tmp/chilli_list", "rb")
    hash = file.read
    file.close
    return hash
  end

  def firmware
    f = `cat /etc/openwrt_version | awk '{printf("%s",$all)}'`
  end

  def get_prefs
    file="/etc/prefs"
    if File.file?(file)
      pref = `cat /etc/prefs`
      pref.gsub("\n","")
    else
      return '"DNE"'
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
  
  def connectivity_check
     puts external_server_is_down 
     external_server_is_down ? run_in_loop : health_check
  end 

  def health_check
    response_code = check_success_url($health_url)
    puts response_code
    unless ["200", "201", "404", "500"].include? response_code
      puts "Health check failed, exiting."
      `rm -rf /tmp/gubbins.lock`
      exit
    end 
      puts "doing healthcheck"  
      system 'touch /tmp/gubbins.lock'
      beat 
  end
  
  def run_in_loop
   puts "I am executing"
    i=0
    loop do
      i+=1
      puts i 
      offline_diagnosis(i)
      sleep 15
      if $live == true
        restore_any_future_changes
        beat
        break
      end
    end
  end

  def is_static
    @prefs= get_prefs
    if @prefs != '"DNE"'
      file = File.open('/etc/prefs', 'rb')
      string = file.read
      file.close
      string.include?("static")
    end
  end

  def offline_diagnosis(interval)
    if wan_interface_is_down
      puts wan_interface_is_down  
      puts "wan_is_down" 
      log_interface_change if interval == 2
    elsif no_wan_ip
       puts "no Wan : #{no_wan_ip} " 
      log_no_wan_ip if interval == 2
      restore_network_file_from_rom if interval == 5
    #elsif gateway_is_down
     #  puts gateway_is_down
     # log_gateway_failure if interval == 2  
    elsif external_server_is_down
      puts "respomnd #{external_server_is_down}"
      puts "No external"  
      change_chilli_logins if interval == 2
    else  
      restore_config_and_set_live
  end
  end 

  def restore_any_future_changes
    puts "Make sure all the config is restored"
  end

  def restore_config_and_set_live
    `logger got internet back`
    sync_configs
    `rm -rf /tmp/gubbins.lock`
    $live  = true
  end

  def sync_configs
    puts "change the chilli configs back"
    file = "/etc/chilli/online"
    if File.file?(file)
      `cp /etc/chilli/online /etc/chilli/defaults && /etc/init.d/chilli restart`
    end
  end

  def change_chilli_logins
    `cp /etc/chilli/defaults /etc/chilli/online && sed -e 's/HS_UAMFORMAT.*/HS_UAMFORMAT=http:\/\/\\$HS_UAMLISTEN\/offline.html/g' /etc/chilli/defaults && /etc/init.d/chilli restart`
  end

  def restore_network_file_from_rom
    if is_static
      `rm -rf /etc/config/network && /rom/etc/uci-defaults/02_network`
      `cp /rom/etc/config/dhcp /etc/config/dhcp`
      `rm -rf /etc/config/wireless && /sbin/wifi detect > /etc/config/wireless`
      `/etc/init.d/network restart`
    end
  end

  def check_success_url(url)
    %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{url}"}
  end

  def active_wlan_name
    @active_wlan_name ||= `echo \`ls /sys/class/net | grep wlan\` | awk '{ print $all }'`
  end

  def iwscan
    File.file?("/etc/scripts/iwscan.sh") ? `sh /etc/scripts/iwscan.sh #{active_wlan_name}` : '"DNE"'
  end

  def iwinfo
    File.file?("/etc/scripts/iwinfo.sh") ? `sh /etc/scripts/iwinfo.sh #{active_wlan_name}` : '"DNE"'
  end

  def airodump
    File.file?("/etc/scripts/airodump") ? `sh /etc/scripts/airodump.sh` : '"DNE"'
  end

  def wifi_clients
    File.file?("/etc/scripts/wificlients.sh") ? `sh /etc/scripts/wificlients.sh` : '"DNE"'
  end

  def log(msg)
    `logger #{msg}`
  end

  def log_interface_change
    `dmesg | awk -F ] '{"cat /proc/uptime | cut -d \" \" -f 1" | getline st;a=substr( $1,2,length($1) - 1);print strftime("%F %H:%M:%S %Z",systime()-st+a)" -> "$0}' | grep  #{$wan_name} | tail -1 | awk ' { print $all  }' > /etc/status`
  end

  def log_no_wan_ip
    `echo \`date\` lost ip address  > /etc/status`
  end

  def log_gateway_failure
    `echo \`date\` Cannot ping to gateway > /etc/status`
  end

  def wan_status
    a = `dmesg | grep #{$wan_name} | tail -1`
    a[/link (\S+)/,1]
  end

  def gateway
    `route | grep default | awk ' { print $2 } '`
  end

  def wan_interface_is_down
    puts wan_status 
    wan_status == "down" ? true : false
  end

  def can_ping_ip(ip)
    `ping  -c 1 #{ip}`
    return "success"  if $? == 0
  end

  def no_wan_ip 
    @wan_ip = get_wan_ip($wan_name)
    wan_response = can_ping_ip(@wan_ip)
    puts @wan_ip
    wan_response == "success" ? false : true
  end

  def gateway_is_down
    gw_response = can_ping_ip(@gateway)
    gw_response == "success" ? false : true
  end

  def external_server_is_down
   external_server_response = can_ping_ip($external_server)
   external_server_response == "success" ? false : true
  end

  def compress_data
    data = "{\"data\":{\"serial\":\"#{@serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{$wan_name}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\",\"logs\":\"#{@logs}\",\"prefs\":#{@prefs}},\"wifi_clients\":#{@wifi_clients},\"iwinfo\":#{@iwinfo},\"iwscan\":#{@iwscan}}"
    Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
  end

  def post_data
    `curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' -F 'ca=#{@ca}' #{$api_url}/api/v1/nas/gubbins -k | ash`
    `rm -rf /etc/status`
    `rm -rf /tmp/gubbins.lock`
  end

  def beat
    if check_success_url($health_url) == "200"
      compress_data
      post_data
    end
    `rm -rf /tmp/gubbins.lock`
  end
  
end

if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 180)
puts "Already testing the connectivity"
else
DataCollector.new.connectivity_check
end


