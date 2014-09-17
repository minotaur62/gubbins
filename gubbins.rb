#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

require '/etc/scripts/functions.rb'
require 'zlib'

class GoGoGubbins
  
  def initialize
    @api_url = "https://api.polkaspots.com"
    @health_url = "http://health.polkaspots.com/api/v1/health"
    @external_server = "8.8.8.8"
    @tun_ip = get_tun_ip('tun5')
    @sync = get_sync
    @nvs = get_nvs
    @wvs = get_wvs
    @uptime = uptime
    @iwinfo = iwinfo
    @iwdump = iwdump
    @firmware = firmware
    @scan = airodump
    @ca = ca_checksum
    @prefs= get_prefs
    @logs=read_logfile
  end
  
  def check_connectivity_and_heartbeat
    system 'touch /tmp/gubbins.lock'
    response = check_success_url
    if ["200", "201", "404", "500"].include? response 
      run_heartbeat
    else
      i=0
      loop do
        i+=1
        check_status(i)
        sleep 15
        if $live == true
          change_back
          break
        end
      end
    end
  end

  def static_dynamic
    @prefs= get_prefs
    if @prefs != '"not exists"' 
      string = File.open('/etc/prefs', 'rb') { |file| file.read }
      if string.include?("static")
        return "static"
      end
    else  
      return "dynamic"    
    end 
  end 
 
    
  def change_back
    puts "Make sure all the config is restored"
  end 
       
  def check_status(change)
    if wan_interface_status
      log_to_syslog_and_status_file if change == 2
    elsif wan_ip_status
      log_to_syslog_and_rm_network_file if ((static_dynamic == "dynamic") && (change == 5))
    elsif gateway_status
      log_gateway_failure if change == 2
    elsif external_server_status
      kill_chilli_and_change_logins if change == 2
    else
      restore_config_and_go_live
    end  
  end 


  def wan_interface_status
    if @wan_status != "up"
      return true
    end
    return false
  end     

  def log_to_syslog_and_status_file
    log_interface_change
  end 

  def wan_ip_status
    @wan_ip = get_wan_ip(get_wan_name)
    wan_response = get_icmp_response(@wan_ip)
    if wan_response != "success"
      return true
    else
      return false
    end 
  end      

  def log_to_syslog_and_rm_network_file
    log_lost_ip
    logger("network file changed")
    `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
  end

  def gateway_status
    @gateway = gateway
    gw_response = get_icmp_response(@gateway)
    if gw_response != "success"
      return true
    else
      return false
    end 
  end 

  def log_gateway_failure
    log_gateway_failure
  end

  def external_server_status
    externalserver_response = get_icmp_response(@external_server)
    if externalserver_response != "success"
      return true
    else
      return false
    end
  end 

  def restore_config_and_go_live
    logger("got internet back")
    sync_configs
    $live  = true 
    return $live
  end 

  def sync_configs
    puts "Get sync ??"
  end 

  def kill_chilli_and_change_logins
    `kilall chilli && cp /etc/chilli/default /etc/chilli/online  && cp /etc/chilli/no_internet /etc/chilli/defaults && /etc/init.d/chilli restart`
  end 

  def logger(msg)
    `logger #{msg}`
  end

  def log_to_syslog_and_rm_network_file
    `logger network file changed`
    `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
  end

  def run_heartbeat
    data = "{\"data\":{\"serial\":\"#{$serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{$wan_name}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\",\"logs\":\"#{@logs}\",\"prefs\":#{@prefs}}, \"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
    Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
      post_data
    end
  end

  def post_data
    system("curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' -F 'ca=#{@ca}' #{@api_url}/api/v1/nas/gubbins -k | ash")
    if $? == 0
      `rm -rf /etc/status`
    end  
    system 'rm -rf /tmp/gubbins.lock'
  end

  def check_success_url                                                                                                                                
    %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{@health_url}"}                                                
  end

end 

  if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 60)
    puts "Already testing the connectivity"
  else
    GoGoGubbins.new.check_connectivity_and_heartbeat
  end
