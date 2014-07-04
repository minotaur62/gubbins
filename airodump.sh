json_object *jinterface[4]; 
                json_object *jmac[4];
                 jmac[i] = json_object_new_string(macd(ifa->ifa_name));
                 json_object_object_add(jobj,ifa->ifa_name, jmac[i]); 
                 jinterface[i] = json_object_new_string(addr);
                json_object_object_add(jobj,ifa->ifa_name, jinterface[i]);#test
