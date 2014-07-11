#include <stdio.h>
#include <curl/curl.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <unistd.h>
#include <json/json.h>
#include <stdlib.h>
#include <signal.h>
#include <resolv.h>
#include <netinet/tcp.h>

int health()
{
 char *string= "8.8.8.8";
 char *stri= "53";
 struct sockaddr_in addr;
 int serverfd;
 int a;
 serverfd = socket(PF_INET, SOCK_STREAM, 0);
 bzero(&addr, sizeof(addr));
 addr.sin_family = AF_INET;
 addr.sin_port = htons(atoi(stri));
 inet_aton(string, &addr.sin_addr);
 a = connect(serverfd, (struct sockaddr*)&addr, sizeof(addr));
   if(a!=0) {  
	 //need to add debug flag 
    printf("No internet\n");
      }
    else { 
    printf("%d Internnet\n",a);
     }
return a;
 }



char *readfile(char *me) {

FILE *read_fp;
 char buffer[BUFSIZ + 1];
 int chars_read;
 memset(buffer, '\0', sizeof(buffer));
 read_fp = popen(me, "r");
  if (read_fp != NULL) {
    chars_read = fread(buffer, sizeof(char), BUFSIZ, read_fp);
    pclose(read_fp);
  }
printf("%s",buffer);
return buffer;
}

char * cpuinfo()
{
   FILE* fp;
   char buffer[BUFSIZ + 1];
   size_t bytes_read;
   char* match;
   char cpu_info[BUFSIZ];
   fp = fopen ("/proc/cpuinfo", "r");
   bytes_read = fread (buffer, 1, sizeof (buffer), fp);
   fclose (fp);
   if (bytes_read == 0 || bytes_read == sizeof (buffer))
     return 0;
   buffer[bytes_read] == '\0';
   match = strstr (buffer, "vendor_id");
   if (match == NULL)
     return 0;
   sscanf(match, " vendor_id	  : %[^\t\n] " ,cpu_info);
//   printf("%s\n ",cpu_info);
   return cpu_info;
}

char *machine()
{
   FILE* fp;
   char buffer[BUFSIZ + 1];
   size_t bytes_read;
   char* match;
   char machine_type[BUFSIZ];
   fp = fopen ("/proc/cpuinfo", "r");
   bytes_read = fread (buffer, 1, sizeof (buffer), fp);
   fclose (fp);
   if (bytes_read == 0 || bytes_read == sizeof (buffer))
     return 0;
   buffer[bytes_read] == '\0';
   match = strstr (buffer, "model name");
   if (match == NULL)
     return 0;
   sscanf(match, " model name  : %[^\t\n] " ,machine_type);
   printf("%s\n ",machine_type);
   return machine_type;
}


void json_parse(json_object * jobj) {
 enum json_type type;
 json_object_object_foreach(jobj, key, val) {
 type = json_object_get_type(val);
 switch (type) {
 case json_type_string: //printf(" ");
 if (strcmp(key,"ssid") == 0) {
 const  char *ssid =  json_object_get_string(val);
  }
  if (strcmp(key,"command") == 0) {
  system(json_object_get_string(val));
  }
if(strcmp(key,"message") == 0) {
   printf("message is : %s",json_object_get_string(val));
}

 break;
 }
 }
}


struct string {
  char *ptr;
  size_t len;
};

void init_string(struct string *s) {
  s->len = 0;
  s->ptr = malloc(s->len+1);
  if (s->ptr == NULL) {
    fprintf(stderr, "malloc() failed\n");
    exit(EXIT_FAILURE);
  }
  s->ptr[0] = '\0';
}

size_t writefunc(void *ptr, size_t size, size_t nmemb, struct string *s)
{
  size_t new_len = s->len + size*nmemb;
  s->ptr = realloc(s->ptr, new_len+1);
  if (s->ptr == NULL) {
    fprintf(stderr, "realloc() failed\n");
    exit(EXIT_FAILURE);
  }
memcpy(s->ptr+s->len, ptr, size*nmemb);
  s->ptr[new_len] = '\0';
  s->len = new_len;

  return size*nmemb;
}


