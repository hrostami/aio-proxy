#!/bin/bash
export LANG=en_US.UTF-8
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;36m'
bblue='\033[0;34m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "Please run the script in root mode" && exit
#[[ -e /etc/hosts ]] && grep -qE '^ *172.65.251.78 gitlab.com' /etc/hosts || echo -e '\n172.65.251.78 gitlab.com' >> /etc/hosts
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "The script does not support your current system. Please choose to use Ubuntu, Debian, or Centos systems." && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
red "The script does not support your current $op system, please choose to use Ubuntu, Debian, Centos system." && exit
fi
version=$(uname -r | cut -d "-" -f1)
vi=$(systemd-detect-virt 2>/dev/null)
bit=$(uname -m)
if [[ $bit = "aarch64" ]]; then
cpu="arm64"
elif [[ $bit = "x86_64" ]]; then
amdv=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
a=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
[[ $amdv == *avx2* && $amdv == *f16c* ]] && cpu="amd64v3" || cpu="amd64"
else
red "Currently the script does not support the $bit architecture" && exit
fi
if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then
bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`
elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then
bbr="Openvz version bbr-plus"
else
bbr="Openvz/Lxc"
fi
if [ ! -f sbyg_update ]; then
green "Install the necessary dependencies of the Sing-box-yg script for the first time..."
update(){
if [ -x "$(command -v apt-get)" ]; then
apt update -y
apt install wget -y
elif [ -x "$(command -v yum)" ]; then
yum update -y && yum install epel-release -y
yum update wget -y
elif [ -x "$(command -v dnf)" ]; then
dnf update -y
dnf update wget -y
fi
}
if [[ $release = Centos && ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
cd
fi
update
packages=("curl" "openssl" "jq" "iptables" "iptables-persistent" "tar" "qrencode" "cron")
inspackages=("curl" "openssl" "jq" "iptables" "iptables-persistent" "tar" "qrencode" "cron")
for i in "${!packages[@]}"; do
package="${packages[$i]}"
inspackage="${inspackages[$i]}"
if ! command -v "$package" &> /dev/null; then
if [ -x "$(command -v apt-get)" ]; then
apt-get install -y "$inspackage"
elif [ -x "$(command -v yum)" ]; then
yum install -y "$inspackage"
elif [ -x "$(command -v dnf)" ]; then
dnf install -y "$inspackage"
fi
fi
done
if [ -x "$(command -v yum)" ] || [ -x "$(command -v dnf)" ]; then
if [ -x "$(command -v yum)" ]; then
yum install -y cronie iptables-services
elif [ -x "$(command -v dnf)" ]; then
dnf install -y cronie iptables-services
fi
systemctl enable iptables >/dev/null 2>&1
systemctl start iptables >/dev/null 2>&1
fi
if [[ -z $vi ]]; then
apt install iputils-ping iproute2 systemctl -y
fi
update
touch sbyg_update
fi
if [[ $vi = openvz ]]; then
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
red "It is detected that TUN is not enabled. Now try to add TUN support." && sleep 4
cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun
TUN=$(cat /dev/net/tun 2>&1)
if [[ ! $TUN =~ 'in bad state' ]] && [[ ! $TUN =~ '处于错误状态' ]] && [[ ! $TUN =~ 'Die Dateizugriffsnummer ist in schlechter Verfassung' ]]; then 
green "Failed to add TUN support. It is recommended to communicate with the VPS manufacturer or enable background settings." && exit
else
echo '#!/bin/bash' > /root/tun.sh && echo 'cd /dev && mkdir net && mknod net/tun c 10 200 && chmod 0666 net/tun' >> /root/tun.sh && chmod +x /root/tun.sh
grep -qE "^ *@reboot root bash /root/tun.sh >/dev/null 2>&1" /etc/crontab || echo "@reboot root bash /root/tun.sh >/dev/null 2>&1" >> /etc/crontab
green "TUN guard function has been started"
fi
fi
fi
v4v6(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
}
warpcheck(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
v6(){
v4orv6(){
if [ -z $(curl -s4m5 icanhazip.com -k) ]; then
echo
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow "Pure IPV6 VPS detected, add DNS64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
endip=2606:4700:d0::a29f:c101
ipv=prefer_ipv6
else
endip=162.159.193.10
ipv=prefer_ipv4
fi
}
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4orv6
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4orv6
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
}
close(){
systemctl stop firewalld.service >/dev/null 2>&1
systemctl disable firewalld.service >/dev/null 2>&1
setenforce 0 >/dev/null 2>&1
ufw disable >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -t mangle -F >/dev/null 2>&1
iptables -F >/dev/null 2>&1
iptables -X >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
if [[ -n $(apachectl -v 2>/dev/null) ]]; then
systemctl stop httpd.service >/dev/null 2>&1
systemctl disable httpd.service >/dev/null 2>&1
service apache2 stop >/dev/null 2>&1
systemctl disable apache2 >/dev/null 2>&1
fi
sleep 1
green "Execute open port and close firewall."
}
openyn(){
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
readp "Do you want to open the port and close the firewall? \n1. Yes, execute (press enter to default)\n2. No, I will do it manually\nPlease select:" action
if [[ -z $action ]] || [[ "$action" = "1" ]]; then
close
elif [[ "$action" = "2" ]]; then
echo
else
red "Input error, please choose again" && openyn
fi
}
inssb(){
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green "1. Start downloading and installing the official version of Sing-box kernel... Please wait."
echo
sbcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
sbname="sing-box-$sbcore-linux-$cpu"
wget -q -O /etc/s-box/sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v$sbcore/$sbname.tar.gz
if [[ -f '/etc/s-box/sing-box.tar.gz' ]]; then
tar xzf /etc/s-box/sing-box.tar.gz -C /etc/s-box
mv /etc/s-box/$sbname/sing-box /etc/s-box
rm -rf /etc/s-box/{sing-box.tar.gz,$sbname}
if [[ -f '/etc/s-box/sing-box' ]]; then
chown root:root /etc/s-box/sing-box
chmod +x /etc/s-box/sing-box
blue "Successfully installed Sing-box kernel version: $(/etc/s-box/sing-box version | awk '/version/{print $NF}')"
else
red "The download of Sing-box kernel is incomplete and the installation failed. Please run the installation again." && exit
fi
else
red "Failed to download the Sing-box kernel. Please run the installation again and check whether the VPS network can access Github." && exit
fi
}
inscertificate(){
ymzs(){
ym_vl_re=www.yahoo.com
blue "The SNI domain name of Vless-reality defaults to www.yahoo.com"
blue "Vmess-ws will enable TLS, Hysteria-2 and Tuic-v5 will use the $(cat /root/ygkkkca/ca.log 2>/dev/null) certificate and enable SNI certificate verification."
tlsyn=true
ym_vm_ws=$(cat /root/ygkkkca/ca.log 2>/dev/null)
certificatec_vmess_ws='/root/ygkkkca/cert.crt'
certificatep_vmess_ws='/root/ygkkkca/private.key'
certificatec_hy2='/root/ygkkkca/cert.crt'
certificatep_hy2='/root/ygkkkca/private.key'
certificatec_tuic='/root/ygkkkca/cert.crt'
certificatep_tuic='/root/ygkkkca/private.key'
}
zqzs(){
ym_vl_re=www.yahoo.com
blue "The SNI domain name of Vless-reality defaults to www.yahoo.com"
blue "Vmess-ws will turn off TLS, Hysteria-2 and Tuic-v5 will use bing self-signed certificates and turn off SNI certificate verification."
tlsyn=false
ym_vm_ws=www.bing.com
certificatec_vmess_ws='/etc/s-box/cert.pem'
certificatep_vmess_ws='/etc/s-box/private.key'
certificatec_hy2='/etc/s-box/cert.pem'
certificatep_hy2='/etc/s-box/private.key'
certificatec_tuic='/etc/s-box/cert.pem'
certificatep_tuic='/etc/s-box/private.key'
}
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green "2. Generate and set up relevant certificates"
echo
blue "Automatically generate bing self-signed certificate..." && sleep 2
openssl ecparam -genkey -name prime256v1 -out /etc/s-box/private.key
openssl req -new -x509 -days 36500 -key /etc/s-box/private.key -out /etc/s-box/cert.pem -subj "/CN=www.bing.com"
echo
if [[ -f /etc/s-box/cert.pem ]]; then
blue "Generating bing self-signed certificate successfully"
else
red "Failed to generate bing self-signed certificate" && exit
fi
echo
if [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key && -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]]; then
yellow "After testing, we have used the Acme-yg script to apply for an Acme domain name certificate: $(cat /root/ygkkkca/ca.log)"
green "Do you use $(cat /root/ygkkkca/ca.log) domain name certificate?"
yellow "1: No! Use self-signed certificate (press Enter to default)"
yellow "2: Yes! Use $(cat /root/ygkkkca/ca.log) domain name certificate"
readp "please choose:" menu
if [ -z "$menu" ] || [ "$menu" = "1" ] ; then
zqzs
else
ymzs
fi
else
green "If there is a domain name that has been resolved, should I apply for an Acme domain name certificate? (Constitutes dual certificate mode, which can coexist with self-signed certificates, and each protocol can be switched independently)"
yellow "1: No! Use self-signed certificate (press Enter to default)"
yellow "2: Yes! Use the Acme-yg script to apply for an Acme certificate (supports regular port 80 mode and Dns API mode)"
readp "please choose:" menu
if [ -z "$menu" ] || [ "$menu" = "1" ] ; then
zqzs
else
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/acme-eng.sh)
if [[ ! -f /root/ygkkkca/cert.crt && ! -f /root/ygkkkca/private.key && ! -s /root/ygkkkca/cert.crt && ! -s /root/ygkkkca/private.key ]]; then
red "Acme certificate application failed, continue to use self-signed certificate" 
zqzs
else
ymzs
fi
fi
fi
}
chooseport(){
if [[ -z $port ]]; then
port=$(shuf -i 2000-65535 -n 1)
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] 
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" port
done
else
until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") && -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") || -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" port
done
fi
blue "Confirmed port: $port" && sleep 2
}
vlport(){
readp "\nSet Vless-reality port [1-65535] (press Enter to skip to a random port between 2000-65535):" port
chooseport
port_vl_re=$port
}
vmport(){
readp "\nSet Vmess-ws port [1-65535] (press Enter to skip to a random port between 2000-65535):" port
chooseport
port_vm_ws=$port
}
hy2port(){
readp "\nSet the Hysteria2 main port [1-65535] (press Enter to skip to a random port between 2000-65535):" port
chooseport
port_hy2=$port
}
tu5port(){
readp "\nSet Tuic5 main port [1-65535] (press Enter to skip to a random port between 2000-65535):" port
chooseport
port_tu=$port
}
insport(){
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green "3. Set each protocol port"
yellow "1: Automatically generate a random port for each protocol (in the range of 2000-65535), press Enter to default"
yellow "2: Customize each protocol port"
readp "please enter:" port
if [ -z "$port" ] || [ "$port" = "1" ] ; then
ports=()
for i in {1..4}; do
while true; do
port=$(shuf -i 2000-65535 -n 1)
if ! [[ " ${ports[@]} " =~ " $port " ]] && \
[[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && \
[[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
ports+=($port)
break
fi
done
done
port_vm_ws=${ports[0]}
port_vl_re=${ports[1]}
port_hy2=${ports[2]}
port_tu=${ports[3]}
if [[ $tlsyn == "true" ]]; then
numbers=("2053" "2083" "2087" "2096" "8443")
else
numbers=("8080" "8880" "2052" "2082" "2086" "2095")
fi
port_vm_ws=${numbers[$RANDOM % ${#numbers[@]}]}
echo
blue "Depending on whether the Vmess-ws protocol enables TLS, randomly specify the port that supports the CDN preferred IP: $port_vm_ws"
else
vlport && vmport && hy2port && tu5port
fi
echo
blue "Each protocol port is confirmed as follows:"
blue "Vless-reality port: $port_vl_re"
blue "Vmess-ws port: $port_vm_ws"
blue "Hysteria-2 port: $port_hy2"
blue "Tuic-v5 port: $port_tu"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green "4. Automatically generate a unified uuid (password) for each protocol"
uuid=$(/etc/s-box/sing-box generate uuid)
blue "Confirmed uuid (password): ${uuid}"
blue "The path of Vmess has been confirmed: ${uuid}-vm"
}
inssbjsonser(){
cat > /etc/s-box/sb.json <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "sniff": true,
      "sniff_override_destination": true,
      "tag": "vless-sb",
      "listen": "::",
      "listen_port": ${port_vl_re},
      "users": [
        {
          "uuid": "${uuid}",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${ym_vl_re}",
          "reality": {
          "enabled": true,
          "handshake": {
            "server": "${ym_vl_re}",
            "server_port": 443
          },
          "private_key": "$private_key",
          "short_id": ["$short_id"]
        }
      }
    },
{
        "type": "vmess",
        "sniff": true,
        "sniff_override_destination": true,
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${port_vm_ws},
        "users": [
            {
                "uuid": "${uuid}",
                "alterId": 0
            }
        ],
        "transport": {
            "type": "ws",
            "path": "${uuid}-vm"
        },
        "tls":{
                "enabled": ${tlsyn},
                "server_name": "${ym_vm_ws}",
                "min_version": "1.2",
                "max_version": "1.3",
                "certificate_path": "$certificatec_vmess_ws",
                "key_path": "$certificatep_vmess_ws"
            }
    }, 
    {
        "type": "hysteria2",
        "sniff": true,
        "sniff_override_destination": true,
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${port_hy2},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "ignore_client_bandwidth":false,
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "min_version":"1.2",
            "max_version":"1.3",
            "certificate_path": "$certificatec_hy2",
            "key_path": "$certificatep_hy2"
        }
    },
        {
            "type":"tuic",
            "sniff": true,
            "sniff_override_destination": true,
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${port_tu},
            "users": [
                {
                    "uuid": "${uuid}",
                    "password": "${uuid}"
                }
            ],
            "congestion_control": "bbr",
            "tls":{
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "$certificatec_tuic",
                "key_path": "$certificatep_tuic"
            }
        }
],
"outbounds": [
{
"type":"direct",
"tag":"direct",
"domain_strategy": "$ipv"
},
{
"type":"direct",
"tag": "vps-outbound-v4", 
"domain_strategy":"ipv4_only"
},
{
"type":"direct",
"tag": "vps-outbound-v6",
"domain_strategy":"ipv6_only"
},
{
"type": "socks",
"tag": "socks-out",
"server": "127.0.0.1",
"server_port": 40000,
"version": "5"
},
{
"type":"direct",
"tag":"socks-IPv4-out",
"detour":"socks-out",
"domain_strategy":"ipv4_only"
},
{
"type":"direct",
"tag":"socks-IPv6-out",
"detour":"socks-out",
"domain_strategy":"ipv6_only"
},
{
"type":"direct",
"tag":"warp-IPv4-out",
"detour":"wireguard-out",
"domain_strategy":"ipv4_only"
},
{
"type":"direct",
"tag":"warp-IPv6-out",
"detour":"wireguard-out",
"domain_strategy":"ipv6_only"
},
{
"type":"wireguard",
"tag":"wireguard-out",
"server":"$endip",
"server_port":1701,
"local_address":[
"172.16.0.2/32",
"2606:4700:110:891c:6ee2:7df4:5e99:b7cf/128"
],
"private_key":"aJkrp4MMgL/Oi2bO4Fww9J8aqAW1ojeOZ22RK0nXYWY=",
"peer_public_key":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
"reserved":[230,25,169]
},
{
"type": "block",
"tag": "block"
}
],
"route":{
"geoip":{
"download_url":"https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.db",
"download_detour":"direct"
},
"geosite":{
"download_url":"https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.db",
"download_detour":"direct"
},
"rules":[
{
"protocol": ["quic"],
"port": [ 443 ],
"outbound": "block"
},
{
"outbound":"warp-IPv4-out",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound":"warp-IPv6-out",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound":"socks-IPv4-out",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound":"socks-IPv6-out",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound":"vps-outbound-v4",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound":"vps-outbound-v6",
"domain": [
"yg_kkk"
],
"geosite": [
"yg_kkk"
]
},
{
"outbound": "direct",
"network": "udp,tcp"
}
]
}
}
EOF
}
sbservice(){
cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
After=network.target nss-lookup.target
[Service]
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/etc/s-box/sing-box run -c /etc/s-box/sb.json
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable sing-box >/dev/null 2>&1
systemctl start sing-box
systemctl restart sing-box
}
ipuuid(){
uuid=$(jq -r '.inbounds[0].users[0].uuid' /etc/s-box/sb.json)
serip=$(curl -s4m5 icanhazip.com -k || curl -s6m5 icanhazip.com -k)
if [[ "$serip" =~ : ]]; then
sbdnsip='https://[2001:4860:4860::8888]/dns-query'
server_ip="[$serip]"
server_ipcl="$serip"
else
sbdnsip='https://8.8.8.8/dns-query'
server_ip="$serip"
server_ipcl="$serip"
fi
}
wgcfgo(){
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
ipuuid
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
ipuuid
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
}
result_vl_vm_hy_tu(){
rm -rf /etc/s-box/vm_ws_argo.txt /etc/s-box/vm_ws.txt /etc/s-box/vm_ws_tls.txt
wgcfgo
vl_port=$(jq -r '.inbounds[0].listen_port' /etc/s-box/sb.json)
vl_name=$(jq -r '.inbounds[0].tls.server_name' /etc/s-box/sb.json)
public_key=$(cat /etc/s-box/public.key)
short_id=$(jq -r '.inbounds[0].tls.reality.short_id[0]' /etc/s-box/sb.json)
argo=$(cat /etc/s-box/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
ws_path=$(jq -r '.inbounds[1].transport.path' /etc/s-box/sb.json)
vm_name=$(jq -r '.inbounds[1].tls.server_name' /etc/s-box/sb.json)
vm_port=$(jq -r '.inbounds[1].listen_port' /etc/s-box/sb.json)
tls=$(jq -r '.inbounds[1].tls.enabled' /etc/s-box/sb.json)
if [[ "$tls" = "false" ]]; then
sb_vm_ip=$server_ip
cl_vm_ip=$server_ipcl
else
sb_vm_ip=$vm_name
cl_vm_ip=$vm_name
fi
hy2_port=$(jq -r '.inbounds[2].listen_port' /etc/s-box/sb.json)
hy2_ports=$(iptables -t nat -nL --line 2>/dev/null | grep -w "$hy2_port" | awk '{print $8}' | sed 's/dpts://; s/dpt://' | tr '\n' ',' | sed 's/,$//')
if [[ -n $hy2_ports ]]; then
hy2ports=$(echo $hy2_ports | sed 's/:/-/g')
hyps=$hy2_port,$hy2ports
else
hyps=$hy2_port
fi
ym=$(cat /root/ygkkkca/ca.log 2>/dev/null)
hy2_sniname=$(jq -r '.inbounds[2].tls.key_path' /etc/s-box/sb.json)
if [[ "$hy2_sniname" = '/etc/s-box/private.key' ]]; then
hy2_name=www.bing.com
sb_hy2_ip=$server_ip
cl_hy2_ip=$server_ipcl
ins_hy2=1
hy2_ins=true
else
hy2_name=$ym
sb_hy2_ip=$ym
cl_hy2_ip=$ym
ins_hy2=0
hy2_ins=false
fi
tu5_port=$(jq -r '.inbounds[3].listen_port' /etc/s-box/sb.json)
ym=$(cat /root/ygkkkca/ca.log 2>/dev/null)
tu5_sniname=$(jq -r '.inbounds[3].tls.key_path' /etc/s-box/sb.json)
if [[ "$tu5_sniname" = '/etc/s-box/private.key' ]]; then
tu5_name=www.bing.com
sb_tu5_ip=$server_ip
cl_tu5_ip=$server_ipcl
ins=1
tu5_ins=true
else
tu5_name=$ym
sb_tu5_ip=$ym
cl_tu5_ip=$ym
ins=0
tu5_ins=false
fi
}
resvless(){
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
vl_link="vless://$uuid@$server_ip:$vl_port?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$vl_name&fp=chrome&pbk=$public_key&sid=$short_id&type=tcp&headerType=none#ygkkk-vl-reality"
echo "$vl_link" > /etc/s-box/vl_reality.txt
red "🚀【 vless-reality-vision 】The node information is as follows:" && sleep 2
echo
echo "Share link [v2rayn, v2rayng, nekobox, shadowrocket]"
echo -e "${yellow}$vl_link${plain}"
echo
echo "QR code [v2rayn, v2rayng, nekobox, shadowrocket]"
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/vl_reality.txt)"
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}
resvmess(){
if [[ "$tls" = "false" ]]; then
if [[ -n $(ps -ef | grep cloudflared) && -s '/etc/s-box/argo.log' ]]; then
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀【 vmess-ws(tls)+Argo】The node information is as follows:" && sleep 2
echo
echo "Share link [v2rayn, v2rayng, nekobox, shadowrocket]"
echo -e "${yellow}vmess://$(echo '{"add":"www.visa.com","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"443","ps":"ygkkk-vm-argo","tls":"tls","sni":"'$argo'","type":"none","v":"2"}' | base64 -w 0)${plain}"
echo
echo "QR code [v2rayn, v2rayng, nekobox, shadowrocket]"
echo 'vmess://'$(echo '{"add":"www.visa.com","aid":"0","host":"'$argo'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"443","ps":"ygkkk-vm-argo","tls":"tls","sni":"'$argo'","type":"none","v":"2"}' | base64 -w 0) > /etc/s-box/vm_ws_argo.txt
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/vm_ws_argo.txt)"
fi
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀【 vmess-ws 】The node information is as follows (it is recommended to set it as a CDN priority node):" && sleep 2
echo
echo "Share link [v2rayn, v2rayng, nekobox, shadowrocket]"
echo -e "${yellow}vmess://$(echo '{"add":"'$server_ip'","aid":"0","host":"'$vm_name'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"'$vm_port'","ps":"ygkkk-vm-ws","tls":"","type":"none","v":"2"}' | base64 -w 0)${plain}"
echo
echo "QR code [v2rayn, v2rayng, nekobox, shadowrocket]"
echo 'vmess://'$(echo '{"add":"'$server_ip'","aid":"0","host":"'$vm_name'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"'$vm_port'","ps":"ygkkk-vm-ws","tls":"","type":"none","v":"2"}' | base64 -w 0) > /etc/s-box/vm_ws.txt
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/vm_ws.txt)"
else
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀【 vmess-ws-tls 】The node information is as follows:" && sleep 2
echo
echo "Share link [v2rayn, v2rayng, nekobox, shadowrocket]"
echo -e "${yellow}vmess://$(echo '{"add":"'$vm_name'","aid":"0","host":"'$vm_name'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"'$vm_port'","ps":"ygkkk-vm-ws-tls","tls":"tls","sni":"'$vm_name'","type":"none","v":"2"}' | base64 -w 0)${plain}"
echo
echo "QR code [v2rayn, v2rayng, nekobox, shadowrocket]"
echo 'vmess://'$(echo '{"add":"'$vm_name'","aid":"0","host":"'$vm_name'","id":"'$uuid'","net":"ws","path":"'$ws_path'","port":"'$vm_port'","ps":"ygkkk-vm-ws-tls","tls":"tls","sni":"'$vm_name'","type":"none","v":"2"}' | base64 -w 0) > /etc/s-box/vm_ws_tls.txt
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/vm_ws_tls.txt)"
fi
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}
reshy2(){
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hy2_link="hysteria2://$uuid@$sb_hy2_ip:$hy2_port?insecure=$ins_hy2&mport=$hyps&sni=$hy2_name#ygkkk-hy2"
echo "$hy2_link" > /etc/s-box/hy2.txt
red "🚀[Hysteria-2]The node information is as follows:" && sleep 2
echo
echo "Share link [nekobox, shadowrocket]"
echo -e "${yellow}$hy2_link${plain}"
echo
echo "QR code [nekobox, shadowrocket]"
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/hy2.txt)"
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}
restu5(){
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
tuic5_link="tuic://$uuid:$uuid@$sb_tu5_ip:$tu5_port?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=$tu5_name&allow_insecure=$ins#ygkkk-tu5"
echo "$tuic5_link" > /etc/s-box/tuic5.txt
red "🚀【Tuic-v5】The node information is as follows:" && sleep 2
echo
echo "Share link [nekobox, shadowrocket]"
echo -e "${yellow}$tuic5_link${plain}"
echo
echo "QR code [nekobox, shadowrocket]"
qrencode -o - -t ANSIUTF8 "$(cat /etc/s-box/tuic5.txt)"
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}
sb_client(){
cat > /etc/s-box/sing_box_client.json <<EOF
{
  "log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
    "dns": {
        "servers": [
            {
                "tag": "remote",
                "address": "$sbdnsip",             
                "detour": "select"
            },
            {
                "tag": "local",
                "address": "h3://223.5.5.5/dns-query",
                "detour": "direct"
            },
            {
                "address": "rcode://success",
                "tag": "block"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip"
            }
        ],
        "rules": [
            {
                "outbound": "any",
                "server": "local",
                "disable_cache": true
            },
            {
                "clash_mode": "Global",
                "server": "remote"
            },
            {
                "clash_mode": "Direct",
                "server": "local"
            },
            {
                "geosite": "cn",
                "server": "local"
            },
            {
                "geosite": "geolocation-!cn",
                "server": "remote"
            },
             {
                "geosite": "geolocation-!cn",             
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_fakeip"
            }
          ],
           "fakeip": {
           "enabled": true,
           "inet4_range": "198.18.0.0/15",
           "inet6_range": "fc00::/18"
         },
          "independent_cache": true,
          "final": "remote"
        },
      "inbounds": [
    {
      "type": "tun",
      "inet4_address": "172.19.0.1/30",
      "inet6_address": "fdfe:dcba:9876::1/126",
      "auto_route": true,
      "strict_route": true,
      "stack": "mixed",
      "sniff": true
    }
  ],
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "external_ui": "ui",
      "external_ui_download_url": "",
      "external_ui_download_detour": "",
      "secret": "",
      "default_mode": "Rule",
      "store_mode": true,
      "store_selected": true,
      "store_fakeip": true
    }
  },
  "outbounds": [
    {
      "tag": "select",
      "type": "selector",
      "default": "auto",
      "outbounds": [
        "auto",
        "vless-sb",
        "vmess-sb",
        "hy2-sb",
        "tuic5-sb"
      ]
    },
    {
      "type": "vless",
      "tag": "vless-sb",
      "server": "$server_ipcl",
      "server_port": $vl_port,
      "uuid": "$uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$vl_name",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key",
          "short_id": "$short_id"
        }
      }
    },
{
            "server": "$cl_vm_ip",
            "server_port": $vm_port,
            "tag": "vmess-sb",
            "tls": {
                "enabled": $tls,
                "server_name": "$vm_name",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "transport": {
                "headers": {
                    "Host": [
                        "$vm_name"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "server": "$cl_hy2_ip",
        "server_port": $hy2_port,
        "password": "$uuid",
        "tls": {
            "enabled": true,
            "server_name": "$hy2_name",
            "insecure": $hy2_ins,
            "alpn": [
                "h3"
            ]
        }
    },
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "server": "$cl_tu5_ip",
            "server_port": $tu5_port,
            "uuid": "$uuid",
            "password": "$uuid",
            "congestion_control": "bbr",
            "udp_relay_mode": "native",
            "udp_over_stream": false,
            "zero_rtt_handshake": false,
            "heartbeat": "10s",
            "tls":{
                "enabled": true,
                "server_name": "$tu5_name",
                "insecure": $tu5_ins,
                "alpn": [
                    "h3"
                ]
            }
        },
    {
      "tag": "direct",
      "type": "direct"
    },
    {
      "tag": "block",
      "type": "block"
    },
    {
      "tag": "dns-out",
      "type": "dns"
    },
    {
      "tag": "auto",
      "type": "urltest",
      "outbounds": [
        "vless-sb",
        "vmess-sb",
        "hy2-sb",
        "tuic5-sb"
      ],
      "url": "https://cp.cloudflare.com/generate_204",
      "interval": "1m",
      "tolerance": 50,
      "interrupt_exist_connections": false
    }
  ],
  "route": {
      "geoip": {
      "download_url": "https://mirror.ghproxy.com/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.db",
      "download_detour": "select"
    },
    "geosite": {
      "download_url": "https://mirror.ghproxy.com/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.db",
      "download_detour": "select"
    },
    "auto_detect_interface": true,
    "final": "select",
    "rules": [
      {
        "outbound": "dns-out",
        "protocol": "dns"
      },
      {
        "clash_mode": "Direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "Global",
        "outbound": "select"
      },
      {
        "geosite": "cn",
        "geoip": [
          "cn",
          "private"
        ],
        "outbound": "direct"
      },
      {
        "geosite": "geolocation-!cn",
        "outbound": "select"
      }
    ]
  },
    "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m",
    "detour": "direct"
  }
}
EOF
cat > /etc/s-box/clash_meta_client.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
global-client-fingerprint: chrome
dns:
  enable: true
  listen: :53
  ipv6: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  default-nameserver: 
    - 223.5.5.5
    - 8.8.8.8
  nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - tls://dns.google
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4
proxies:
- name: vless-reality-vision节点               
  type: vless
  server: $server_ipcl                           
  port: $vl_port                                
  uuid: $uuid   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $vl_name                 
  reality-opts: 
    public-key: $public_key    
    short-id: $short_id                      
  client-fingerprint: chrome                  
- name: vmess-ws节点                         
  type: vmess
  server: $cl_vm_ip                        
  port: $vm_port                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: $tls
  network: ws
  servername: $vm_name                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: $vm_name                     
- name: hysteria2节点                            
  type: hysteria2                                      
  server: $cl_hy2_ip                               
  port: $hy2_port                                
  password: $uuid                              
  alpn:
    - h3
  sni: $hy2_name                               
  skip-cert-verify: $hy2_ins
  fast-open: true
- name: tuic5节点                            
  server: $cl_tu5_ip                      
  port: $tu5_port                                    
  type: tuic
  uuid: $uuid       
  password: $uuid   
  alpn: [h3]
  disable-sni: true
  reduce-rtt: true
  udp-relay-mode: native
  congestion-controller: bbr
  sni: $tu5_name                                
  skip-cert-verify: $tu5_ins  
proxy-groups:
- name: 负载均衡
  type: load-balance
  url: https://cp.cloudflare.com/generate_204
  interval: 300
  strategy: round-robin
  proxies:
    - vless-reality-vision节点                              
    - vmess-ws节点
    - hysteria2节点
    - tuic5节点
- name: 自动选择
  type: url-test
  url: https://cp.cloudflare.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    - vless-reality-vision节点                              
    - vmess-ws节点
    - hysteria2节点
    - tuic5节点
    
- name: 🌍选择代理节点
  type: select
  proxies:
    - 负载均衡                                         
    - 自动选择
    - DIRECT
    - vless-reality-vision节点                              
    - vmess-ws节点
    - hysteria2节点
    - tuic5节点
rules:
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,🌍选择代理节点
EOF
cat > /etc/s-box/v2rayn_hy2.yaml <<EOF
server: $sb_hy2_ip:$hy2_port
auth: $uuid
tls:
  sni: $hy2_name
  insecure: $hy2_ins
fastOpen: true
socks5:
  listen: 127.0.0.1:50000
lazy: true
transport:
  udp:
    hopInterval: 30s
EOF
cat > /etc/s-box/v2rayn_tu5.json <<EOF
{
    "relay": {
        "server": "$sb_tu5_ip:$tu5_port",
        "uuid": "$uuid",
        "password": "$uuid",
        "congestion_control": "bbr",
        "alpn": ["h3", "spdy/3.1"]
    },
    "local": {
        "server": "127.0.0.1:55555"
    },
    "log_level": "info"
}
EOF
if [[ -n $hy2_ports ]]; then
hy2_ports=",$hy2_ports"
hy2_ports=$(echo $hy2_ports | sed 's/:/-/g')
a=$hy2_ports
sed -i "/server:/ s/$/$a/" /etc/s-box/v2rayn_hy2.yaml
fi
sed -i 's/server: \(.*\)/server: "\1"/' /etc/s-box/v2rayn_hy2.yaml
}
cfargo(){
tls=$(jq -r '.inbounds[1].tls.enabled' /etc/s-box/sb.json)
if [[ "$tls" = "false" ]]; then
i=0
while [ $i -le 4 ]; do let i++
yellow "The $i-th refresh verifies the validity of the Cloudflared Argo tunnel domain name, please wait..."
if [[ -n $(ps -ef | grep cloudflared) ]]; then
kill -15 $(cat /etc/s-box/sbargopid.log) >/dev/null 2>&1
fi
/etc/s-box/cloudflared tunnel --url http://localhost:$(jq -r '.inbounds[1].listen_port' /etc/s-box/sb.json) --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box/argo.log 2>&1 &
echo "$!" > /etc/s-box/sbargopid.log
sleep 5
if [[ -n $(curl -sL https://$(cat /etc/s-box/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')/ -I | awk 'NR==1 && /404|400/') ]]; then
argo=$(cat /etc/s-box/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
blue "Argo tunnel application is successful, domain name verification is valid: $argo" && sleep 2
break
fi
if [ $i -eq 5 ]; then
yellow "Argo domain name verification is temporarily unavailable. It may be automatically restored later, or you may directly apply for reset." && sleep 2
fi
done
else
yellow "Because vmess has tls enabled, the Argo tunnel function is unavailable." && sleep 2
fi
}
instsllsingbox(){
if [[ -f '/etc/systemd/system/sing-box.service' ]]; then
red "Sing-box service has been installed and cannot be installed again" && exit
fi
mkdir -p /etc/s-box
v6 ; sleep 1
openyn ; sleep 1
inssb ; sleep 1
inscertificate ; sleep 1
insport ; sleep 1
echo
blue "Vless-reality related keys and ids will be automatically generated..."
key_pair=$(/etc/s-box/sing-box generate reality-keypair)
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
echo "$public_key" > /etc/s-box/public.key
short_id=$(/etc/s-box/sing-box generate rand --hex 4)
wget -q -O /root/geosite.db https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.db
wget -q -O /root/geoip.db https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.db
inssbjsonser && sbservice && sbactive
if [[ ! $vi =~ lxc|openvz ]]; then
sysctl -w net.core.rmem_max=2500000 >/dev/null 2>&1
sysctl -p >/dev/null 2>&1
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green "5. For vmess-ws protocol, add Cloudflared-Argo temporary tunnel function"
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
esac
curl -sL -o /etc/s-box/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu
chmod +x /etc/s-box/cloudflared
/etc/s-box/cloudflared tunnel --url http://localhost:$(jq -r '.inbounds[1].listen_port' /etc/s-box/sb.json) --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box/argo.log 2>&1 &
echo "$!" > /etc/s-box/sbargopid.log
sleep 5
if [[ -n $(curl -sL https://$(cat /etc/s-box/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')/ -I | awk 'NR==1 && /404|400/') ]]; then
argo=$(cat /etc/s-box/argo.log 2>/dev/null | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
blue "The Argo tunnel application is successful and the verification is valid. Domain name: $argo" && sleep 2
else
cfargo
fi
curl -sL https://gitlab.com/rwkgyg/sing-box-yg/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1 > /etc/s-box/v
clear
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
lnsb && blue "Sing-box is installed successfully and the script shortcut is sb" && cronsb
sbshare
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
blue "For the v2rayn configuration files, Clash-Meta, SFA/SFI/SFW client configuration files of Hysteria2 and Tuic5, please select 9 to view"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
}
changeym(){
[ -f /root/ygkkkca/ca.log ] && ymzs="$yellow switches to domain name certificate: $(cat /root/ygkkkca/ca.log 2>/dev/null)$plain" || ymzs="$yellow has not applied for a domain name certificate and cannot switch to $plain"
vl_na="Domain name certificate in use: $(jq -r '.inbounds[0].tls.server_name' /etc/s-box/sb.json). $yellow replaces the domain name certificate that meets the requirements of reality. It is not recommended to use the domain name with its own resolution $plain"
tls=$(jq -r '.inbounds[1].tls.enabled' /etc/s-box/sb.json)
[[ "$tls" = "false" ]] && vm_na="TLS is currently turned off. $ymzs ${yellow} switches to enable TLS, the Argo tunnel will be closed, you can enter the main menu option 4, change the port to https 443 series port, the main protocol can achieve CDN preferred IP${plain}" || vm_na="Domain name certificate in use: $(cat /root/ygkkkca/ca.log 2>/dev/null). $yellow is switched to turn off TLS, Argo tunnel will be available, you can enter the main menu option 4, change the port to http 80 series port, the main protocol can realize CDN preferred IP$plain"
hy2_sniname=$(jq -r '.inbounds[2].tls.key_path' /etc/s-box/sb.json)
[[ "$hy2_sniname" = '/etc/s-box/private.key' ]] && hy2_na="Using self-signed bing certificate. $ymzs" || hy2_na="Domain name certificate in use: $(cat /root/ygkkkca/ca.log 2>/dev/null). $yellow switches to self-signed bing certificate $plain"
tu5_sniname=$(jq -r '.inbounds[3].tls.key_path' /etc/s-box/sb.json)
[[ "$tu5_sniname" = '/etc/s-box/private.key' ]] && tu5_na="Using self-signed bing certificate. $ymzs" || tu5_na="Domain name certificate in use: $(cat /root/ygkkkca/ca.log 2>/dev/null). $yellow switches to self-signed bing certificate $plain"
green "Please select the protocol to switch certificate mode"
green "1: vless-reality protocol, $vl_na"
if [[ -f /root/ygkkkca/ca.log ]]; then
green "2: vmess-ws protocol, $vm_na"
green "3: Hysteria2 protocol, $hy2_na"
green "4: Tuic5 protocol, $tu5_na"
else
red "Only option 1 (vless-reality) is supported. Because the domain name certificate has not been applied for, the certificate switching options for vmess-ws, Hysteria-2, and Tuic-v5 are not displayed for the time being."
fi
green "0: Return to the upper level"
readp "please choose:" menu
if [ "$menu" = "1" ]; then
readp "Please enter the vless-reality domain name (press Enter to use www.yahoo.com):" menu
ym_vl_re=${menu:-www.yahoo.com}
a=$(jq -r '.inbounds[0].tls.server_name' /etc/s-box/sb.json)
b=$(jq -r '.inbounds[0].tls.reality.handshake.server' /etc/s-box/sb.json)
c=$(cat /etc/s-box/vl_reality.txt | cut -d'=' -f5 | cut -d'&' -f1)
sed -i "23s/$a/$ym_vl_re/" /etc/s-box/sb.json
sed -i "27s/$b/$ym_vl_re/" /etc/s-box/sb.json
systemctl restart sing-box
blue "The vless-reality domain name has been changed to $ym_vl_re"
result_vl_vm_hy_tu && resvless && sb_client
elif [ "$menu" = "2" ]; then
if [ -f /root/ygkkkca/ca.log ]; then
a=$(jq -r '.inbounds[1].tls.enabled' /etc/s-box/sb.json)
[ "$a" = "true" ] && a_a=false || a_a=true
b=$(jq -r '.inbounds[1].tls.server_name' /etc/s-box/sb.json)
[ "$b" = "www.bing.com" ] && b_b=$(cat /root/ygkkkca/ca.log) || b_b=$(cat /root/ygkkkca/ca.log)
c=$(jq -r '.inbounds[1].tls.certificate_path' /etc/s-box/sb.json)
d=$(jq -r '.inbounds[1].tls.key_path' /etc/s-box/sb.json)
if [ "$d" = '/etc/s-box/private.key' ]; then
c_c='/root/ygkkkca/cert.crt'
d_d='/root/ygkkkca/private.key'
else
c_c='/etc/s-box/cert.pem'
d_d='/etc/s-box/private.key'
fi
sed -i "53s#$a#$a_a#" /etc/s-box/sb.json
sed -i "54s#$b#$b_b#" /etc/s-box/sb.json
sed -i "57s#$c#$c_c#" /etc/s-box/sb.json
sed -i "58s#$d#$d_d#" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && resvmess && sb_client
else
red "No domain name certificate has been applied for currently and cannot be switched. Select 12 from the main menu to execute Acme certificate application" && sleep 2 && sb
fi
elif [ "$menu" = "3" ]; then
if [ -f /root/ygkkkca/ca.log ]; then
c=$(jq -r '.inbounds[2].tls.certificate_path' /etc/s-box/sb.json)
d=$(jq -r '.inbounds[2].tls.key_path' /etc/s-box/sb.json)
if [ "$d" = '/etc/s-box/private.key' ]; then
c_c='/root/ygkkkca/cert.crt'
d_d='/root/ygkkkca/private.key'
else
c_c='/etc/s-box/cert.pem'
d_d='/etc/s-box/private.key'
fi
sed -i "81s#$c#$c_c#" /etc/s-box/sb.json
sed -i "82s#$d#$d_d#" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && reshy2 && sb_client
else
red "No domain name certificate has been applied for currently and cannot be switched. Select 12 from the main menu to execute Acme certificate application" && sleep 2 && sb
fi
elif [ "$menu" = "4" ]; then
if [ -f /root/ygkkkca/ca.log ]; then
c=$(jq -r '.inbounds[3].tls.certificate_path' /etc/s-box/sb.json)
d=$(jq -r '.inbounds[3].tls.key_path' /etc/s-box/sb.json)
if [ "$d" = '/etc/s-box/private.key' ]; then
c_c='/root/ygkkkca/cert.crt'
d_d='/root/ygkkkca/private.key'
else
c_c='/etc/s-box/cert.pem'
d_d='/etc/s-box/private.key'
fi
sed -i "104s#$c#$c_c#" /etc/s-box/sb.json
sed -i "105s#$d#$d_d#" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && restu5 && sb_client
else
red "No domain name certificate has been applied for currently and cannot be switched. Select 12 from the main menu to execute Acme certificate application" && sleep 2 && sb
fi
else
sb
fi
}
allports(){
vl_port=$(jq -r '.inbounds[0].listen_port' /etc/s-box/sb.json)
vm_port=$(jq -r '.inbounds[1].listen_port' /etc/s-box/sb.json)
hy2_port=$(jq -r '.inbounds[2].listen_port' /etc/s-box/sb.json)
tu5_port=$(jq -r '.inbounds[3].listen_port' /etc/s-box/sb.json)
hy2_ports=$(iptables -t nat -nL --line 2>/dev/null | grep -w "$hy2_port" | awk '{print $8}' | sed 's/dpts://; s/dpt://' | tr '\n' ',' | sed 's/,$//')
tu5_ports=$(iptables -t nat -nL --line 2>/dev/null | grep -w "$tu5_port" | awk '{print $8}' | sed 's/dpts://; s/dpt://' | tr '\n' ',' | sed 's/,$//')
[[ -n $hy2_ports ]] && hy2zfport="$hy2_ports" || hy2zfport="Not added"
[[ -n $tu5_ports ]] && tu5zfport="$tu5_ports" || tu5zfport="Not added"
}
changeport(){
sbactive
allports
fports(){
readp "\nPlease enter the forwarded port range (in the range of 1000-65535, the format is small number:large number):" rangeport
if [[ $rangeport =~ ^([1-9][0-9]{3,4}:[1-9][0-9]{3,4})$ ]]; then
b=${rangeport%%:*}
c=${rangeport##*:}
if [[ $b -ge 1000 && $b -le 65535 && $c -ge 1000 && $c -le 65535 && $b -lt $c ]]; then
iptables -t nat -A PREROUTING -p udp --dport $rangeport -j DNAT --to-destination :$port
ip6tables -t nat -A PREROUTING -p udp --dport $rangeport -j DNAT --to-destination :$port
netfilter-persistent save >/dev/null 2>&1
service iptables save >/dev/null 2>&1
blue "Confirmed forwarded port range: $rangeport"
else
red "The entered port range is not within the valid range" && fports
fi
else
red "The input format is incorrect. The format is small number:big number" && fports
fi
echo
}
fport(){
readp "\nPlease enter a forwarded port (in the range of 1000-65535):" onlyport
if [[ $onlyport -ge 1000 && $onlyport -le 65535 ]]; then
iptables -t nat -A PREROUTING -p udp --dport $onlyport -j DNAT --to-destination :$port
ip6tables -t nat -A PREROUTING -p udp --dport $onlyport -j DNAT --to-destination :$port
netfilter-persistent save >/dev/null 2>&1
service iptables save >/dev/null 2>&1
blue "Confirmed forwarded port: $onlyport"
else
blue "The entered port is not within the valid range" && fport
fi
echo
}
hy2deports(){
allports
hy2_ports=$(echo "$hy2_ports" | sed 's/,/,/g')
IFS=',' read -ra ports <<< "$hy2_ports"
for port in "${ports[@]}"; do
iptables -t nat -D PREROUTING -p udp --dport $port -j DNAT --to-destination :$hy2_port
ip6tables -t nat -D PREROUTING -p udp --dport $port -j DNAT --to-destination :$hy2_port
done
netfilter-persistent save >/dev/null 2>&1
service iptables save >/dev/null 2>&1
}
tu5deports(){
allports
tu5_ports=$(echo "$tu5_ports" | sed 's/,/,/g')
IFS=',' read -ra ports <<< "$tu5_ports"
for port in "${ports[@]}"; do
iptables -t nat -D PREROUTING -p udp --dport $port -j DNAT --to-destination :$tu5_port
ip6tables -t nat -D PREROUTING -p udp --dport $port -j DNAT --to-destination :$tu5_port
done
netfilter-persistent save >/dev/null 2>&1
service iptables save >/dev/null 2>&1
}
allports
green "vless-reality and vmess-ws can only change the unique port"
green "Hysteria2 and Tuic5 support changing the main port and adding and deleting multiple forwarding ports."
green "Hysteria2 supports port hopping, and supports multi-port multiplexing with Tuic5."
green "1: vless-reality protocol ${yellow} port: $vl_port${plain}"
green "2: vmess-ws protocol ${yellow} port: $vm_port${plain}"
green "3: Hysteria2 protocol ${yellow} port: $hy2_port forwarding multi-port: $hy2zfport${plain}"
green "4: Tuic5 protocol ${yellow} port: $tu5_port forwarding multi-port: $tu5zfport${plain}"
green "0: Return to the upper level"
readp "Please select the protocol to change the port [0-4]:" menu
if [ "$menu" = "1" ]; then
vlport
sed -i "14s/$vl_port/$port_vl_re/" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && resvless && sb_client
elif [ "$menu" = "2" ]; then
vmport
sed -i "41s/$vm_port/$port_vm_ws/" /etc/s-box/sb.json
systemctl restart sing-box
cfargo
result_vl_vm_hy_tu && resvmess && sb_client
elif [ "$menu" = "3" ]; then
green "1: Replace the main port of Hysteria2 (the original multi-port is automatically reset and deleted)"
green "2: Add Hysteria2 multi-port"
green "3: Reset and delete Hysteria2 multi-port"
green "0: Return to the upper level"
readp "Please select【0-3】：" menu
if [ "$menu" = "1" ]; then
if [ -n $hy2_ports ]; then
hy2deports
hy2port
sed -i "67s/$hy2_port/$port_hy2/" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && reshy2 && sb_client
else
hy2port
sed -i "67s/$hy2_port/$port_hy2/" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && reshy2 && sb_client
fi
elif [ "$menu" = "2" ]; then
green "1: Add Hysteria2 range port"
green "2: Add Hysteria2 single port"
green "0: Return to the upper level"
readp "Please select [0-2]:" menu
if [ "$menu" = "1" ]; then
port=$(jq -r '.inbounds[2].listen_port' /etc/s-box/sb.json)
fports && result_vl_vm_hy_tu && sb_client && changeport
elif [ "$menu" = "2" ]; then
port=$(jq -r '.inbounds[2].listen_port' /etc/s-box/sb.json)
fport && result_vl_vm_hy_tu && sb_client && changeport
else
changeport
fi
elif [ "$menu" = "3" ]; then
if [ -n $hy2_ports ]; then
hy2deports && result_vl_vm_hy_tu && sb_client && changeport
else
yellow "Hysteria2 multi-port not set up" && changeport
fi
else
changeport
fi
elif [ "$menu" = "4" ]; then
green "1: Replace the Tuic5 main port (the original multi-port automatic reset is deleted)"
green "2: Add Tuic5 multi-port"
green "3: Reset and delete Tuic5 multi-port"
green "0: Return to the upper level"
readp "Please select【0-3】：" menu
if [ "$menu" = "1" ]; then
if [ -n $tu5_ports ]; then
tu5deports
tu5port
sed -i "91s/$tu5_port/$port_tu/" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && restu5 && sb_client
else
tu5port
sed -i "91s/$tu5_port/$port_tu/" /etc/s-box/sb.json
systemctl restart sing-box
result_vl_vm_hy_tu && restu5 && sb_client
fi
elif [ "$menu" = "2" ]; then
green "1: Add Tuic5 range port"
green "2: Add Tuic5 single port"
green "0: Return to the upper level"
readp "Please select [0-2]:" menu
if [ "$menu" = "1" ]; then
port=$(jq -r '.inbounds[3].listen_port' /etc/s-box/sb.json)
fports && result_vl_vm_hy_tu && sb_client && changeport
elif [ "$menu" = "2" ]; then
port=$(jq -r '.inbounds[3].listen_port' /etc/s-box/sb.json)
fport && result_vl_vm_hy_tu && sb_client && changeport
else
changeport
fi
elif [ "$menu" = "3" ]; then
if [ -n $tu5_ports ]; then
tu5deports && result_vl_vm_hy_tu && sb_client && changeport
else
yellow "Tuic5 is not set up with multiple ports" && changeport
fi
else
changeport
fi
else
sb
fi
}
changeuuid(){
olduuid=$(jq -r '.inbounds[0].users[0].uuid' /etc/s-box/sb.json)
green "Current uuid (password): $olduuid"
echo
readp "Enter the custom uuid, which must be in uuid format. If you don’t understand, press Enter (reset and randomly generate uuid):" menu
if [ -z "$menu" ]; then
uuid=$(/etc/s-box/sing-box generate uuid)
else
uuid=$menu
fi
blue "Confirmed uuid (password): ${uuid}" 
blue "The path of Vmess has been confirmed: ${uuid}-vm" && sleep 2
sed -i "s/$olduuid/$uuid/g" /etc/s-box/sb.json
systemctl restart sing-box
sbshare
}
changeip(){
v4v6
chip(){
rpip=$(jq -r '.outbounds[0].domain_strategy' /etc/s-box/sb.json)
sed -i "113s/$rpip/$rrpip/g" /etc/s-box/sb.json
systemctl restart sing-box
}
readp "1. IPV4 priority\n2. IPV6 priority\n3. IPV4 only\n4. IPV6 only\nPlease select:" choose
if [[ $choose == "1" && -n $v4 ]]; then
rrpip="prefer_ipv4" && chip && v4_6="IPV4 priority ($v4)"
elif [[ $choose == "2" && -n $v6 ]]; then
rrpip="prefer_ipv6" && chip && v4_6="IPV6 priority ($v6)"
elif [[ $choose == "3" && -n $v4 ]]; then
rrpip="ipv4_only" && chip && v4_6="IPV4 only ($v4)"
elif [[ $choose == "4" && -n $v6 ]]; then
rrpip="ipv6_only" && chip && v4_6="IPV6 only ($v6)"
else 
red "The IPV4/IPV6 address you selected does not currently exist, or is entered incorrectly" && changeip
fi
blue "Current changed IP priority: ${v4_6}" && sb
}
tgsbshow(){
echo
yellow "1: Reset/set the Telegram robot’s Token and user ID"
yellow "0: Return to the upper level"
readp "Please select [0-1]:" menu
if [ "$menu" = "1" ]; then
rm -rf /etc/s-box/sbtg.sh
readp "Enter Telegram robot Token:" token
telegram_token=$token
readp "Enter Telegram bot user ID:" userid
telegram_id=$userid
echo '#!/bin/bash
export LANG=en_US.UTF-8
m1=$(cat /etc/s-box/vl_reality.txt 2>/dev/null)
m2=$(cat /etc/s-box/vm_ws.txt 2>/dev/null)
m3=$(cat /etc/s-box/vm_ws_argo.txt 2>/dev/null)
m4=$(cat /etc/s-box/vm_ws_tls.txt 2>/dev/null)
m5=$(cat /etc/s-box/hy2.txt 2>/dev/null)
m6=$(cat /etc/s-box/tuic5.txt 2>/dev/null)
m7=$(cat /etc/s-box/sing_box_client.json 2>/dev/null)
m8=$(cat /etc/s-box/clash_meta_client.yaml 2>/dev/null)
message_text_m1=$(echo "$m1")
message_text_m2=$(echo "$m2")
message_text_m3=$(echo "$m3")
message_text_m4=$(echo "$m4")
message_text_m5=$(echo "$m5")
message_text_m6=$(echo "$m6")
message_text_m7=$(echo "$m7" | jq -c .)
message_text_m8=$(echo "$m8")
MODE=HTML
URL="https://api.telegram.org/bottelegram_token/sendMessage"
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[ Vless-reality-vision sharing link ]: Support v2rayng, nekobox, shadowrocket"$'"'"'\n\n'"'"'"${message_text_m1}")
if [[ -f /etc/s-box/vm_ws.txt ]]; then
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[ Vmess-ws sharing link ]: Support v2rayng, nekobox, shadowrocket"$'"'"'\n\n'"'"'"${message_text_m2}")
fi
if [[ -n $(ps -ef | grep cloudflared) && -s '/etc/s-box/argo.log' ]]; then
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀【 Vmess-ws(tls)+Argo sharing link】: Support v2rayng, nekobox, shadowrocket"$'"'"'\n\n'"'"'"${message_text_m3}")
fi
if [[ -f /etc/s-box/vm_ws_tls.txt ]]; then
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[ Vmess-ws-tls sharing link ]: Support v2rayng, nekobox, shadowrocket"$'"'"'\n\n'"'"'"${message_text_m4}")
fi
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[Hysteria-2 Sharing Link]: Supports nekobox and shadowrocket"$'"'"'\n\n'"'"'"${message_text_m5}")
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[ Tuic-v5 sharing link ]: Support nekobox, shadowrocket"$'"'"'\n\n'"'"'"${message_text_m6}")
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀【Sing-box configuration file】: Support SFA, SFI, SFW"$'"'"'\n\n'"'"'"${message_text_m7}")
res=$(timeout 20s curl -s -X POST $URL -d chat_id=telegram_id  -d parse_mode=${MODE} --data-urlencode "text=🚀[Clash-meta configuration file]: Supports CMFA, CMFW-V, CMFOC"$'"'"'\n\n'"'"'"${message_text_m8}")
if [ $? == 124 ];then
echo TG_api请求超时,请检查网络是否重启完成并是否能够访问TG
fi
resSuccess=$(echo "$res" | jq -r ".ok")
if [[ $resSuccess = "true" ]]; then
echo "TG push successful";
else
echo "TG push failed, please check the TG robot Token and ID";
fi
' > /etc/s-box/sbtg.sh
sed -i "s/telegram_token/$telegram_token/g" /etc/s-box/sbtg.sh
sed -i "s/telegram_id/$telegram_id/g" /etc/s-box/sbtg.sh
green "Setup is complete! Please make sure the TG robot is activated!"
tgnotice && sleep 3 && sb
else
changeserv
fi
}
tgnotice(){
if [[ -f /etc/s-box/sbtg.sh ]]; then
green "Please wait for 5 seconds, the TG robot is ready to push..."
sbshare > /dev/null 2>&1
bash /etc/s-box/sbtg.sh
else
red "The TG notification function is not set, please go to the main menu option 3 to set it." && sleep 2 && sb
fi
}
changeserv(){
sbactive
echo
green "Sing-box configuration change options are as follows:"
readp "1: Reality certificate replacement + other protocol self-signed certificates and domain name certificate switching (turn on or off sni certificate verification, TLS)\n2: Change the full protocol uuid (password)\n3: Reset the temporary domain name applied for Argo tunnel\n4: Switch local IPV4, IPV6 outbound priority\n5: Set Telegram robot notification function\n0: Return to the upper level\nPlease select [0-5]:" menu
if [ "$menu" = "1" ];then
changeym
elif [ "$menu" = "2" ];then
changeuuid
elif [ "$menu" = "3" ];then
cfargo
elif [ "$menu" = "4" ];then
changeip
elif [ "$menu" = "5" ];then
tgsbshow
else 
sb
fi
}
sbymfl(){
[[ $(systemctl is-active warp-svc 2>/dev/null) = active ]] && warp_s4_ip="Current IP: $(curl -4sx socks5h://localhost:40000 icanhazip.com -k)" || warp_s4_ip='无warp-s5的IPV4，黑名单模式'
[[ $(systemctl is-active warp-svc 2>/dev/null) = active ]] && warp_s6_ip="Current IP: $(curl -6sx socks5h://localhost:40000 icanhazip.com -k)" || warp_s6_ip='无warp-s5的IPV6，黑名单模式'
v4v6
if [[ -z $v4 ]]; then
vps_ipv4='无本地IPV4，黑名单模式'      
vps_ipv6="Current IP: $v6"
elif [[ -n $v4 &&  -n $v6 ]]; then
vps_ipv4="Current IP: $v4"    
vps_ipv6="Current IP: $v6"
else
vps_ipv4="Current IP: $v4"    
vps_ipv6='无本地IPV6，黑名单模式'
fi
unset swg4 swd4 swd6 swg6 ssd4 ssg4 ssd6 ssg6 sad4 sag4 sad6 sag6
wd4=$(jq -r '.route.rules[1].domain | join(" ")' /etc/s-box/sb.json)
wg4=$(jq -r '.route.rules[1].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$wd4" == "yg_kkk" && "$wg4" == "yg_kkk" ]]; then
wfl4="${yellow}[warp outbound IPV4 available] not diverted${plain}"
else
if [[ "$wd4" != "yg_kkk" ]]; then
swd4="$wd4 "
fi
if [[ "$wg4" != "yg_kkk" ]]; then
swg4=$wg4
fi
wfl4="${yellow}[warp outbound IPV4 available] has been diverted: $swd4$swg4${plain}"
fi
wd6=$(jq -r '.route.rules[2].domain | join(" ")' /etc/s-box/sb.json)
wg6=$(jq -r '.route.rules[2].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$wd6" == "yg_kkk" && "$wg6" == "yg_kkk" ]]; then
wfl6="${yellow}[warp outbound IPV6 available] not diverted${plain}"
else
if [[ "$wd6" != "yg_kkk" ]]; then
swd6="$wd6 "
fi
if [[ "$wg6" != "yg_kkk" ]]; then
swg6=$wg6
fi
wfl6="${yellow}[warp outbound IPV6 available] has been diverted: $swd6$swg6${plain}"
fi
sd4=$(jq -r '.route.rules[3].domain | join(" ")' /etc/s-box/sb.json)
sg4=$(jq -r '.route.rules[3].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$sd4" == "yg_kkk" && "$sg4" == "yg_kkk" ]]; then
sfl4="${yellow}【$warp_s4_ip】not diverted${plain}"
else
if [[ "$sd4" != "yg_kkk" ]]; then
ssd4="$sd4 "
fi
if [[ "$sg4" != "yg_kkk" ]]; then
ssg4=$sg4
fi
sfl4="${yellow}[$warp_s4_ip] has been diverted: $ssd4$ssg4${plain}"
fi
sd6=$(jq -r '.route.rules[4].domain | join(" ")' /etc/s-box/sb.json)
sg6=$(jq -r '.route.rules[4].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$sd6" == "yg_kkk" && "$sg6" == "yg_kkk" ]]; then
sfl6="${yellow}【$warp_s6_ip】not diverted${plain}"
else
if [[ "$sd6" != "yg_kkk" ]]; then
ssd6="$sd6 "
fi
if [[ "$sg6" != "yg_kkk" ]]; then
ssg6=$sg6
fi
sfl6="${yellow}[$warp_s6_ip] has been diverted: $ssd6$ssg6${plain}"
fi
ad4=$(jq -r '.route.rules[5].domain | join(" ")' /etc/s-box/sb.json)
ag4=$(jq -r '.route.rules[5].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$ad4" == "yg_kkk" && "$ag4" == "yg_kkk" ]]; then
adfl4="${yellow}【$vps_ipv4】not diverted${plain}" 
else
if [[ "$ad4" != "yg_kkk" ]]; then
sad4="$ad4 "
fi
if [[ "$ag4" != "yg_kkk" ]]; then
sag4=$ag4
fi
adfl4="${yellow}[$vps_ipv4] has been diverted: $sad4$sag4${plain}"
fi
ad6=$(jq -r '.route.rules[6].domain | join(" ")' /etc/s-box/sb.json)
ag6=$(jq -r '.route.rules[6].geosite | join(" ")' /etc/s-box/sb.json)
if [[ "$ad6" == "yg_kkk" && "$ag6" == "yg_kkk" ]]; then
adfl6="${yellow}【$vps_ipv6】not diverted${plain}" 
else
if [[ "$ad6" != "yg_kkk" ]]; then
sad6="$ad6 "
fi
if [[ "$ag6" != "yg_kkk" ]]; then
sag6=$ag6
fi
adfl6="${yellow}[$vps_ipv6] has been diverted: $sad6$sag6${plain}"
fi
}
changefl(){
sbactive
green "Unified domain name offloading for all protocols"
green "warp-wireguard is enabled by default, IPV4 and IPV6 are available (options 1 and 2)"
green "warp-socks5 requires the installation of warp official client (options 3 and 4)"
green "VPS local outbound traffic distribution. If warp option 1 is installed, the local IP will be taken over by the warp (options 5 and 6)"
yellow "Supports complete domain name mode (for example: www.google.com) and geosite mode (for example: netflix, disney, openai)"
yellow "Notice:"
yellow "1: In the complete domain name method, only the complete domain name can be filled in, and in the geosite method, only geosite can be filled in."
yellow "2: Do not divert traffic to the same complete domain name or geosite repeatedly."
yellow "3: If there is no network in the diversion channel, the diversion filled in is in blacklist mode (block the website)"
changef
}
changef(){
sbymfl
echo
green "1: Reset warp-wireguard-ipv4 diversion domain name $wfl4"
green "2: Reset warp-wireguard-ipv6 distribution domain name $wfl6"
green "3: Reset warp-socks5-ipv4 offload domain name $sfl4"
green "4: Reset warp-socks5-ipv6 offload domain name $sfl6"
green "5: Reset the VPS local ipv4 offload domain name $adfl4"
green "6: Reset VPS local ipv6 offload domain name $adfl6"
green "0: Return to the upper level"
echo
readp "Please select【0-6】：" menu
if [ "$menu" = "1" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name, and press Enter to skip the diversion channel that means resetting and clearing the full domain name of warp-wireguard-ipv4):" w4flym
if [ -z "$w4flym" ]; then
w4flym='"yg_kkk"'
else
w4flym="$(echo "$w4flym" | sed 's/ /","/g')"
w4flym="\"$w4flym\""
fi
sed -i "192s/.*/$w4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changef
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name, and press Enter to skip indicating that the geosite mode of warp-wireguard-ipv4 is reset and cleared):" w4flym
if [ -z "$w4flym" ]; then
w4flym='"yg_kkk"'
else
w4flym="$(echo "$w4flym" | sed 's/ /","/g')"
w4flym="\"$w4flym\""
fi
sed -i "195s/.*/$w4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changef
else
changef
fi
elif [ "$menu" = "2" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name and press Enter to skip the diversion channel to reset and clear the full domain name of warp-wireguard-ipv6:" w6flym
if [ -z "$w6flym" ]; then
w6flym='"yg_kkk"'
else
w6flym="$(echo "$w6flym" | sed 's/ /","/g')"
w6flym="\"$w6flym\""
fi
sed -i "201s/.*/$w6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name and press Enter to skip to reset and clear the geosite diversion channel of warp-wireguard-ipv6:" w6flym
if [ -z "$w6flym" ]; then
w6flym='"yg_kkk"'
else
w6flym="$(echo "$w6flym" | sed 's/ /","/g')"
w6flym="\"$w6flym\""
fi
sed -i "204s/.*/$w6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
else
changefl
fi
elif [ "$menu" = "3" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name, and press Enter to skip the diversion channel to reset and clear the full domain name of warp-socks5-ipv4:" s4flym
if [ -z "$s4flym" ]; then
s4flym='"yg_kkk"'
else
s4flym="$(echo "$s4flym" | sed 's/ /","/g')"
s4flym="\"$s4flym\""
fi
sed -i "210s/.*/$s4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name and press Enter to skip to reset and clear the geosite distribution channel of warp-socks5-ipv4:" s4flym
if [ -z "$s4flym" ]; then
s4flym='"yg_kkk"'
else
s4flym="$(echo "$s4flym" | sed 's/ /","/g')"
s4flym="\"$s4flym\""
fi
sed -i "213s/.*/$s4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
else
changefl
fi
elif [ "$menu" = "4" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name and press Enter to skip the diversion channel to reset and clear the full domain name of warp-socks5-ipv6:" s6flym
if [ -z "$s6flym" ]; then
s6flym='"yg_kkk"'
else
s6flym="$(echo "$s6flym" | sed 's/ /","/g')"
s6flym="\"$s6flym\""
fi
sed -i "219s/.*/$s6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name and press Enter to skip to reset and clear the geosite distribution channel of warp-socks5-ipv6:" s6flym
if [ -z "$s6flym" ]; then
s6flym='"yg_kkk"'
else
s6flym="$(echo "$s6flym" | sed 's/ /","/g')"
s6flym="\"$s6flym\""
fi
sed -i "222s/.*/$s6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
else
changefl
fi
elif [ "$menu" = "5" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name and press Enter to skip the diversion channel that indicates the complete domain name method of clearing the VPS local IPv4:" ad4flym
if [ -z "$ad4flym" ]; then
ad4flym='"yg_kkk"'
else
ad4flym="$(echo "$ad4flym" | sed 's/ /","/g')"
ad4flym="\"$ad4flym\""
fi
sed -i "228s/.*/$ad4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name, and press Enter to skip the geosite mode of clearing the VPS local IPv4 distribution channel:" ad4flym
if [ -z "$ad4flym" ]; then
ad4flym='"yg_kkk"'
else
ad4flym="$(echo "$ad4flym" | sed 's/ /","/g')"
ad4flym="\"$ad4flym\""
fi
sed -i "231s/.*/$ad4flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
else
changefl
fi
elif [ "$menu" = "6" ]; then
readp "1: Use the complete domain name method\n2: Use the geosite method\n3: Return to the upper level\nPlease select:" menu
if [ "$menu" = "1" ]; then
readp "Leave a space between each domain name, and press Enter to skip the diversion channel that indicates the complete domain name method of clearing the VPS local IPv6:" ad6flym
if [ -z "$ad6flym" ]; then
ad6flym='"yg_kkk"'
else
ad6flym="$(echo "$ad6flym" | sed 's/ /","/g')"
ad6flym="\"$ad6flym\""
fi
sed -i "237s/.*/$ad6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
elif [ "$menu" = "2" ]; then
readp "Leave a space between each domain name, and press Enter to skip the geosite mode of clearing the VPS local IPv6 distribution channel:" ad6flym
if [ -z "$ad6flym" ]; then
ad6flym='"yg_kkk"'
else
ad6flym="$(echo "$ad6flym" | sed 's/ /","/g')"
ad6flym="\"$ad6flym\""
fi
sed -i "240s/.*/$ad6flym/" /etc/s-box/sb.json
systemctl restart sing-box
changefl
else
changefl
fi
else
sb
fi
}
stclre(){
if [[ ! -f '/etc/s-box/sb.json' ]]; then
red "Sing-box is not installed properly" && exit
fi
readp "1: Restart\n2: Shut down\nPlease select:" menu
if [ "$menu" = "1" ]; then
systemctl enable sing-box
systemctl start sing-box
systemctl restart sing-box
sbactive
green "Sing-box service has been restarted\n" && sleep 3 && sb
elif [ "$menu" = "2" ]; then
systemctl stop sing-box
systemctl disable sing-box
green "Sing-box service is closed\n" && sleep 3 && sb
else
stclre
fi
}
cronsb(){
uncronsb
crontab -l > /tmp/crontab.tmp
echo "0 1 * * * systemctl restart sing-box" >> /tmp/crontab.tmp
echo '@reboot /bin/bash -c "/etc/s-box/cloudflared tunnel --url http://localhost:$(jq -r '.inbounds[1].listen_port' /etc/s-box/sb.json) --edge-ip-version auto --no-autoupdate --protocol http2 > /etc/s-box/argo.log 2>&1 & pid=\$! && echo \$pid > /etc/s-box/sbargopid.log"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
uncronsb(){
crontab -l > /tmp/crontab.tmp
sed -i '/sing-box/d' /tmp/crontab.tmp
sed -i '/sb.json/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
lnsb(){
curl -sL -o /usr/bin/sb https://raw.githubusercontent.com/hrostami/aio-proxy/master/4in1.sh
chmod +x /usr/bin/sb
}
upsbyg(){
if [[ ! -f '/usr/bin/sb' ]]; then
red "Sing-box-yg is not installed properly" && exit
fi
lnsb
curl -sL https://gitlab.com/rwkgyg/sing-box-yg/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1 > /etc/s-box/v
green "Sing-box-yg installation script upgraded successfully" && sleep 5 && sb
}
lapre(){
latcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
precore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | sed -n 4p | tr -d ',"' | awk '{print $1}')
inscore=$(/etc/s-box/sing-box version 2>/dev/null | awk '/version/{print $NF}')
}
upsbcroe(){
sbactive
lapre
[[ $inscore =~ ^[0-9.]+$ ]] && lat="[v$inscore installed]" || pre="[v$inscore installed]"
green "1: Upgrade/switch to the latest official version of Sing-box v$latcore ${bblue}${lat}${plain}"
green "2: Upgrade/switch to the latest beta version of Sing-box v$precore ${bblue}${pre}${plain}"
readp "please choose:" menu
if [ "$menu" = "1" ]; then
upcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | grep -Eo '"[0-9.]+",' | sed -n 1p | tr -d '",')
elif [ "$menu" = "2" ]; then
upcore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/SagerNet/sing-box | sed -n 4p | tr -d ',"' | awk '{print $1}')
else
sb
fi
green "Start downloading and updating Sing-box kernel... Please wait"
sbname="sing-box-$upcore-linux-$cpu"
wget -q -O /etc/s-box/sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v$upcore/$sbname.tar.gz
if [[ -f '/etc/s-box/sing-box.tar.gz' ]]; then
tar xzf /etc/s-box/sing-box.tar.gz -C /etc/s-box
mv /etc/s-box/$sbname/sing-box /etc/s-box
rm -rf /etc/s-box/{sing-box.tar.gz,$sbname}
if [[ -f '/etc/s-box/sing-box' ]]; then
chown root:root /etc/s-box/sing-box
chmod +x /etc/s-box/sing-box
systemctl restart sing-box
blue "Successfully upgraded/switched Sing-box kernel version: $(/etc/s-box/sing-box version | awk '/version/{print $NF}')" && sleep 3 && sb
else
red "The download of Sing-box kernel is incomplete and the installation failed. Please run the installation again." && upsbcroe
fi
else
red "Failed to download the Sing-box kernel. Please run the installation again and check whether the VPS network can access Github." && exit
fi
}
unins(){
systemctl stop sing-box >/dev/null 2>&1
systemctl disable sing-box >/dev/null 2>&1
kill -15 $(cat /etc/s-box/sbargopid.log >/dev/null 2>&1) 
rm -f /etc/systemd/system/sing-box.service
rm -rf /etc/s-box sbyg_update /usr/bin/sb /root/geosite.db /root/geoip.db
uncronsb
iptables -t nat -F PREROUTING >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
service iptables save >/dev/null 2>&1
green "Sing-box uninstallation completed!"
}
sblog(){
red "Exit log Ctrl+c"
systemctl status sing-box
journalctl -u sing-box.service -o cat -f
}
sbactive(){
if [[ ! -f /etc/s-box/sb.json ]]; then
red "Sing-box does not start normally. Please uninstall and reinstall or select 10 to view the running log feedback." && exit
fi
}
sbshare(){
result_vl_vm_hy_tu && resvless && resvmess && reshy2 && restu5 && sb_client
}
clash_sb_share(){
echo
yellow "1: View the latest sharing links and QR codes of each agreement"
yellow "2: View the latest Clash-Meta and Sing-box client SFA/SFI/SFW unified configuration files"
yellow "3: View the latest V2rayN client configuration files of Hysteria2 and Tuic5"
yellow "4: Push the latest node configuration information (1+2) to Telegram"
yellow "0: Return to the upper level"
readp "Please select【0-4】：" menu
if [ "$menu" = "1" ]; then
sbshare
elif  [ "$menu" = "2" ]; then
green "Please wait……"
sbshare > /dev/null 2>&1
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀[ vless-reality, vmess-ws, Hysteria2, Tuic5 ] The Clash-Meta configuration file is shown as follows:"
red "Supports Clash-Meta Android client, Clash-Verge computer client, soft router Openclash, and supports Gitlab private subscription link online configuration update"
red "File directory /etc/s-box/clash_meta_client.yaml , copy and build according to the yaml file format." && sleep 2
echo
cat /etc/s-box/clash_meta_client.yaml
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀[ vless-reality, vmess-ws, Hysteria2, Tuic5 ] The SFA/SFI/SFW configuration file is displayed as follows:"
red "Android SFA, Apple SFI (supports Gitlab private subscription link online configuration update), win computer official file package SFW, please go to the Yongge Github project to download it yourself."
red "File directory /etc/s-box/sing_box_client.json , copy and build according to the json file format." && sleep 2
echo
cat /etc/s-box/sing_box_client.json
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
elif  [ "$menu" = "3" ]; then
green "Please wait……"
sbshare > /dev/null 2>&1
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀【Hysteria-2】The v2rayn configuration file is shown as follows:"
red "Please download the official Hysteria2 client core, which supports multi-port hopping and multi-port multiplexing."
red "File directory /etc/s-box/v2rayn_hy2.yaml, copy and build according to the yaml file format." && sleep 2
echo
cat /etc/s-box/v2rayn_hy2.yaml
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
tu5_sniname=$(jq -r '.inbounds[3].tls.key_path' /etc/s-box/sb.json)
if [[ "$tu5_sniname" = '/etc/s-box/private.key' ]]; then
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
red "Note: When the V2rayN client uses the Tuic5 official client core, it does not support Tuic5 self-signed certificates and only supports domain name certificates." && sleep 2
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
else
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
red "🚀[Tuic-v5] The v2rayn configuration file is shown as follows:"
red "Please download the Tuic5 official client core. If you have set up multiple ports, please modify it yourself. Multi-port hopping is not supported and multi-port multiplexing is supported."
red "File directory /etc/s-box/v2rayn_tu5.json , copy and build according to the json file format." && sleep 2
echo
cat /etc/s-box/v2rayn_tu5.json
echo
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
fi
elif [ "$menu" = "4" ]; then
tgnotice
else
sb
fi
}
acme(){
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/acme-eng.sh)
}
cfwarp(){
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/warp.sh)
}
bbr(){
if [[ $vi =~ lxc|openvz ]]; then
yellow "The current VPS architecture is $vi and does not support original BBR acceleration." && sleep 2 && exit 
else
green "Click any key to turn on BBR acceleration, ctrl+c to exit"
bash <(curl -Ls https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
fi
}
showprotocol(){
allports
sbymfl
tls=$(jq -r '.inbounds[1].tls.enabled' /etc/s-box/sb.json)
if [[ "$tls" = "false" ]]; then
if [[ -n $(ps -ef | grep cloudflared) && -s '/etc/s-box/argo.log' && -n $(curl -sL https://$(cat /etc/s-box/argo.log | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')/ -I | awk 'NR==1 && /404|400/') ]]; then
vm_zs="TLS off"
argoym="Turned on"
else
vm_zs="TLS off"
argoym="Not turned on, can be reset to turn on"
fi
else
vm_zs="TLS enabled"
argoym="Does not support opening"
fi
hy2_sniname=$(jq -r '.inbounds[2].tls.key_path' /etc/s-box/sb.json)
[[ "$hy2_sniname" = '/etc/s-box/private.key' ]] && hy2_zs="self-signed certificate" || hy2_zs="Domain name certificate"
tu5_sniname=$(jq -r '.inbounds[3].tls.key_path' /etc/s-box/sb.json)
[[ "$tu5_sniname" = '/etc/s-box/private.key' ]] && tu5_zs="self-signed certificate" || tu5_zs="Domain name certificate"
echo -e "The key information of the Sing-box node and the diverted domain names are as follows:"
echo -e "🚀【 Vless-reality 】${yellow} port: $vl_port SNI domain name certificate: $(jq -r '.inbounds[0].tls.server_name' /etc/s-box/sb.json)${plain}"
if [[ "$tls" = "false" ]]; then
echo -e "🚀【 Vmess-ws 】${yellow} port: $vm_port Certificate format: $vm_zs Argo status: $argoym${plain}"
else
echo -e "🚀[ Vmess-ws-tls ] ${yellow} port: $vm_port Certificate format: $vm_zs Argo status: $argoym${plain}"
fi
echo -e "🚀【 Hysteria-2 】${yellow} port: $hy2_port Certificate format: $hy2_zs Forwarding multiple ports: $hy2zfport${plain}"
echo -e "🚀【 Tuic-v5 】${yellow} port: $tu5_port Certificate format: $tu5_zs Forwarding multiple ports: $tu5zfport${plain}"
if [ "$argoym" = "Turned on" ]; then
echo -e "UUID (password): ${yellow}$(jq -r '.inbounds[0].users[0].uuid' /etc/s-box/sb.json)${plain}"
echo -e "Argo temporary domain name: ${yellow}$(cat /etc/s-box/argo.log | grep -a trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2} ' | awk '{print $1}')${plain}"
fi
echo
ww4="warp-wireguard-ipv4 diversion domain name: $wfl4"
ww6="warp-wireguard-ipv6 diversion domain name: $wfl6"
ws4="warp-socks5-ipv4 diversion domain name: $sfl4"
ws6="warp-socks5-ipv6 diversion domain name: $sfl6"
l4="VPS local ipv4 offload domain name: $adfl4"
l6="VPS local ipv6 offload domain name: $adfl6"
ymflzu=("ww4" "ww6" "ws4" "ws6" "l4" "l6")
for ymfl in "${ymflzu[@]}"; do
if [[ ${!ymfl} != *"not yet"* ]]; then
echo -e "${!ymfl}"
fi
done
if [[ $ww4 = *"not yet"* && $ww6 = *"not yet"* && $ws4 = *"not yet"* && $ws6 = *"not yet"* && $l4 = *"not yet"* && $l6 = *"not yet"* ]] ; then
echo -e "Domain name diversion is not set up"
fi
}
clear
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
white "Yongge Github project: github.com/yonggekkk"
white "Yongge Blogger Blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
white "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
white "Vless-reality-vision, Vmess-ws(tls)+Argo, Hysteria-2, Tuic-v5 one-click four-protocol coexistence"
white "Sing-box-yg script shortcut: sb"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green " 1. Install Sing-box" 
green " 2. Uninstall Sing-box"
white "----------------------------------------------------------------------------------"
green " 3. Change configuration (dual certificate, UUID, Argo domain name, IP priority, TG notification)" 
green " 4. Change ports and add multi-port hop multiplexing" 
green " 5. Three major channels for custom domain name diversion" 
green " 6. Close and restart Sing-box"   
green " 7. Update Sing-box-yg script"
green "8. Update and switch Sing-box dual core"
white "----------------------------------------------------------------------------------"
green " 9. Real-time query/TG notification: sharing link, QR code, Clash-Meta, official SFA/SFI/SFW client configuration"
green "10. View Sing-box operation log"
green "11. One-click original BBR+FQ acceleration"
green "12. Manage Acme to apply for domain name certificate"
green "13. Manage Warp to view Netflix and ChatGPT unlocking status"
green " 0. Exit script"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
insV=$(cat /etc/s-box/v 2>/dev/null)
latestV=$(curl -sL https://gitlab.com/rwkgyg/sing-box-yg/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1)
if [ -f /etc/s-box/v ]; then
if [ "$insV" = "$latestV" ]; then
echo -e "The latest version of the current Sing-box-yg script: ${bblue}${insV}${plain} (already installed)"
else
echo -e "Current Sing-box-yg script version number: ${bblue}${insV}${plain}"
echo -e "The latest Sing-box-yg script version number detected: ${yellow}${latestV}${plain} (7 can be selected for update)"
echo -e "${yellow}$(curl -sL https://gitlab.com/rwkgyg/sing-box-yg/-/raw/main/version/version)${plain}"
fi
else
echo -e "Current Sing-box-yg script version number: ${bblue}${latestV}${plain}"
echo -e "Please select 1 first to install the Sing-box-yg script"
fi
lapre
if [ -f '/etc/s-box/sb.json' ]; then
if [[ $inscore =~ ^[0-9.]+$ ]]; then
if [ "${inscore}" = "${latcore}" ]; then
echo
echo -e "The latest official version of the current Sing-box kernel: ${bblue}${inscore}${plain} (already installed)"
echo
echo -e "Current Sing-box latest beta kernel: ${bblue}${precore}${plain} (switchable)"
else
echo
echo -e "Currently, Sing-box has installed the official version of the kernel: ${bblue}${inscore}${plain}"
echo -e "The latest Sing-box official version kernel detected: ${yellow}${latcore}${plain} (8 can be selected for update)"
echo
echo -e "Current Sing-box latest beta kernel: ${bblue}${precore}${plain} (switchable)"
fi
else
if [ "${inscore}" = "${precore}" ]; then
echo
echo -e "Current Sing-box latest beta kernel: ${bblue}${inscore}${plain} (installed)"
echo
echo -e "Current Sing-box latest official version kernel: ${bblue}${latcore}${plain} (switchable)"
else
echo
echo -e "Currently Sing-box has a beta kernel installed: ${bblue}${inscore}${plain}"
echo -e "The latest Sing-box beta kernel detected: ${yellow}${precore}${plain} (8 can be selected for update)"
echo
echo -e "Current Sing-box latest official version kernel: ${bblue}${latcore}${plain} (switchable)"
fi
fi
else
echo
echo -e "The latest official version of the current Sing-box kernel: ${bblue}${latcore}${plain}"
echo -e "Current Sing-box latest beta kernel: ${bblue}${precore}${plain}"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo -e "The VPS status is as follows:"
echo -e "System:$blue$op$plain \c";echo -e "Kernel:$blue$version$plain \c";echo -e "Processor:$blue$cpu$plain \c";echo -e "Virtualization:$blue$vi$plain \c";echo -e "BBR algorithm:$blue$bbr$plain"
v4v6
if [[ "$v6" == "2a09"* ]]; then
w6="【WARP】"
fi
if [[ "$v4" == "104.28"* ]]; then
w4="【WARP】"
fi
rpip=$(jq -r '.outbounds[0].domain_strategy' /etc/s-box/sb.json 2>/dev/null)
[[ -z $v4 ]] && showv4='IPV4地址丢失，请切换至IPV6或者重装Sing-box' || showv4=$v4$w4
[[ -z $v6 ]] && showv6='IPV6地址丢失，请切换至IPV4或者重装Sing-box' || showv6=$v6$w6
if [[ $rpip = 'prefer_ipv6' ]]; then
v4_6="IPV6 priority outbound ($showv6)"
elif [[ $rpip = 'prefer_ipv4' ]]; then
v4_6="IPV4 priority outbound ($showv4)"
elif [[ $rpip = 'ipv4_only' ]]; then
v4_6="IPV4 outbound only ($showv4)"
elif [[ $rpip = 'ipv6_only' ]]; then
v4_6="IPV6 outbound only ($showv6)"
fi
if [[ -z $v4 ]]; then
vps_ipv4='无IPV4'      
vps_ipv6="$v6"
elif [[ -n $v4 &&  -n $v6 ]]; then
vps_ipv4="$v4"    
vps_ipv6="$v6"
else
vps_ipv4="$v4"    
vps_ipv6='无IPV6'
fi
echo -e "Local IPV4 address: $blue$vps_ipv4$w4$plain Local IPV6 address: $blue$vps_ipv6$w6$plain"
if [[ -n $rpip ]]; then
echo -e "Local IP priority: $blue$v4_6$plain"
fi
if [[ -n $(systemctl status sing-box 2>/dev/null | grep -w active) && -f '/etc/s-box/sb.json' ]]; then
echo -e "Sing-box status: $green is running $plain"
elif [[ -z $(systemctl status sing-box 2>/dev/null | grep -w active) && -f '/etc/s-box/sb.json' ]]; then
echo -e "Sing-box status: $yellow has not been started. You can choose 6 to restart. If it is still the same, choose 10 to view the log and give feedback. It is recommended to uninstall and reinstall Sing-box$plain."
else
echo -e "Sing-box status: $red is not installed $plain"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [ -f '/etc/s-box/sb.json' ]; then
showprotocol
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
readp "Please enter a number【0-13】:" Input
case "$Input" in  
 1 ) instsllsingbox;;
 2 ) unins;;
 3 ) changeserv;;
 4 ) changeport;;
 5 ) changefl;;
 6 ) stclre;;
 7 ) upsbyg;; 
 8 ) upsbcroe;;
 9 ) clash_sb_share;;
10 ) sblog;;
11 ) bbr;;
12 ) acme;;
13 ) cfwarp;;
 * ) exit 
esac
