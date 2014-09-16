#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

require '/etc/scripts/functions.rb'
require 'zlib'

class GoGoGubbins
  
  def api_url                                        
      "http://3ce87f37.ngrok.com"                     
  end

  def health_url                                     
      "http://health.polkaspots.com/api/v1/health"     
  end

  def check_connectivity_and_heartbeat
    system 'touch /tmp/gubbins.lock'
    response = check_success_url
    check_lights
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
  
  def externel_server
    return "8.8.8.8"
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
    @wan_status = wan_status
    if @wan_status != "up" 
      if change == 2
        `logger Wan interface is Down`
        log_interface_change
        end
           
       if static_dynamic == "dynamic" && change == 5
         `rm -rf /etc/network && /rom/etc/uci-defaults/02_network`
         end    
       end 
            
      @wan_ip = get_wan_ip(get_wan_name)
      wan_response = get_icmp_response(@wan_ip)
      if wan_response != "success"
        if change == 2
          log_lost_ip
        end
      end   
                 
     @gateway = gateway
     gw_response = get_icmp_response(@gateway)
     if gw_response != "success" 
       if change == 2
         log_gateway_failure
       end 
     end             
      
     es_response = get_icmp_response(externel_server)
     if es_response != "success"
       if change == 2
         `kilall chilli && cp /etc/chilli/default /etc/chilli/online  && cp /etc/chilli/no_internet /etc/chilli/defaults && /etc/init.d/chilli restart`
       end
     end       
     else 
       $live  = true 
       return $live
     end    
  end       
     
                     
  def run_heartbeat
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
    data = "{\"data\":{\"serial\":\"#{$serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{$wan_name}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\",\"logs\":\"#{@logs}\",\"prefs\":#{@prefs}}, \"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
      Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
    puts data
    system("curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' -F 'ca=#{@ca}' #{api_url}/api/v1/nas/gubbins -k | ash")
   if $? == 0
    `rm -rf /etc/status`
    system 'rm -rf /tmp/gubbins.lock'
  end

  def check_success_url                                                                                                                                
      %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{health_url}"}                                                
  end


if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 60)
  puts "Already testing the connectivity"
else
  GoGoGubbins.new.check_connectivity_and_heartbeat
end
