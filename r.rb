#!/usr/bin/ruby


if File.exists?('prefs')
  
    f= `cat prefs | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w hed | cut -d":" -f3| sed -e 's/^ *//g' -e 's/ *$//g'`
  

  puts" hwell #{f}"

  if f.include? "static"

     puts "hello"
  end 

  end 





