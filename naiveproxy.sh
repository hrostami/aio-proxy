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
red "The script does not support the current system, please choose to use Ubuntu, Debian, Centos system." && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
red "The script does not support the current $op system, please choose to use Ubuntu, Debian, Centos system." && exit
fi
latcore=v`curl -Ls https://data.jsdelivr.com/v1/package/gh/klzgrad/naiveproxy | sed -n 4p | tr -d ',"' | awk '{print $1}'`
inscore=`cat /etc/caddy/version 2>/dev/null | head -n 1`
insV=$(cat /etc/caddy/v 2>/dev/null)
latestV=$(curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "update content" 'NR>2 {print $1; exit}')
version=$(uname -r | cut -d "-" -f1)
vi=$(systemd-detect-virt 2>/dev/null)
bit=$(uname -m)
if [[ $bit = x86_64 ]]; then
cpu=amd64
elif [[ $bit = aarch64 ]]; then
cpu=arm64
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
if [ ! -f nayg_update ]; then
green "Install the necessary dependencies of the Naiveproxy-yg script for the first time..."
if [[ -z $vi ]]; then
apt update iproute2 systemctl -y
fi
update(){
if [ -x "$(command -v apt-get)" ]; then
apt update -y
elif [ -x "$(command -v yum)" ]; then
yum update -y && yum install epel-release -y
elif [ -x "$(command -v dnf)" ]; then
dnf update -y
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
packages=("curl" "openssl" "jq" "tar" "qrencode" "wget" "cron")
inspackages=("curl" "openssl" "jq" "tar" "qrencode" "wget" "cron")
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
yum install -y cronie
elif [ -x "$(command -v dnf)" ]; then
dnf install -y cronie
fi
fi
update
touch nayg_update
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
warpcheck
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4=$(curl -s4m5 icanhazip.com -k)
if [ -z $v4 ]; then
yellow "Pure IPV6 VPS detected, add DNS64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
fi
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
blue "Execute open port and close firewall."
echo "----------------------------------------------------"
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
forwardproxy(){
go env -w GO111MODULE=on
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
}
rest(){
if [[ ! -f /root/caddy ]]; then
red "caddy2-naiveproxy build failed and the script exited" && exit
fi
chmod +x caddy
mv caddy /usr/bin/
}
inscaddynaive(){
echo
naygvsion=`curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | head -n 1`
yellow "1. Please choose to install or update the naiveproxy kernel method:"
readp "1. Compiled caddy2-naiveproxy version: $naygvsion (fast installation, highly recommended, press Enter to default)\n2. Online compiled caddy2-naiveproxy version: $latcore (slow installation, compilation failure may occur)\nPlease select:" chcaddynaive
if [ -z "$chcaddynaive" ] || [ $chcaddynaive == "1" ]; then
cd /root
wget -qN https://gitlab.com/rwkgyg/naiveproxy-yg/raw/main/caddy2-naive-linux-${cpu}.tar.gz
wget -qN https://gitlab.com/rwkgyg/naiveproxy-yg/raw/main/version
tar zxvf caddy2-naive-linux-${cpu}.tar.gz
rm caddy2-naive-linux-${cpu}.tar.gz -f
cd
rest
elif [ $chcaddynaive == "2" ]; then
if [[ $release = Centos ]] && [[ ${vsid} =~ 8 ]]; then
green "Centos 8 system recommends using the compiled caddy2-naiveproxy version" && inscaddynaive
fi
cd /root
if [[ $release = Centos ]]; then 
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install golang && forwardproxy
elif [[ $release = Debian ]]; then
apt install software-properties-common -y
apt update
$GOLANG_VERSION = `curl -Ls https://golang.google.cn/dl/ | grep -oE "go[0-9.]+.linux-$cpu.tar.gz" | head -n 1 | cut  -c3-8`
wget -c https://golang.google.cn/dl/go$GOLANG_VERSION.linux-$cpu.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-$cpu.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
forwardproxy
else
apt install software-properties-common -y
add-apt-repository ppa:longsleep/golang-backports 
apt update 
apt install golang-go && forwardproxy
fi
cd
rest
lastvsion=v`curl -Ls https://data.jsdelivr.com/v1/package/gh/klzgrad/naiveproxy | sed -n 4p | tr -d ',"' | awk '{print $1}'`
echo $lastvsion > /root/version
else 
red "Input error, please choose again" && inscaddynaive
fi
version(){
if [[ ! -d /etc/caddy/ ]]; then
mkdir /etc/caddy >/dev/null 2>&1
fi
mv version /etc/caddy/
}
version
echo "----------------------------------------------------"
}
inscertificate(){
echo
yellow "2. The application method for Naiveproxy protocol certificate is as follows:"
readp "1. acme one-click certificate application script (supports regular 80 port mode and dns api mode), the certificate applied with this script will be automatically recognized (press enter to default)\n2. Customized certificate path (not /root/ygkkkca path) \nPlease select:" certificate
if [ -z "${certificate}" ] || [ $certificate == "1" ]; then
if [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key ]] && [[ -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]] && [[ -f /root/ygkkkca/ca.log ]]; then
blue "After testing, I have used this acme script to apply for a certificate before."
readp "1. Use the original certificate directly (press Enter to default)\n2. Delete the original certificate and apply for a new certificate\nPlease choose:" certacme
if [ -z "${certacme}" ] || [ $certacme == "1" ]; then
ym=$(cat /root/ygkkkca/ca.log)
blue "Detected domain name: $ym, directly referenced"
elif [ $certacme == "2" ]; then
curl https://get.acme.sh | sh
bash /root/.acme.sh/acme.sh --uninstall
rm -rf /root/ygkkkca
rm -rf ~/.acme.sh acme.sh
sed -i '/--cron/d' /etc/crontab
[[ -z $(/root/.acme.sh/acme.sh -v 2>/dev/null) ]] && green "acme.sh uninstallation completed" || red "acme.sh uninstallation failed"
sleep 2
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/acme-eng.sh)
ym=$(cat /root/ygkkkca/ca.log)
if [[ ! -f /root/ygkkkca/cert.crt && ! -f /root/ygkkkca/private.key ]] && [[ ! -s /root/ygkkkca/cert.crt && ! -s /root/ygkkkca/private.key ]]; then
red "The certificate application failed and the script exited" && exit
fi
fi
else
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/acme-eng.sh)
ym=$(cat /root/ygkkkca/ca.log)
if [[ ! -f /root/ygkkkca/cert.crt && ! -f /root/ygkkkca/private.key ]] && [[ ! -s /root/ygkkkca/cert.crt && ! -s /root/ygkkkca/private.key ]]; then
red "The certificate application failed and the script exited" && exit
fi
fi
certificatec='/root/ygkkkca/cert.crt'
certificatep='/root/ygkkkca/private.key'
elif [ $certificate == "2" ]; then
readp "Please enter the path to the placed public key file crt (/a/b/…/cert.crt):" cerroad
blue "The path of the public key file crt: $cerroad"
readp "Please enter the path to the placed key file key (/a/b/…/private.key):" keyroad
blue "Path to key file key: $keyroad"
certificatec=$cerroad
certificatep=$keyroad
readp "Please enter the resolved domain name:" ym
blue "Resolved domain name: $ym"
else 
red "Input error, please choose again" && inscertificate
fi
echo "----------------------------------------------------"
}
insport(){
echo
readp "3. Set the Naiveproxy port [1-65535] (press Enter to skip to a random port between 2000-65535):" port
if [[ -z $port ]]; then
port=$(shuf -i 2000-65535 -n 1)
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] 
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" port
done
else
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" port
done
fi
blue "Confirmed port: $port"
echo "----------------------------------------------------"
}
insuser(){
echo
readp "4. Set the user name, which must be more than 3 characters (press Enter to skip to random 3 characters):" user
if [[ -z ${user} ]]; then
user=`date +%s%N |md5sum | cut -c 1-3`
else
if [[ 3 -ge ${#user} ]]; then
until [[ 3 -le ${#user} ]]
do
[[ 3 -ge ${#user} ]] && yellow "\nThe username must be more than 3 characters! please enter again" && readp "\nSet username:" user
done
fi
fi
blue "Confirmed username: ${user}"
echo "----------------------------------------------------"
}
inspswd(){
echo
readp "5. Set a password, which must be more than 5 characters (press Enter to skip to a random 5 characters):" pswd
if [[ -z ${pswd} ]]; then
pswd=`date +%s%N |md5sum | cut -c 1-5`
else
if [[ 5 -ge ${#pswd} ]]; then
until [[ 5 -le ${#pswd} ]]
do
[[ 5 -ge ${#pswd} ]] && yellow "\nThe username must be more than 5 characters! please enter again" && readp "\nSet password:" pswd
done
fi
fi
blue "Confirmed password: ${pswd}"
echo "----------------------------------------------------"
}
insweb(){
echo
readp "6. Set up the disguised URL. Note: Do not bring http(s):// (Enter to skip, the default is Yongge’s blog address: ygkkk.blogspot.com):" web
if [[ -z ${web} ]]; then
naweb=ygkkk.blogspot.com
else
naweb=$web
fi
blue "Confirmed disguised URL: ${naweb}"
echo "----------------------------------------------------"
}
insconfig(){
echo
readp "7. Set caddy2-naiveproxy listening port [1-65535] (press Enter to skip to a random port between 2000-65535):" caddyport
if [[ -z $caddyport ]]; then
caddyport=$(shuf -i 2000-65535 -n 1)
if [[ $caddyport == $port ]]; then
yellow "\nThe port is occupied, please re-enter the port." && readp "Customize caddy2-naiveproxy listening port:" caddyport
fi
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]] 
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" caddyport
done
else
until [[ -z $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]]
do
[[ -n $(ss -tunlp | grep -w tcp | awk '{print $5}' | sed 's/.*://g' | grep -w "$caddyport") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom port:" caddyport
done
fi
blue "Confirmed port: $caddyport\n"
green "Set the configuration file and service process of naiveproxy...\n"
mkdir /root/naive >/dev/null 2>&1
mkdir /etc/caddy >/dev/null 2>&1
cat << EOF >/etc/caddy/Caddyfile
{
http_port $caddyport
}
:$port, $ym:$port {
tls ${certificatec} ${certificatep} 
route {
 forward_proxy {
   basic_auth ${user} ${pswd}
   hide_ip
   hide_via
   probe_resistance
  }
 reverse_proxy  https://$naweb {
   header_up  Host  {upstream_hostport}
   header_up  X-Forwarded-Host  {host}
  }
}
}
EOF
cat <<EOF > /root/naive/v2rayn.json
{
  "listen": "socks://127.0.0.1:1080",
  "proxy": "https://${user}:${pswd}@${ym}:$port"
}
EOF
cat << EOF >/etc/systemd/system/caddy.service
[Unit]
Description=YGKKK-Caddy2-naiveproxy
Documentation=https://gitlab.com/rwkgyg/naiveproxy-yg
After=network.target network-online.target
Requires=network-online.target
[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
PrivateTmp=false
NoNewPrivileges=yes
ProtectHome=false
ProtectSystem=false
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable caddy >/dev/null 2>&1
systemctl start caddy
}
stclre(){
if [[ ! -f '/etc/caddy/Caddyfile' ]]; then
green "naiveproxy is not installed properly" && exit
fi
green "The naiveproxy service performs the following operations"
readp "1. Restart\n2. Shut down\n0. Return to the upper level\nPlease select:" action
if [[ $action == "1" ]]; then
systemctl enable caddy
systemctl start caddy
systemctl restart caddy
green "naiveproxy service restart\n"
elif [[ $action == "2" ]]; then
systemctl stop caddy
systemctl disable caddy
green "naiveproxy service is closed\n"
else
na
fi
}
changeserv(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "naiveproxy is not installed properly" && exit
fi
green "The naiveproxy configuration change options are as follows:"
readp "1. Add or delete multi-port reuse (one port is added each time it is executed)\n2. Change the main port\n3. Change the user name\n4. Change the password\n5. Re-apply for a certificate or change the certificate path\n6. Change the disguised web page \n0. Return to the upper level\nPlease select:" choose
if [ $choose == "1" ];then
duoport
elif [ $choose == "2" ];then
changeport
elif [ $choose == "3" ];then
changeuser
elif [ $choose == "4" ];then
changepswd
elif [ $choose == "5" ];then
inscertificate
oldcer=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 5p | awk '{print $2}'`
oldkey=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 5p | awk '{print $3}'`
sed -i "s#$oldcer#${certificatec}#g" /etc/caddy/Caddyfile
sed -i "s#$oldkey#${certificatep}#g" /etc/caddy/Caddyfile
sed -i "s#$oldcer#${certificatec}#g" /etc/caddy/reCaddyfile
sed -i "s#$oldkey#${certificatep}#g" /etc/caddy/reCaddyfile
oldym=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 4p | awk '{print $2}'| awk -F":" '{print $1}'`
sed -i "s/$oldym/${ym}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
elif [ $choose == "6" ];then
changeweb
else 
na
fi
}
duoport(){
naiveports=`cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:'`
green "\nThe port currently being used by naiveproxy:"
blue "$naiveports"
readp "\n1. Add multi-port multiplexing\n2. Restore only one main port\n0. Return to the upper layer\nPlease select:" choose
if [ $choose == "1" ]; then
oldport1=`cat /etc/caddy/reCaddyfile 2>/dev/null | sed -n 4p | awk '{print $1}'| tr -d ',:'`
insport
sed -i "s/$oldport1/$port/g" /etc/caddy/reCaddyfile
cat /etc/caddy/reCaddyfile 2>/dev/null | tail -15 >> /etc/caddy/Caddyfile
sussnaiveproxy
elif [ $choose == "2" ]; then
sed -i '19,$d' /etc/caddy/Caddyfile 2>/dev/null
sussnaiveproxy
else 
changeserv
fi
}
changeuser(){
olduserc=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 8p | awk '{print $2}'`
echo
blue "Username currently in use: $olduserc"
echo
insuser
sed -i "s/$olduserc/${user}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
}
changepswd(){
oldpswdc=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 8p | awk '{print $3}'`
echo
blue "Password currently in use: $oldpswdc"
echo
inspswd
sed -i "s/$oldpswdc/${pswd}/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile /root/naive/URL.txt /root/naive/v2rayn.json
sussnaiveproxy
}
changeport(){
oldport1=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 4p | awk '{print $1}'| tr -d ',:'`
echo
blue "Main port currently in use: $oldport1"
echo
insport
sed -i "s/$oldport1/$port/g" /etc/caddy/Caddyfile /root/naive/v2rayn.json /root/naive/URL.txt
sussnaiveproxy
}
changeweb(){
oldweb=`cat /etc/caddy/Caddyfile 2>/dev/null | sed -n 13p | awk '{print $2}'`
echo
blue "Currently using the disguised URL: $oldweb"
echo
insweb
sed -i "s/$oldweb/$naweb/g" /etc/caddy/Caddyfile /etc/caddy/reCaddyfile
sussnaiveproxy
}
acme(){
bash <(curl -L -s https://raw.githubusercontent.com/hrostami/aio-proxy/master/acme-eng.sh)
}
cfwarp(){
bash <(curl -Ls https://raw.githubusercontent.com/hrostami/aio-proxy/master/warp.sh)
}
bbr(){
bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
}
lnna(){
curl -sL -o /usr/bin/na https://raw.githubusercontent.com/hrostami/aio-proxy/master/naiveproxy.sh
chmod +x /usr/bin/na
}
upnayg(){
if [[ ! -f '/etc/caddy/Caddyfile' ]]; then
red "Naiveproxy-yg is not installed properly" && exit
fi
lnna
curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "update content" 'NR>2 {print $1; exit}' > /etc/caddy/v
green "Naiveproxy-yg installation script upgraded successfully" && sleep 5 && na
}
upnaive(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "naiveproxy is not installed properly" && exit
fi
green "\nUpgrade naiveproxy kernel version\n"
inscaddynaive
systemctl restart caddy
green "naiveproxy kernel version upgraded successfully" && na
}
unins(){
systemctl stop caddy >/dev/null 2>&1
systemctl disable caddy >/dev/null 2>&1
rm -f /etc/systemd/system/caddy.service
rm -rf /usr/bin/caddy /etc/caddy /root/naive /usr/bin/na /root/nayg_update
green "naiveproxy uninstallation completed!"
}
sussnaiveproxy(){
systemctl restart caddy
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
green "The naiveproxy service started successfully" && naiveproxyshare
else
red "The naiveproxy service failed to start. Please run systemctl status caddy to view the service status and provide feedback. The script exits." && exit
fi
}
naiveproxyshare(){
if [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && ! -f '/etc/caddy/Caddyfile' ]]; then
red "naiveproxy is not installed properly" && exit
fi
red "======================================================================================"
naiveports=`cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:'`
green "\nThe port currently being used by naiveproxy:" && sleep 2
blue "$naiveports\n"
green "The content of the current v2rayn client configuration file v2rayn.json is as follows, save it to /root/naive/v2rayn.json\n"
yellow "$(cat /root/naive/v2rayn.json)\n" && sleep 2
green "The current naiveproxy node sharing link is as follows, save it to /root/naive/URL.txt"
yellow "$(cat /root/naive/URL.txt)\n" && sleep 2
green "The current naiveproxy node QR code sharing link is as follows (Nekobox)"
qrencode -o - -t ANSIUTF8 "$(cat /root/naive/URL.txt)"
}
insna(){
if [[ -f '/etc/caddy/Caddyfile' ]]; then
green "Naiveproxy has been installed. Please perform the uninstall function before reinstalling." && exit
fi
rm -f /etc/systemd/system/caddy.service
rm -rf /usr/bin/caddy /etc/caddy /root/naive /usr/bin/na
v6 ; openyn ; inscaddynaive ; inscertificate ; insport ; insuser ; inspswd ; insweb ; insconfig
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
green "The naiveproxy service started successfully"
lnna
curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "update content" 'NR>2 {print $1; exit}' > /etc/caddy/v
cp -f /etc/caddy/Caddyfile /etc/caddy/reCaddyfile >/dev/null 2>&1
if [[ ! $vi =~ lxc|openvz ]]; then
sysctl -w net.core.rmem_max=8000000 >/dev/null 2>&1
sysctl -p >/dev/null 2>&1
fi
else
red "The naiveproxy service failed to start. Please run systemctl status caddy to view the service status and provide feedback. The script exits." && exit
fi
red "======================================================================================"
url="naive+https://${user}:${pswd}@${ym}:$port?padding=true#Naive-$(hostname)"
echo ${url} > /root/naive/URL.txt
green "\nnaiveproxy proxy service installation is complete, the shortcut to generate the script is na" && sleep 3
green "\nv2rayn client configuration file v2rayn.json is saved to /root/naive/v2rayn.json\n"
yellow "$(cat /root/naive/v2rayn.json)\n"
green "Share the link and save it to /root/naive/URL.txt" && sleep 3
yellow "${url}\n"
green "The QR code sharing link is as follows (Nekobox)" && sleep 2
qrencode -o - -t ANSIUTF8 "$(cat /root/naive/URL.txt)"
}
nalog(){
echo
red "To exit Naiveproxy log viewing, please press Ctrl+c"
echo
journalctl -u caddy --output cat -f
}
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
white "Yongge Github project: github.com/yonggekkk"
white "Yongge Blogger Blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
green "After the Naiveproxy-yg script is installed successfully, the shortcut to enter the script again is na"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
green " 1. Install Naiveproxy" 
green " 2. Uninstall Naiveproxy"
white "----------------------------------------------------------------------------------"
green " 3. Change configuration (multi-port reuse, user name and password, certificate, disguised web page)" 
green " 4. Close and restart Naiveproxy"   
green " 5. Update Naiveproxy-yg installation script"
green " 6. Update Naiveproxy kernel version"
white "----------------------------------------------------------------------------------"
green " 7. Display Naiveproxy sharing link, V2rayN configuration file, and QR code"
green " 8. View the Naiveproxy operation log"
green " 9. Manage Acme to apply for a domain name certificate"
green "10. Manage Warp to view Netflix and ChatGPT unlocking status"
green "11. One-click original BBR+FQ acceleration"
green " 0. Exit script"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [ -f /etc/caddy/v ]; then
if [ "$insV" = "$latestV" ]; then
echo -e "The latest version of the current Naiveproxy-yg script: ${bblue}${insV}${plain} (already installed)"
else
echo -e "Current Naiveproxy-yg script version number: ${bblue}${insV}${plain}"
echo -e "The latest Naiveproxy-yg script version number detected: ${yellow}${latestV}${plain} (5 can be selected for update)"
echo -e "${yellow}$(curl -sL https://gitlab.com/rwkgyg/naiveproxy-yg/-/raw/main/version | awk -F "update content" 'NR>2 {print $1}')${plain}"
fi
else
echo -e "Current Naiveproxy-yg script version number: ${bblue}${latestV}${plain}"
echo -e "Please select 1 first to install the Naiveproxy-yg script"
fi
if [ -f /etc/caddy/v ]; then
if [ "$inscore" = "$latcore" ]; then
echo -e "Current Naiveproxy latest kernel version: ${bblue}${inscore}${plain} (installed)"
else
echo -e "Currently Naiveproxy has installed kernel version: ${bblue}${inscore}${plain}"
echo -e "The latest Naiveproxy kernel version detected: ${yellow}${latcore}${plain} (optional 6 for update)"
fi
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
if [[ -z $v4 ]]; then
vps_ipv4='无IPV4'      
vps_ipv6="$v6"
elif [[ -n $v4 && -n $v6 ]]; then
vps_ipv4="$v4"    
vps_ipv6="$v6"
else
vps_ipv4="$v4"    
vps_ipv6='无IPV6'
fi
echo -e "Local IPV4 address: $blue$vps_ipv4$w4$plain Local IPV6 address: $blue$vps_ipv6$w6$plain"
naiveports=$(cat /etc/caddy/Caddyfile 2>/dev/null | awk '{print $1}' | grep : | tr -d ',:' | tr '\n' ' ')
if [[ -n $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
echo -e "Naiveproxy status: $green running $plain Proxy ports: $green $naiveports$plain"
elif [[ -z $(systemctl status caddy 2>/dev/null | grep -w active) && -f '/etc/caddy/Caddyfile' ]]; then
echo -e "Naiveproxy status: $yellow is not started. You can choose 4 to restart. If it is still the same, choose 8 to view the log and give feedback. It is recommended to uninstall and reinstall Naiveproxy-yg$plain."
else
echo -e "Naiveproxy status: $red is not installed $plain"
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
readp "Please enter a number [0-11]:" Input
case "$Input" in     
 1 ) insna;;
 2 ) unins;;
 3 ) changeserv;;
 4 ) stclre;;
 5 ) upnayg;; 
 6 ) upnaive;;
 7 ) naiveproxyshare;;
 8 ) nalog;;
 9 ) acme;;
10 ) cfwarp;;
11 ) bbr;;
 * ) exit;; 
esac
