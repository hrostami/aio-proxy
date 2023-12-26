#!/bin/bash 
export LANG=en_US.UTF-8
red='\033[0;31m'
bblue='\033[0;34m'
plain='\033[0m'
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
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
red "Your current system is not supported, please choose to use Ubuntu, Debian, Centos system" && exit 
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
red "The script does not support your current $op system, please choose to use Ubuntu, Debian, Centos system." && exit
fi
v4v6(){
v4=$(curl -s4m6 icanhazip.com -k)
v6=$(curl -s6m6 icanhazip.com -k)
}
acme1(){
if [ ! -f acyg_update ]; then
green "Install the necessary dependencies of the Acme-yg script for the first time..."
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
packages=("curl" "openssl" "lsof" "socat" "dnsutils" "tar" "wget" "cron")
inspackages=("curl" "openssl" "lsof" "socat" "dnsutils" "tar" "wget" "cron")
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
if ! command -v "cronie" &> /dev/null; then
if [ -x "$(command -v yum)" ]; then
yum install -y cronie
elif [ -x "$(command -v dnf)" ]; then
dnf install -y cronie
fi
fi
if ! command -v "dig" &> /dev/null; then
if [ -x "$(command -v yum)" ]; then
yum install -y bind-utils
elif [ -x "$(command -v dnf)" ]; then
dnf install -y bind-utils
fi
fi
fi
update
touch acyg_update
fi
v4v6
if [[ -z $v4 ]]; then
yellow "It is detected that the VPS is pure IPV6 Only, add dns64"
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
sleep 2
fi
}
acme2(){
if [[ -n $(lsof -i :80|grep -v "PID") ]]; then
yellow "It is detected that port 80 is occupied, and now all port 80 is released."
sleep 2
lsof -i :80|grep -v "PID"|awk '{print "kill -9",$2}'|sh >/dev/null 2>&1
green "All ports 80 have been released!"
sleep 2
fi
}
acme3(){
readp "Please enter the email address required for registration (press enter to skip and a virtual gmail email will be automatically generated):" Aemail
if [ -z $Aemail ]; then
auto=`date +%s%N |md5sum | cut -c 1-6`
Aemail=$auto@gmail.com
fi
yellow "Currently registered email name: $Aemail"
green "Start installing the acme.sh certificate application script"
bash ~/.acme.sh/acme.sh --uninstall >/dev/null 2>&1
rm -rf ~/.acme.sh acme.sh
uncronac
wget -N https://github.com/Neilpang/acme.sh/archive/master.tar.gz >/dev/null 2>&1
tar -zxvf master.tar.gz >/dev/null 2>&1
cd acme.sh-master >/dev/null 2>&1
./acme.sh --install >/dev/null 2>&1
cd
curl https://get.acme.sh | sh -s email=$Aemail
if [[ -n $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
green "Installation of acme.sh certificate application program successful"
bash ~/.acme.sh/acme.sh --upgrade --use-wget --auto-upgrade
else
red "Installation of acme.sh certificate application program failed" && exit
fi
}
checktls(){
if [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key ]] && [[ -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]]; then
cronac
green "The domain name certificate application was successful or already exists! The domain name certificate (cert.crt) and key (private.key) have been saved to the /root/ygkkkca folder" 
yellow "The crt path of the public key file is as follows and can be copied directly"
green "/root/ygkkkca/cert.crt"
yellow "The key file key path is as follows and can be copied directly"
green "/root/ygkkkca/private.key"
echo $ym > /root/ygkkkca/ca.log
if [[ -f '/etc/hysteria/config.json' ]]; then
blue "The Hysteria-1 proxy protocol is detected. If you have installed Yongge's Hysteria script, please execute the application/change certificate in the Hysteria script. This certificate will be automatically applied."
fi
if [[ -f '/etc/caddy/Caddyfile' ]]; then
blue "The Naiveproxy proxy protocol is detected. If you have installed Yongge's Naiveproxy script, please execute the application/change certificate in the Naiveproxy script. This certificate will be automatically applied."
fi
if [[ -f '/etc/tuic/tuic.json' ]]; then
blue "The Tuic proxy protocol is detected. If you have installed Yongge's Tuic script, please execute the application/change certificate in the Tuic script. This certificate will be automatically applied."
fi
if [[ -f '/usr/bin/x-ui' ]]; then
blue "x-ui (xray proxy protocol) is detected. If you install Yongge’s x-ui script and enable the tls option, this certificate will be automatically applied."
fi
if [[ -f '/etc/s-box/sb.json' ]]; then
blue "The Sing-box kernel agent is detected. If you have installed Yongge's Sing-box script, please execute the application/change certificate in the Sing-box script. This certificate will be automatically applied."
fi
else
bash ~/.acme.sh/acme.sh --uninstall >/dev/null 2>&1
rm -rf /root/ygkkkca
rm -rf ~/.acme.sh acme.sh
uncronac
red "Unfortunately, the domain name certificate application failed. The suggestions are as follows:"
yellow "1. Change the custom name of the second-level domain name and try to execute the script (important)"
green "Example: the original second-level domain name x.ygkkk.eu.org or x.ygkkk.cf, rename the x name in cloudflare"
echo
yellow "2: Because there is a time limit for applying for certificates for the same local IP multiple times in a row, wait for a while and try again." && exit
fi
}
installCA(){
bash ~/.acme.sh/acme.sh --install-cert -d ${ym} --key-file /root/ygkkkca/private.key --fullchain-file /root/ygkkkca/cert.crt --ecc
}
checkip(){
v4v6
if [[ -z $v4 ]]; then
vpsip=$v6
elif [[ -n $v4 && -n $v6 ]]; then
vpsip="$v6 or $v4"
else
vpsip=$v4
fi
domainIP=$(dig @8.8.8.8 +time=2 +short "$ym" 2>/dev/null)
if echo $domainIP | grep -q "network unreachable\|timed out" || [[ -z $domainIP ]]; then
domainIP=$(dig @2001:4860:4860::8888 +time=2 aaaa +short "$ym" 2>/dev/null)
fi
if echo $domainIP | grep -q "network unreachable\|timed out" || [[ -z $domainIP ]] ; then
red "The IP was not resolved. Please check whether the domain name is entered incorrectly." 
yellow "Have you tried manually typing to force a match?"
yellow "1: Yes! Enter the IP for domain name resolution"
yellow "2: No! Exit script"
readp "please choose:" menu
if [ "$menu" = "1" ] ; then
green "VPS local IP: $vpsip"
readp "Please enter the IP for domain name resolution, consistent with the VPS local IP ($vpsip):" domainIP
else
exit
fi
elif [[ -n $(echo $domainIP | grep ":") ]]; then
green "The IPV6 address resolved to the current domain name: $domainIP"
else
green "The IPV4 address resolved to the current domain name: $domainIP"
fi
if [[ $domainIP != $v4 ]] && [[ $domainIP != $v6 ]]; then
yellow "Current VPS local IP: $vpsip"
red "The IP resolved by the current domain name does not match the local IP of the current VPS! ! !"
green "suggestions below:"
if [[ "$v6" == "2a09"* || "$v4" == "104.28"* ]]; then
yellow "WARP failed to shut down automatically, please shut it down manually! Or use the Yongge WARP script that supports automatic closing and opening."
else
yellow "1. Please ensure that CDN Xiaohuangyun is turned off (DNS only). The settings for other domain name resolution websites are the same."
yellow "2. Please check whether the IP set by the domain name resolution website is correct."
fi
exit 
else
green "The IP matching is correct, and the application for the certificate begins..."
fi
}
checkacmeca(){
nowca=`bash ~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}'`
if [[ $nowca == $ym ]]; then
red "After testing, the entered domain name already has a certificate application record, so there is no need to apply again."
red "Certificate application records are as follows:"
bash ~/.acme.sh/acme.sh --list
yellow "If you must reapply, please execute the delete certificate option first" && exit
fi
}
ACMEstandaloneDNS(){
readp "Please enter the resolved domain name:" ym
green "Domain name entered: $ym" && sleep 1
checkacmeca
checkip
if [[ $domainIP = $v4 ]]; then
bash ~/.acme.sh/acme.sh  --issue -d ${ym} --standalone -k ec-256 --server letsencrypt --insecure
fi
if [[ $domainIP = $v6 ]]; then
bash ~/.acme.sh/acme.sh  --issue -d ${ym} --standalone -k ec-256 --server letsencrypt --listen-v6 --insecure
fi
installCA
checktls
}
ACMEDNS(){
readp "Please enter the resolved domain name:" ym
green "Domain name entered: $ym" && sleep 1
checkacmeca
freenom=`echo $ym | awk -F '.' '{print $NF}'`
if [[ $freenom =~ tk|ga|gq|ml|cf ]]; then
red "After detection, you are using freenom free domain name resolution, which does not support the current DNS API mode. The script exits." && exit 
fi
if [[ -n $(echo $ym | grep \*) ]]; then
green "After testing, it is currently a pan-domain name certificate application." && sleep 2
else
green "After testing, it is currently a single domain name certificate application." && sleep 2
fi
checkacmeca
checkip
echo
ab="Please select a managed domain name resolution service provider:\n1.Cloudflare\n2.Tencent Cloud DNSPod\n3.Alibaba Cloud Aliyun\n Please select:"
readp "$ab" cd
case "$cd" in 
1 )
readp "Please copy Cloudflare’s Global API Key:" GAK
export CF_Key="$GAK"
readp "Please enter the registered email address to log in to Cloudflare:" CFemail
export CF_Email="$CFemail"
if [[ $domainIP = $v4 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${ym} -k ec-256 --server letsencrypt --insecure
fi
if [[ $domainIP = $v6 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${ym} -k ec-256 --server letsencrypt --listen-v6 --insecure
fi
;;
2 )
readp "Please copy the DP_Id of Tencent Cloud DNSPod:" DPID
export DP_Id="$DPID"
readp "Please copy the DP_Key of Tencent Cloud DNSPod:" DPKEY
export DP_Key="$DPKEY"
if [[ $domainIP = $v4 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_dp -d ${ym} -k ec-256 --server letsencrypt --insecure
fi
if [[ $domainIP = $v6 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_dp -d ${ym} -k ec-256 --server letsencrypt --listen-v6 --insecure
fi
;;
3 )
readp "Please copy the Ali_Key of Alibaba Cloud Aliyun:" ALKEY
export Ali_Key="$ALKEY"
readp "Please copy Ali_Secret of Alibaba Cloud Aliyun:" ALSER
export Ali_Secret="$ALSER"
if [[ $domainIP = $v4 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_ali -d ${ym} -k ec-256 --server letsencrypt --insecure
fi
if [[ $domainIP = $v6 ]]; then
bash ~/.acme.sh/acme.sh --issue --dns dns_ali -d ${ym} -k ec-256 --server letsencrypt --listen-v6 --insecure
fi
esac
installCA
checktls
}
ACMEDNScheck(){
wgcfv6=$(curl -s6m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
ACMEDNS
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
ACMEDNS
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
}
ACMEstandaloneDNScheck(){
wgcfv6=$(curl -s6m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
ACMEstandaloneDNS
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
ACMEstandaloneDNS
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
}
acme(){
mkdir -p /root/ygkkkca
ab="1. Select the independent 80 port mode to apply for a certificate (domain name only, recommended by beginners), port 80 will be forcibly released during the installation process\n2. Select the DNS API mode to apply for a certificate (domain name, ID, Key required), automatically identify single domain name and Generic domain name\n0. Return to the previous level\n Please select:"
readp "$ab" cd
case "$cd" in 
1 ) acme1 && acme2 && acme3 && ACMEstandaloneDNScheck;;
2 ) acme1 && acme3 && ACMEDNScheck;;
0 ) start_menu;;
esac
}
Certificate(){
[[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "The acme.sh certificate application is not installed and cannot be executed." && exit 
green "The domain name displayed under Main_Domainc is the domain name certificate that has been successfully applied for. The automatic renewal time point of the corresponding domain name certificate is displayed under Renew."
bash ~/.acme.sh/acme.sh --list
#readp "Please enter the domain name certificate to be revoked and deleted (copy the domain name displayed under Main_Domain, please press Ctrl+c to exit):" ym
#if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $ym) ]]; then
#bash ~/.acme.sh/acme.sh --revoke -d ${ym} --ecc
#bash ~/.acme.sh/acme.sh --remove -d ${ym} --ecc
#rm -rf /root/ygkkkca
#green "The domain name certificate of ${ym} was revoked and deleted successfully."
#else
#red "The ${ym} domain name certificate you entered was not found, please verify by yourself!" && exit
#fi
}
acmeshow(){
if [[ -n $(~/.acme.sh/acme.sh -v 2>/dev/null) ]]; then
caacme1=`bash ~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}'`
if [[ -n $caacme1 && ! $caacme1 == "Main_Domain" ]] && [[ -f /root/ygkkkca/cert.crt && -f /root/ygkkkca/private.key && -s /root/ygkkkca/cert.crt && -s /root/ygkkkca/private.key ]]; then
caacme=$caacme1
else
caacme='无证书申请记录'
fi
else
caacme='未安装acme'
fi
}
cronac(){
uncronac
crontab -l > /tmp/crontab.tmp
echo "0 0 * * * root bash ~/.acme.sh/acme.sh --cron -f >/dev/null 2>&1" >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
uncronac(){
crontab -l > /tmp/crontab.tmp
sed -i '/--cron/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
acmerenew(){
[[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "The acme.sh certificate application is not installed and cannot be executed." && exit 
green "The domain names shown below are the domain name certificates that have been successfully applied for."
bash ~/.acme.sh/acme.sh --list | tail -1 | awk '{print $1}'
echo
#ab="1. Renew all certificates with one click (recommended)\n2. Select the specified domain name certificate to renew\n0. Return to the previous level\n Please select:"
#readp "$ab" cd
#case "$cd" in 
#1 ) 
green "Start renewing certificate..." && sleep 3
bash ~/.acme.sh/acme.sh --cron -f
checktls
#;;
#2 ) 
#readp "Please enter the domain name certificate to be renewed (copy the domain name displayed under Main_Domain):" ym
#if [[ -n $(bash ~/.acme.sh/acme.sh --list | grep $ym) ]]; then
#bash ~/.acme.sh/acme.sh --renew -d ${ym} --force --ecc
#checktls
#else
#red "The ${ym} domain name certificate you entered was not found, please verify by yourself!" && exit
#fi
#;;
#0 ) start_menu;;
#esac
}
uninstall(){
[[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && yellow "The acme.sh certificate application is not installed and cannot be executed." && exit 
curl https://get.acme.sh | sh
bash ~/.acme.sh/acme.sh --uninstall
rm -rf /root/ygkkkca
rm -rf ~/.acme.sh acme.sh
uncronac
[[ -z $(~/.acme.sh/acme.sh -v 2>/dev/null) ]] && green "acme.sh uninstallation completed" || red "acme.sh uninstallation failed"
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
white "Yongge blogger’s blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
yellow "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
green "Acme-yg script version number V2023.12.18"
yellow "hint:"
yellow "1. The script does not support multi-IP VPS. The IP for SSH login must be consistent with the VPS shared network IP."
yellow "2. Port 80 mode only supports single domain name certificate application, and supports automatic renewal when port 80 is not occupied."
yellow "3. The DNS API mode does not support freenom free domain name application. It supports single domain name and pan-domain name certificate applications, and unconditional automatic renewal."
yellow "4. Before applying for a pan-domain name, you need to set a resolution record with a name of * characters on the resolution platform (input format: *. primary/secondary primary domain)"
yellow "Public key file crt storage path: /root/ygkkkca/cert.crt"
yellow "Key file key storage path: /root/ygkkkca/private.key"
echo
red "========================================================================="
acmeshow
blue "Certificates that have been successfully applied for (in domain name form):"
yellow "$caacme"
echo
red "========================================================================="
green " 1. acme.sh applies for letsencrypt ECC certificate (supports port 80 mode and DNS API mode)"
green " 2. Query the successfully applied domain name and automatic renewal time point"
green " 3. Manual one-click certificate renewal"
green " 4. Delete the certificate and uninstall the one-click ACME certificate application script"
green " 0. Exit"
echo
readp "Please enter the number:" NumberInput
case "$NumberInput" in     
1 ) acme;;
2 ) Certificate;;
3 ) acmerenew;;
4 ) uninstall;;
* ) exit      
esac