int send_data(char *mac)
{
  CURL *curl;
  CURLcode res;

  struct curl_httppost *formpost=NULL;
  struct curl_httppost *lastptr=NULL;
  struct curl_slist *headerlist=NULL;
  static const char buf[] = "Expect:";

  curl_global_init(CURL_GLOBAL_ALL);

  curl_formadd(&formpost,
               &lastptr,
               CURLFORM_COPYNAME, "data",
               CURLFORM_FILE, "/tmp/data.gz",
               CURLFORM_END);

 curl_formadd(&formpost,
               &lastptr,
               CURLFORM_COPYNAME, "mac",
               CURLFORM_COPYCONTENTS, mac,
               CURLFORM_END);

  curl = curl_easy_init();
  headerlist = curl_slist_append(headerlist, buf);
  if(curl) {
    struct string s;
    init_string(&s);
    curl_easy_setopt(curl, CURLOPT_URL, "https://api.polkaspots.com/api/v1/nas/gubbins");
      curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerlist);
    curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost);
   curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
   curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);
    res = curl_easy_perform(curl);
    if(res != CURLE_OK)
      fprintf(stderr, "curl_easy_perform() failed: %s\n",
              curl_easy_strerror(res));


     json_object * jobj = json_tokener_parse(s.ptr);
    json_parse(jobj);
    free(s.ptr);

    curl_easy_cleanup(curl);
    curl_formfree(formpost);
    curl_slist_free_all (headerlist);
  }
  return 0;
}


int main() {
  while (1) {
    int x;
    x=health();
      if (x ==0) {
        hb();
             }
     sleep(5);
     health();
     }
     return 0;
    }


int hb() {
char *base_url="https://s3-eu-west-1.amazonaws.com/ps-openwrt-configs/configs/chilli/defaults";
json_object * jobj = json_object_new_object();
json_object *juptime = json_object_new_string(readfile("cat /proc/uptime"));

json_object_object_add(jobj,"uptime", juptime);

  struct ifaddrs *ifap, *ifa;
    struct sockaddr_in *sa;
    char *addr;
    char *ip;
    getifaddrs (&ifap);
    for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
        if ((ifa->ifa_addr->sa_family==AF_INET) && strncmp(ifa->ifa_name,"e",1) == 0 )  {
            sa = (struct sockaddr_in *) ifa->ifa_addr;
            addr = inet_ntoa(sa->sin_addr);
            if (strncmp(ifa->ifa_name,"eth0",3) == 0 ) {
            //printf("hello");
           
          json_object *jinterface = json_object_new_string(addr);
           json_object_object_add(jobj,ifa->ifa_name, jinterface);
           }

            if (strncmp(ifa->ifa_name,"wlan",1) == 0 ) {  
               printf("wireless");
               
                 }
          
          } 
   }
    freeifaddrs(ifap);


curl(base_url);
json_object *jcpu = json_object_new_string(cpuinfo());
json_object_object_add(jobj,"system", jcpu);


json_object *jmachine = json_object_new_string(machine());
json_object_object_add(jobj,"model", jmachine);

json_object *jmac = json_object_new_string(macd("eth0"));
json_object_object_add(jobj,"mac", jmac);

FILE *fp = fopen("/tmp/data", "w+");
fprintf(fp,"%s",json_object_to_json_string(jobj));
fclose(fp);
printf ("%s\n",json_object_to_json_string(jobj));
system("gzip -f /tmp/data");   
return 0;
}


int curl(char *url)
{
    int code;  
    CURL *curl;
    FILE *fp;
    CURLcode res;
    char outfilename[FILENAME_MAX] = "/tmp/defaults";
     curl = curl_easy_init();     
    if (curl)
    {   
        fp = fopen(outfilename,"wb");
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
        res = curl_easy_perform(curl);
         long http_code = 0;
         double speed_down = 0; 
         curl_easy_getinfo (curl, CURLINFO_RESPONSE_CODE,&http_code);
        // curl_easy_getinfo (curl, CURLINFO_SPEED_DOWNLOAD,&speed_down);
         printf("%lu ",http_code);
         
        curl_easy_cleanup(curl);
        fclose(fp);


    }   
    return 0;
}


 int macd(char *iface)
 { 
    
  
    int fd;
    struct ifreq ifr;
  // char *iface = "eth0";
    unsigned char *mac;
    char Hw_mac[BUFSIZ];
    fd = socket(AF_INET, SOCK_DGRAM, 0);

    ifr.ifr_addr.sa_family = AF_INET;
    strncpy(ifr.ifr_name , iface , IFNAMSIZ-1);

    ioctl(fd, SIOCGIFHWADDR, &ifr);

    close(fd);

    mac = (unsigned char *)ifr.ifr_hwaddr.sa_data;

    //display mac address
    sprintf(Hw_mac,"%.2x:%.2x:%.2x:%.2x:%.2x:%.2x" , mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
   //printf("%s",Hw_mac); 
    return Hw_mac;
}










