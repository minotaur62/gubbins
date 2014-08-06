#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

require '/etc/scripts/functions.rb'
require 'zlib'

class GoGoGubbins
  
  def api_url                                        
      "https://api.polkaspots.com"                     
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
  
  def check_status(change)
    @wan_status = wan_status
    if (@wan_status != "up")
      if(change == 2)
       log_interface_change
      end
      check_status(1) 
      else 
      @wan_ip = get_wan_ip(get_wan_name)
      wan_response = get_icmp_response(@wan_ip)
      if (result != "success" )
        if (change == 2)
         log_lost_ip
        end
        else
          @gateway = gateway
          gw_response = get_icmp_response(@gateway)
          if(gw_response != "success")
            if(change == 2)
             log_gateway_failure
            end
            else
               es_response = get_icmp_response(externel_server)
               if (es_response != "success")
                 if (change == 2)
                 system`kilall chilli && cp /etc/chilli/default /etc/chilli/online  && cp /etc/chilli/no_internet /etc/chilli/defaults && /etc/init.d/chilli restart`   
                 end
              else 
                $live  = true 
                return $live
                end     
             end     
          end 
      end 
   end       

          
  def check_lights
    @sync = get_sync
    response = check_success_url
    $mode      
    if (@sync != null && response == "200")
      $status = 'online'
    end
    
    if (@sync == nil && response != "200")
      $status = 'new'     
    end
    
    if (@sync == nil && response == "200")
      $status = 'notadded'     
    end
    
    if (@sync != nil && response != "200")
      $status = 'offline'     
    end
    
    if ( $mode = "night mode" )
       $status = 'nightmode'
    end   
    
    case $status
      when 'online'
        system '/bin/sh /etc/scripts/led.sh online'
      when 'new' 
        system '/bin/sh /etc/scripts/led.sh new'
      when 'notadded'
        system '/bin/sh /etc/scripts/led.sh notadded'
      when 'processing'
        system '/bin/sh /etc/scripts/led.sh processing'
      when 'offline'
        system '/bin/sh /etc/scripts/led.sh offline'
      when 'nightmode'
        system '/bin/sh /etc/scripts/led.sh nightmode'
        else 
          puts "what should be default" 
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
    data = "{\"data\":{\"serial\":\"#{$serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{$wan_name}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{uptime}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\",\"prefs\":\"#{@prefs}\",\"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
      Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
    system("curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' -F 'ca=#{@ca}' #{api_url}/api/v1/nas/gubbins -k | ash")
    system 'rm -rf /tmp/gubbins.lock'
  end

  def check_success_url                                                                                                                                
      %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "#{health_url}"}                                                
  end

end

if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 60)
  puts "Already testing the connectivity"
else
  GoGoGubbins.new.check_connectivity_and_heartbeat
end
