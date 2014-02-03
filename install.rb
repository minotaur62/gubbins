#!/usr/bin/ruby
# Copyright (c) 2014 PolkaSpots Limited
# Use this, change things but don't claim it's yours
# Don't be a douche, play nice

class Installer

  def files
    files = {
      "gubbins.rb" => '/etc/scripts/gubbins.rb',
      "functions.rb" => '/etc/scripts/functions.rb',
      "iwinfo.rb" => '/etc/scripts/iwinfo.sh',
      "iwdump.rb" => '/etc/scripts/iwdump.sh'
    }
  end

  def install
    `mkdir -p /etc/scripts`
    files.each do |name,path|
      puts "Downloading #{name}"
      system("curl -k -s --connect-timeout 5 -X GET #{base_url}/#{name} > #{path} && chmod +x #{path}")
    end
  end

  def base_url
    'https://raw2.github.com/minotaur62/gubbins/master'
  end

end

Installer.new.install
