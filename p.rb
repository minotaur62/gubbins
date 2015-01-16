def get_response_from_ct
  $serial="1515151515151"
  $wan_mac="54:23:23:23:43:34"
  response=`curl --connect-timeout 5 -d "serial=#{$serial}&mac=#{$wan_mac}" https://api.polkaspots.com/api/v1/nas/status -k`
  puts response
end 

get_response_from_ct
