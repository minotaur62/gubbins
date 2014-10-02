#!/usr/bin/ruby

require 'zlib'

class CollectData
  
  attr_accessor :wan_name,:lan_name,:wan_mac,:lan_mac,:serial,:system_type,:machine_type,:machine_type,:nvs,:wvs,:sync,:version,:api_url,:health_url,:external_server
  
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
    @version = '1.3'
    @api_url = "https://api.polkaspots.com"
    @health_url = "http://health.polkaspots.com/api/v1/health"
    @external_server = "8.8.8.8"
  end   

  def get_wan_name
    `/sbin/uci -P/var/state get network.wan.ifname | awk '{printf("%s",$all)}'`
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

  def wan_status
    @eth = @wan_name.split('-').join('')
    a = `dmesg | grep #{@eth} | tail -1`
    a[/link (\S+)/,1]
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

  def can_ping_ip(ip)
    `ping  -c 1 #{ip}`
     return "success" if $? == 0      
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

  def expected_response
    ["200", "201", "404", "500"].include? check_success_url(@api_url)
  end

  def run
    system 'touch /tmp/gubbins.lock'
    expected_response ? heartbeat : run_in_loop
  end
 
  def run_in_loop 
    i=0
    loop do
      i+=1
      offline_diagnosis(i)
      sleep 15
      if $live == true
        change_back
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

  def change_back
    puts "Make sure all the config is restored"
  end

  def offline_diagnosis(interval) 
    if wan_interface_is_down
      log_to_syslog_and_status_file(interval)
    elsif no_wan_ip
      log_to_syslog_and_rm_network_file(interval)
    elsif gateway_is_down
      log_gateway_failure(interval)
    elsif external_server_is_down
      kill_chilli_and_change_logins(interval)
    else
      restore_config_and_set_live
    end
  end

  def wan_interface_is_down
    @wan_interface_status != "up"
  end

  def log_to_syslog_and_status_file(interval)
    log_interface_change if interval == 2   
  end

  def no_wan_ip
    @wan_ip = get_wan_ip(get_wan_name)
    wan_response = can_ping_ip(@wan_ip)
    wan_response != "success"
  end

  def log_to_syslog_and_rm_network_file(interval)
    if interval == 2 
      log_lost_ip
    elsif interval == 5 && is_static
      logger("network file changed")
      `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
    end
  end

  def gateway_is_down
    gw_response = can_ping_ip(@gateway)
    gw_response != "success" 
  end

  def log_gateway_failure(interval)
    log_gateway_failure if interval == 2
  end

  def external_server_is_down
    externalserver_response = can_ping_ip(@external_server)
    externalserver_response != "success"
  end

  def restore_config_and_set_live
    logger("got internet back")
    sync_configs
    `rm -rf /tmp/gubbins.lock`
    $live  = true 
  end

  def sync_configs
    puts "Get sync ??"
    chilli = `cat /etc/chilli/defaults`
    if chilli
      `killall chilli && cp /etc/chilli/online /etc/chilli/default && /etc/init.d/chilli restart`
    end 
  end

  def kill_chilli_and_change_logins(interval)
    if interval == 2
      `killall chilli && cp /etc/chilli/default /etc/chilli/online  && cp /etc/chilli/no_internet /etc/chilli/defaults && /etc/init.d/chilli restart`
    end 
  end 

  def logger(msg)
    `logger #{msg}`
  end

  def log_to_syslog_and_rm_network_file
    `logger network file changed`
    `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
  end

  def check_success_url(url)                                                                                                                                
    %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{@url}"}                                                
  end

  def post_url_check
    check_success_url(@api_url)
  end 
  
  def heartbeat
    if post_url_check == 200
      compress_data
      post_data
    end
    `rm -rf /tmp/gubbins.lock`
  end 

  def compress_data
    data = "{\"data\":{\"serial\":\"#{@serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{@lan_mac}\",\"system\":\"#{@system_type}\",\"machine_type\":\"#{@machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{@wan_name}\",\"wan_ip\":\"#{get_wan_ip(@wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{@version}\",\"chilli\":\"#{chilli_list}\",\"logs\":\"#{@logs}\",\"prefs\":#{@prefs}}, \"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
    Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
  end 

  def post_data
    `curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' -F 'ca=#{@ca}' #{@api_url}/api/v1/nas/gubbins -k | ash`
    `rm -rf /etc/status`   
    `rm -rf /tmp/gubbins.lock`
  end
  
end 

 # if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 60)
 #   puts "Already testing the connectivity"
 # else
 #   CollectData.new.run
 # end
