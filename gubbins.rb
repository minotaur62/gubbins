#!/usr/bin/ruby

require 'zlib'

class DataCollector
                     
  def initialize
    @wan_name = get_wan_name
    @lan_name = get_lan_name
    @wan_mac = wan_mac(@wan_name)
    @lan_mac = lan_mac(@lan_name)
    @serial = get_serial
    @system_type = get_system_type
    @machine_type = get_machine_type
    @nvs = get_nvs
    @wvs = get_wvs
    @sync = get_sync
    @version = '1.3.2'
    @api_url = "https://api.polkaspots.com"
    @health_url = "http://health.polkaspots.com/api/v1/health"
    @firmware = firmware
    @ca = ca_checksum
    @prefs= get_prefs
    @logs= read_logfile
    @tun_ip = get_tun_ip("tun5")
    @dhcp_leases = read_dhcp_leases
  end   

  def get_wan_name
    f = `/sbin/uci -P/var/state get network.wan.ifname`
    if ($? !=0) || (f.include?("not"))
      `jffs2reset -y || firstboot && /sbin/reboot`
    end 
    return f
  end

  def get_wan_ip(device)
    f = `/sbin/ifconfig #{device}`
    f[/net addr:(\S+)/,1]
  end 

  def wan_mac(device)
    f = `/sbin/ifconfig #{device}`
    if f.match(/(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)\:(\S+)/)
      "#$1:#$2:#$3:#$4:#$5:#$6"
    end 
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
    f[/machine			: (.*)/, 1]
  end

  def get_system_type
    f = `cat /proc/cpuinfo`
    f = f[/system type		: (.*)/, 1]
    f.split[0..1].join " "
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
    hash = File.open("/tmp/chilli_list", "rb").read
    return hash
    hash.close
  end
  
  def read_dhcp_leases
    file = "/tmp/dhcp/leases"
    if(!(File.file?(file)) || (File.zero?(file)))
      return "no devices connected"
    end 
    dhcp_leases = `cat /tmp/dhcp.leases`
    dhcp_leases.gsub("\n",",")
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
  
  def expected_response
    ["200", "201", "404", "500"].include? check_success_url(@health_url)
  end

  def run
    system 'touch /tmp/gubbins.lock'
    expected_response ? HeartBeat.new.beat : run_in_loop
  end

  def run_in_loop 
    i=0
    loop do
      i+=1
      offline_diagnosis(i)
      sleep 15
      if $live == true
        restore_any_future_changes
        HeartBeat.new.beat
        break
      end
    end
  end

  def is_static
    @prefs= get_prefs
    if @prefs != '"not exists"' 
      string = File.open('/etc/prefs', 'rb') { |file| file.read }
      string.include?("static")
    end 
  end
  
  def offline_diagnosis(interval)
    if OfflineResponder.new.wan_interface_is_down
      Logger.new.log_interface_change if interval == 2
    elsif OfflineResponder.new.no_wan_ip
      Logger.new.log_no_wan_ip if interval == 2
      restore_network_file_from_rom if interval == 5
    elsif OfflineResponder.new.gateway_is_down
      Logger.new.log_gateway_failure if interval == 2
    elsif OfflineResponder.new.external_server_is_down
      change_chilli_logins if interval == 2
    else
      restore_config_and_set_live
    end
  end
  
  def restore_any_future_changes
    puts "Make sure all the config is restored"
  end
    
  def restore_config_and_set_live
    Logger.new.log("got internet back")
    sync_configs
    `rm -rf /tmp/gubbins.lock`
    $live  = true 
  end

  def sync_configs
    puts "Get sync ??"
    file = `/etc/chilli/online`
    if File.file?(file)
      `cp /etc/chilli/online /etc/chilli/default && /etc/init.d/chilli restart`
    end 
  end

  def change_chilli_logins
    `cp /etc/chilli/default /etc/chilli/online && sed -e 's/HS_UAMFORMAT.*/HS_UAMFORMAT=http:\/\/\\$HS_UAMLISTEN\/offline.html/g' /etc/chilli/default && /etc/init.d/chilli restart`
  end 

  def restore_network_file_from_rom
    if is_static
      `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
      `cp /rom/etc/config/dhcp /etc/config/dhcp`
      `rm -rf /etc/config/wireless && /sbin/wifi detect > /etc/config/wireless`
      `/etc/init.d/network restart` 
    end 
  end 

  def check_success_url(url)                                                                                                                                
    %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{url}"}                                                
  end
  
  module WirelessScanner

    def scan_active_interfaces
      @iwinfo = iwinfo
      @iwdump = iwdump
      @scan = airodump
      @wifi_clients = wifi_clients
    end 

    def get_active_wlan
       w = `echo \`ls /sys/class/net | grep w\` | awk '{ print $all }'`
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
    
    def wifi_clients
      `sh /etc/scripts/wificlients.sh`
    end  

  end
  
