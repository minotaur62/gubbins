#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

require '/etc/scripts/functions.rb'
require 'zlib'

class GoGoGubbins

  def check_connectivity_and_heartbeat
    system 'touch /tmp/gubbins.lock'
    response = check_success_url
    check_lights
    if response == "200"
      run_heartbeat
    else
      i=0
      loop do
        i+=1
        set_ssid_state
        sleep 15
        break print "I'm alive" if $live == true
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
    data = "{\"data\":{\"serial\":\"#{$serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"firmware\":\"#{@firmware}\",\"wan_interface\":\"#{$wan_name}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\"},\"iwinfo\":#{@iwinfo},\"iwdump\":#{@iwdump}}"
      Zlib::GzipWriter.open('/tmp/data.gz') do |gz|
      gz.write data
      gz.close
    end
    system("curl --silent --connect-timeout 5 -F data=@/tmp/data.gz -F 'mac=#{$wan_mac}' https://api.polkaspots.com/api/v1/nas/gubbins -k | ash")
    system 'rm -rf /tmp/gubbins.lock'
  end

  def check_success_url
    %x{curl --connect-timeout 5 --write-out "%{http_code}" --silent --output /dev/null "http://www.bbc.co.uk/"}
  end

end

if File.exists?('/tmp/gubbins.lock') && File.ctime('/tmp/gubbins.lock') > (Time.now - 300)
  puts "Already testing the connectivity"
else
  GoGoGubbins.new.check_connectivity_and_heartbeat
end
