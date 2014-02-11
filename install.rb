#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

class Installer

  def files
    files = {
      "gubbins.rb" => '/etc/scripts/gubbins.rb',
      "functions.rb" => '/etc/scripts/functions.rb',
      "iwinfo.sh" => '/etc/scripts/iwinfo.sh',
      "iwdump.sh" => '/etc/scripts/iwdump.sh',
      "airodump.sh" => '/etc/scripts/airodump.sh',
      "polkaspots" => '/etc/init.d/polkaspots'
    }
  end

  def install
    `mkdir -p /etc/scripts`
    files.each do |name,path|
      puts "Downloading #{name}"
      system("curl -k -s --connect-timeout 5 -X GET #{base_url}/#{name} -o #{path} && chmod +x #{path}")
    end
  end

  def base_url
    'https://s3-eu-west-1.amazonaws.com/ps-openwrt-configs/1.3/production/scripts'
  end

end

Installer.new.install