end 

class Logger
  
  def log(msg)
    `logger #{msg}`
  end
  
  def log_interface_change
    `dmesg | awk -F ] '{"cat /proc/uptime | cut -d \" \" -f 1" | getline st;a=substr( $1,2,length($1) - 1);print strftime("%F %H:%M:%S %Z",systime()-st+a)" -> "$0}' | grep  eth1 | tail -1 | awk ' { print $all  }' > /etc/status`
  end
  
  def log_no_wan_ip
    `echo \`date\` lost ip address  > /etc/status`
  end
  
  def log_gateway_failure
    `echo \`date\` Cannot ping to gateway > /etc/status`
  end
  
end 

class OfflineResponder
  
  def initialize
    @external_server = "8.8.8.8"
    @gateway = gateway
  end 
  
  def wan_status
    @eth = DataCollector.new.get_wan_name.split('-').join('')
    a = `dmesg | grep #{@eth} | tail -1`
    a[/link (\S+)/,1]
  end
  
  def gateway
    `route | grep default | awk ' { print $2 } '`
  end
   
  def wan_interface_is_down
    wan_status != "up"
  end
  
  def can_ping_ip(ip)
    `ping  -c 1 #{ip}`
    return "success" if $? == 0      
  end
  
  def no_wan_ip
    @wan_ip = DataCollector.new.get_wan_ip(DataCollector.new.get_wan_name)
    wan_response = can_ping_ip(@wan_ip)
    wan_response != "success"
  end
  
  def gateway_is_down
    gw_response = can_ping_ip(@gateway)
    gw_response != "success" 
  end
  
  def external_server_is_down
    externalserver_response = can_ping_ip(@external_server)
    externalserver_response != "success"
  end
   
end 
    
class HeartBeat < DataCollector 
  
  include WirelessScanner
    
  def compress_data
    data = "{\"data\":{\"serial\":\"#{@serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{@lan_mac}\",\"system\":\"#{@system_type}\",\"machine_type\":\"#{@machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{@wan_name}\",\"wan_ip\":\"#{get_wan_ip(@wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{@version}\",\"chilli\":\"#{chilli_list}\",\"dhcp_leases\":\"#{@dhcp_leases}\","\"logs\":\"#{@logs}\",\"prefs\":#{@prefs}},\"wifi_clients\":#{@wifi_clients}",\"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
    Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
  end

  def post_data
    `curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{@wan_mac}' -F 'ca=#{@ca}' #{@api_url}/api/v1/nas/gubbins -k | ash`
    `rm -rf /etc/status`   
    `rm -rf /tmp/gubbins.lock`
  end

  def beat
    if check_success_url(@health_url) == "200"
      scan_active_interfaces
      compress_data
      post_data
    end
    `rm -rf /tmp/gubbins.lock`
  end

end
 
 if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 60)
   puts "Already testing the connectivity"
 else   
   DataCollector.new.run
 end