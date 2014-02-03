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
  
  def run_heartbeat
    @tun_ip = get_tun_ip('tun5')
    @sync = get_sync
    @nvs = get_nvs
    @wvs = get_wvs
    @uptime = uptime
    iwinfo = iwinfo
    iwdump = iwdump('wlan0-1')
    scan = airodump 
    data = "{\"data\":{\"serial\":\"#{$serial}\",\"ip\":\"#{@tun_ip}\",\"lmac\":\"#{$lan_mac}\",\"system\":\"#{$system_type}\",\"machine_type\":\"#{$machine_type}\",\"wan_ip\":\"#{get_wan_ip($wan_name)}\",\"uptime\":\"#{}\",\"sync\":\"#{@sync}\",\"version\":\"#{$version}\",\"chilli\":\"#{chilli_list}\"},\"iwinfo\":#{iwinf},\"iwdump\":#{iwdump}}"
    puts data
    Zlib::GzipWriter.open('data.gz') do |gz|
      gz.write data 
      gz.close
    end
    heartbeat = system("curl --silent --connect-timeout 5 -F data=@data.gz -F 'mac=#{$wan_mac}' http://192.168.20.46/api/v1/nas/gubbins")
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