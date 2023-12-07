#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export LANG=en_US.UTF-8
endpoint=
red='\033[0;31m'
bblue='\033[0;34m'
yellow='\033[0;33m'
green='\033[0;32m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}
rred(){ echo -e "\033[35m\033[01m$1\033[0m";}
readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}
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
red "Your current system is not supported, please choose to use Ubuntu, Debian, Centos system." && exit
fi
vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
version=$(uname -r | cut -d "-" -f1)
main=$(uname -r | cut -d "." -f1)
minor=$(uname -r | cut -d "." -f2)
vi=$(systemd-detect-virt)
case "$release" in
"Centos") yumapt='yum -y';;
"Ubuntu"|"Debian") yumapt="apt-get -y";;
esac
cpujg(){
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) red "Currently the script does not support the $(uname -m) schema" && exit;;
esac
}
cfwarpshow(){
insV=$(cat /root/warpip/v 2>/dev/null)
latestV=$(curl -s https://gitlab.com/rwkgyg/CFwarp/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1)
if [[ -f /root/warpip/v ]]; then
if [ "$insV" = "$latestV" ]; then
echo -e " The current CFwarp-yg script version number: ${bblue}${insV}${plain} is the latest version"
else
echo -e " Current CFwarp-yg script version number: ${bblue}${insV}${plain}"
echo -e " The latest CFwarp-yg script version number detected: ${yellow}${latestV}${plain} (8 can be selected for update)"
echo -e "${yellow}$(curl -s https://gitlab.com/rwkgyg/CFwarp/-/raw/main/version/version)${plain}"
fi
else
echo -e " Current CFwarp-yg script version number: ${bblue}${latestV}${plain}"
echo -e " Please select the plan (1, 2, 3) first and install the desired warp mode"
fi
}
tun(){
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
}
nf4(){
result=`curl --connect-timeout 5 -4sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="Give up, Netflix does not serve the current IP area" && return
[[ "$result" == "curl"* ]] && NF="Error, unable to connect to Netflix official website" && return
result=`curl -4sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="Sorry, the current IP cannot watch Netflix" && return
result1=`curl -4sL "https://www.netflix.com/title/70143836" 2>&1`
[[ "$result1" == *"page-404"* ]] && NF="Unfortunately, the current IP only unlocks Netflix’s homemade dramas" || NF="Congratulations, the current IP has fully unlocked Netflix’s non-self-produced dramas"
}
nf6(){
result=`curl --connect-timeout 5 -6sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="Give up, Netflix does not serve the current IP area" && return
[[ "$result" == "curl"* ]] && NF="Error, unable to connect to Netflix official website" && return
result=`curl -6sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="Sorry, the current IP cannot watch Netflix" && return
result1=`curl -6sL "https://www.netflix.com/title/70143836" 2>&1`
[[ "$result1" == *"page-404"* ]] && NF="Unfortunately, the current IP only unlocks Netflix’s homemade dramas" || NF="Congratulations, the current IP has fully unlocked Netflix’s non-self-produced dramas"
}
nfs5() {
result=`curl -sx socks5h://localhost:$mport --connect-timeout 5 -4sSL "https://www.netflix.com/" 2>&1`
[ "$result" == "Not Available" ] && NF="Give up, Netflix does not serve the current IP area" && return
[[ "$result" == "curl"* ]] && NF="Error, unable to connect to Netflix official website" && return
result=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/80018499" 2>&1`
[[ "$result" == *"page-404"* || "$result" == *"NSEZ-403"* ]] && NF="Sorry, the current IP cannot watch Netflix" && return
result1=`curl -sx socks5h://localhost:$mport -4sL "https://www.netflix.com/title/70143836" 2>&1`
[[ "$result1" == *"page-404"* ]] && NF="Unfortunately, the current IP only unlocks Netflix’s homemade dramas" || NF="Congratulations, the current IP has fully unlocked Netflix’s non-self-produced dramas"
}
v4v6(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
}
checkwgcf(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
}
warpip(){
mkdir -p /root/warpip
if [[ ! -f '/root/warpip/result.csv' ]]; then
cpujg
v4v6
if [[ -z $v4 ]]; then
wget -qO /root/warpip/ip.txt https://gitlab.com/rwkgyg/CFwarp/raw/main/point/ip6.txt
else
wget -qO /root/warpip/ip.txt https://gitlab.com/rwkgyg/CFwarp/raw/main/point/ip.txt
fi
wget -qO /root/warpip/$cpu https://gitlab.com/rwkgyg/CFwarp/raw/main/point/cpu/$cpu && chmod +x /root/warpip/$cpu
cd /root/warpip
./$cpu >/dev/null 2>&1 &
wait
cd
a=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $2}'`
if [[ $a = 100.00% ]]; then
rm -rf /root/warpip/*
if [[ -z $v4 ]]; then
n=0
	iplist=100
	while true
	do
		temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
	done
	while true
	do
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2)))])
			n=$[$n+1]
		fi
	done
else
	n=0
	iplist=100
	while true
	do
		temp[$n]=$(echo 162.159.192.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 162.159.193.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 162.159.195.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 188.114.96.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 188.114.97.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 188.114.98.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
		temp[$n]=$(echo 188.114.99.$(($RANDOM%256)))
		n=$[$n+1]
		if [ $n -ge $iplist ]
		then
			break
		fi
	done
	while true
	do
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.192.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.193.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 162.159.195.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 188.114.96.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 188.114.97.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 188.114.98.$(($RANDOM%256)))
			n=$[$n+1]
		fi
		if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
		then
			break
		else
			temp[$n]=$(echo 188.114.99.$(($RANDOM%256)))
			n=$[$n+1]
		fi
	done
fi
echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u>/root/warpip/ip.txt
wget -qO /root/warpip/$cpu https://gitlab.com/rwkgyg/CFwarp/raw/main/point/$cpu && chmod +x /root/warpip/$cpu
cd /root/warpip
./$cpu >/dev/null 2>&1 &
wait
cd
a=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $2}'`
if [[ $a = 100.00% ]]; then
rm -rf /root/warpip/*
if [[ -z $v4 ]]; then
endpoint=[2606:4700:d0::a29f:c001]:2408
else
endpoint=162.159.193.10:1701
fi
else
endpoint=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $1}'`
fi
else
endpoint=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $1}'`
fi
else
a=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $2}'`
if [[ $a = 100.00% ]]; then
if [[ -z $v4 ]]; then
endpoint=[2606:4700:d0::a29f:c001]:2408
else
endpoint=162.159.193.10:1701
fi
else
endpoint=`cat /root/warpip/result.csv | awk -F, '$3!="timeout ms" {print} ' | sed -n '2p' | awk -F ',' '{print $1}'`
fi
fi
}
dig9(){
if [[ -n $(grep 'DiG 9' /etc/hosts) ]]; then
echo -e "search blue.kundencontroller.de\noptions rotate\nnameserver 2a02:180:6:5::1c\nnameserver 2a02:180:6:5::4\nnameserver 2a02:180:6:5::1e\nnameserver 2a02:180:6:5::1d" > /etc/resolv.conf
fi
}
mtuwarp(){
v4v6
yellow "Start automatically setting the best network throughput value of warp's MTU to optimize the WARP network!"
MTUy=1500
MTUc=10
if [[ -n $v6 && -z $v4 ]]; then
ping='ping6'
IP1='2606:4700:4700::1111'
IP2='2001:4860:4860::8888'
else
ping='ping'
IP1='1.1.1.1'
IP2='8.8.8.8'
fi
while true; do
if ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP1} >/dev/null 2>&1 || ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP2} >/dev/null 2>&1; then
MTUc=1
MTUy=$((${MTUy} + ${MTUc}))
else
MTUy=$((${MTUy} - ${MTUc}))
[[ ${MTUc} = 1 ]] && break
fi
[[ ${MTUy} -le 1360 ]] && MTUy='1360' && break
done
MTU=$((${MTUy} - 80))
green "MTU optimal network throughput value = $MTU has been set"
}
WGproxy(){
bash <(curl -Ls https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/acwarp.sh)
}
xyz(){
if [[ -n $(screen -ls | grep '(Attached)' | awk '{print $1}' | awk -F "." '{print $1}') ]]; then
until [[ -z $(screen -ls | grep '(Attached)' | awk '{print $1}' | awk -F "." '{print $1}' | awk 'NR==1{print}') ]] 
do
Attached=`screen -ls | grep '(Attached)' | awk '{print $1}' | awk -F "." '{print $1}' | awk 'NR==1{print}'`
screen -d $Attached
done
fi
screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null
rm -rf /root/WARP-UP.sh
cat>/root/WARP-UP.sh<<-\EOF
#!/bin/bash
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
sleep 2
checkwgcf(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
}
warpclose(){
wg-quick down wgcf >/dev/null 2>&1;systemctl stop wg-quick@wgcf >/dev/null 2>&1;systemctl disable wg-quick@wgcf >/dev/null 2>&1;kill -15 $(pgrep warp-go) >/dev/null 2>&1;systemctl stop warp-go >/dev/null 2>&1;systemctl disable warp-go >/dev/null 2>&1
}
warpopen(){
wg-quick down wgcf >/dev/null 2>&1;systemctl enable wg-quick@wgcf >/dev/null 2>&1;systemctl start wg-quick@wgcf >/dev/null 2>&1;systemctl restart wg-quick@wgcf >/dev/null 2>&1;kill -15 $(pgrep warp-go) >/dev/null 2>&1;systemctl stop warp-go >/dev/null 2>&1;systemctl enable warp-go >/dev/null 2>&1;systemctl start warp-go >/dev/null 2>&1;systemctl restart warp-go >/dev/null 2>&1
}
warpre(){
i=0
while [ $i -le 4 ]; do let i++
warpopen
checkwgcf
if [[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]; then
green "The warp after the interruption tried to obtain the IP successfully!" 
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] The warp after the interruption tried to obtain the IP successfully!" >> /root/warpip/warp_log.txt
break
else 
red "The warp attempt to obtain the IP after the interruption failed!"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] The warp after the interruption failed to obtain the IP!" >> /root/warpip/warp_log.txt
fi
done
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
warpclose
red "Since five attempts to obtain the IP of the warp failed, the execution is now stopped and the warp is closed, and the VPS returns to its original IP state."
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Due to 5 failed attempts to obtain the IP of the warp, the execution is now stopped and the warp is closed, and the VPS returns to its original IP status." >> /root/warpip/warp_log.txt
fi
}
while true; do
green "Check whether the warp is starting..."
wp=$(cat /root/warpip/wp.log)
if [[ $wp = w4 ]]; then
checkwgcf
if [[ $wgcfv4 =~ on|plus ]]; then
green "Congratulations! WARP IPV4 status is running! The next round of detection will be automatically executed in 600 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Congratulations! WARP IPV4 status is running! The next round of detection will be automatically executed in 600 seconds" >> /root/warpip/warp_log.txt
sleep 600s
else
warpre ; green "The next round of detection will be automatically executed in 500 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] The next round of detection will be automatically executed in 500 seconds" >> /root/warpip/warp_log.txt
sleep 500s
fi
elif [[ $wp = w6 ]]; then
checkwgcf
if [[ $wgcfv6 =~ on|plus ]]; then
green "Congratulations! WARP IPV6 status is running! The next round of detection will be automatically executed in 600 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Congratulations! WARP IPV6 status is running! The next round of detection will be automatically executed in 600 seconds" >> /root/warpip/warp_log.txt
sleep 600s
else
warpre ; green "The next round of detection will be automatically executed in 500 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] The next round of detection will be automatically executed in 500 seconds" >> /root/warpip/warp_log.txt
sleep 500s
fi
else
checkwgcf
if [[ $wgcfv4 =~ on|plus && $wgcfv6 =~ on|plus ]]; then
green "Congratulations! WARP IPV4+IPV6 status is running! The next round of detection will be automatically executed in 600 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Congratulations! WARP IPV4+IPV6 status is running! The next round of detection will be automatically executed in 600 seconds" >> /root/warpip/warp_log.txt
sleep 600s
else
warpre ; green "The next round of detection will be automatically executed in 500 seconds"
echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] The next round of detection will be automatically executed in 500 seconds" >> /root/warpip/warp_log.txt
sleep 500s
fi
fi
done
EOF
[[ -e /root/WARP-UP.sh ]] && screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
}
first4(){
[[ -e /etc/gai.conf ]] && grep -qE '^ *precedence ::ffff:0:0/96  100' /etc/gai.conf || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf 2>/dev/null
}
docker(){
if [[ -n $(ip a | grep docker) ]]; then
red "It is detected that docker has been installed on the VPS. Please ensure that docker is in host running mode, otherwise docker will fail." && sleep 3s
echo
yellow "After 6 seconds, continue to install WARP for plan 1. To exit the installation, please press Ctrl+c." && sleep 6s
fi
}
lncf(){
curl -sSL -o /usr/bin/cf -L https://gitlab.com/rwkgyg/CFwarp/-/raw/main/CFwarp.sh
chmod +x /usr/bin/cf
}
UPwpyg(){
if [[ ! -f '/usr/bin/cf' ]]; then
red "The CFwarp script was not installed properly!" && exit
fi
lncf
curl -s https://gitlab.com/rwkgyg/CFwarp/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1 > /root/warpip/v
green "CFwarp script upgraded successfully" && cf
}
restwarpgo(){
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
}
cso(){
warp-cli --accept-tos disconnect >/dev/null 2>&1
warp-cli --accept-tos disable-always-on >/dev/null 2>&1
warp-cli --accept-tos delete >/dev/null 2>&1
if [[ $release = Centos ]]; then
yum autoremove cloudflare-warp -y
else
apt purge cloudflare-warp -y
rm -f /etc/apt/sources.list.d/cloudflare-client.list /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
fi
$yumapt autoremove
}
WARPun(){
readp "1. Uninstall only solution one WARP\n2. Uninstall only solution two Socks5-WARP\n3. Thoroughly clean and uninstall all WARP-related solutions (1+2)\n Please choose:" cd
case "$cd" in
1 ) cwg && green "warp uninstall completed";;
2 ) cso && green "socks5-warp uninstall completed";;
3 ) cwg && cso && unreswarp && green "Both warp and socks5-warp have been completely uninstalled." && rm -rf /usr/bin/cf warp_update
esac
}
WARPtools(){
green "1. Check the WARP online monitoring situation in real time (please note before entering: exit and continue to execute the monitoring command: ctrl+a+d, exit and close the monitoring command: ctrl+c)"
green "2. Restart the WARP online monitoring function"
green "3. Reset and customize the WARP online monitoring time interval"
green "4. Check the WARP online monitoring log for the day"
echo "-----------------------------------------------"
green "5. Change Socks5+WARP port"
echo "-----------------------------------------------"
green "6. Use your own warp key to slowly flash warp + traffic"
green "7. Generate warp+ keys for more than 20 million GB traffic with one click"
echo "-----------------------------------------------"
green "0. Exit"
readp "please choose:" warptools
if [[ $warptools == 1 ]]; then
[[ -z $(type -P warp-go) && -z $(type -P wg-quick) ]] && red "Solution 1 is not installed and the script exits." && exit
name=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
if [[ $name =~ "up" ]]; then
screen -Ur up
else
red "The WARP monitoring function is not started, please select 2 to restart." && WARPtools
fi
elif [[ $warptools == 2 ]]; then
[[ -z $(type -P warp-go) && -z $(type -P wg-quick) ]] && red "Solution 1 is not installed and the script exits." && exit
xyz
name=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
[[ $name =~ "up" ]] && green "WARP online monitoring started successfully" || red "WARP online monitoring fails to start. Check whether screen is installed successfully."
elif [[ $warptools == 3 ]]; then
[[ -z $(type -P warp-go) && -z $(type -P wg-quick) ]] && red "Solution 1 is not installed and the script exits." && exit
xyz
readp "When the warp state is running, the interval between rechecking the warp state (default is 600 seconds when you press Enter), please enter the interval (for example: 50 seconds, enter 50):" stop
[[ -n $stop ]] && sed -i "s/600s/${stop}s/g;s/600s/${stop}s/g" /root/WARP-UP.sh || green "Default interval is 600 seconds"
readp "When the warp status is interrupted (the warp automatically closes after 5 consecutive failures and the original VPS IP is restored), continue to detect the WARP status interval (the default is 500 seconds by pressing Enter). Please enter the interval time (for example: 50 seconds, enter 50):" goon
[[ -n $goon ]] && sed -i "s/500s/${goon}s/g;s/500s/${goon}s/g" /root/WARP-UP.sh || green "Default interval is 500 seconds"
[[ -e /root/WARP-UP.sh ]] && screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null ; screen -UdmS up bash -c '/bin/bash /root/WARP-UP.sh'
green "After the setting is completed, you can view the monitoring time interval in option 1."
elif [[ $warptools == 4 ]]; then
[[ -z $(type -P warp-go) && -z $(type -P wg-quick) ]] && red "Solution 1 is not installed and the script exits." && exit
cat /root/warpip/warp_log.txt
# find /root/warpip/warp_log.txt -mtime -1 -exec cat {} \;
elif [[ $warptools == 6 ]]; then
green "You can also brush it online on the web: https://replit.com/@ygkkkk/Warp" && sleep 2
wget -N https://gitlab.com/rwkgyg/CFwarp/raw/main/wp-plus.py 
sed -i "27 s/[(][^)]*[)]//g" wp-plus.py
readp "Client configuration ID (36 characters):" ID
sed -i "27 s/input/'$ID'/" wp-plus.py
python3 wp-plus.py
elif [[ $warptools == 5 ]]; then
SOCKS5WARPPORT
elif [[ $warptools == 7 ]]; then
wppluskey && rm -rf warpplus.sh
green "The accumulated warp+ keys generated by the current script have been placed in the /root/WARP+Keys.txt file."
green "The new key for each re-execution will be placed at the end of the file (including scheme one and scheme two)"
blue "$(cat /root/WARP+Keys.txt)"
echo
else
cf
fi
}
chatgpt4(){
gpt1=$(curl -s4 https://chat.openai.com 2>&1)
gpt2=$(curl -s4 https://android.chat.openai.com 2>&1)
}
chatgpt6(){
gpt1=$(curl -s6 https://chat.openai.com 2>&1)
gpt2=$(curl -s6 https://android.chat.openai.com 2>&1)
}
checkgpt(){
if [[ $gpt1 == *location* ]]; then
if [[ $gpt2 == *VPN* ]]; then
chat='遗憾，当前IP仅解锁ChatGPT网页，未解锁客户端'
elif [[ $gpt2 == *Request* ]]; then
chat='恭喜，当前IP完整解锁ChatGPT (网页+客户端)'
else
chat='杯具，当前IP无法解锁ChatGPT服务'
fi
else
chat='杯具，当前IP无法解锁ChatGPT服务'
fi
}
ShowSOCKS5(){
if [[ $(systemctl is-active warp-svc) = active ]]; then
mport=`warp-cli --accept-tos settings 2>/dev/null | grep 'WarpProxy on port' | awk -F "port " '{print $2}'`
s5ip=`curl -sx socks5h://localhost:$mport icanhazip.com -k`
nfs5
gpt1=$(curl -sx socks5h://localhost:$mport https://chat.openai.com 2>&1)
gpt2=$(curl -sx socks5h://localhost:$mport https://android.chat.openai.com 2>&1)
checkgpt
#NF=$(./nf -proxy socks5h://localhost:$mport | awk '{print $1}' | sed -n '3p')
nonf=$(curl -sx socks5h://localhost:$mport --user-agent "${UA_Browser}" http://ip-api.com/json/$s5ip?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -sx socks5h://localhost:$mport ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
socks5=$(curl -sx socks5h://localhost:$mport www.cloudflare.com/cdn-cgi/trace -k --connect-timeout 2 | grep warp | cut -d= -f2) 
case ${socks5} in 
plus) 
S5Status=$(white "Socks5 WARP+ status: \c" ; rred "Running, WARP+ account (remaining WARP+ traffic: $((`warp-cli --accept-tos account | grep Quota | awk '{ print $(NF) }'`/1000000000)) GB)" ; white " Socks5 port: \c" ; rred "$mport" ; white " Service provider Cloudflare obtains the IPV4 address: \c" ; rred "$s5ip  $country" ; white " Netflix NF unlocking status:\c" ; rred "$NF" ; white " ChatGPT unlocking status: \c" ; rred "$chat");;  
on) 
S5Status=$(white "Socks5 WARP status: \c" ; green "Running, WARP ordinary account (unlimited WARP traffic)" ; white " Socks5 port: \c" ; green "$mport" ; white " Service provider Cloudflare obtains the IPV4 address:\c" ; green "$s5ip  $country" ; white " Netflix NF unlocking status:\c" ; green "$NF" ; white " ChatGPT unlocking status: \c" ; green "$chat");;  
*) 
S5Status=$(white "Socks5 WARP status: \c" ; yellow "Socks5-WARP client installed but port is closed")
esac 
else
S5Status=$(white "Socks5 WARP status: \c" ; red "Socks5-WARP client not installed")
fi
}
SOCKS5ins(){
yellow "Detecting the Socks5-WARP installation environment..."
if [[ $release = Centos ]]; then
[[ ! ${vsid} =~ 8 ]] && yellow "Current system version number: Centos $vsid \nSocks5-WARP only supports Centos 8" && exit 
elif [[ $release = Ubuntu ]]; then
[[ ! ${vsid} =~ 20|22 ]] && yellow "Current system version number: Ubuntu $vsid \nSocks5-WARP only supports Ubuntu 20.04/22.04 system" && exit 
elif [[ $release = Debian ]]; then
[[ ! ${vsid} =~ 10|11|12 ]] && yellow "Current system version number: Debian $vsid \nSocks5-WARP only supports Debian 10/11/12 systems" && exit 
fi
[[ $(warp-cli --accept-tos status 2>/dev/null) =~ 'Connected' ]] && red "Socks5-WARP is currently running" && cf
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4v6
if [[ -n $v6 && -z $v4 ]]; then
systemctl start wg-quick@wgcf >/dev/null 2>&1
restwarpgo
red "Pure IPV6 VPS currently does not support the installation of Socks5-WARP" && sleep 2 && exit
else
systemctl start wg-quick@wgcf >/dev/null 2>&1
restwarpgo
#elif [[ -n $v4 && -z $v6 ]]; then
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#[[ $wgcfv4 =~ on|plus ]] && red "Pure IPV4 VPS has Wgcf-WARP-IPV4 installed and does not support the installation of Socks5-WARP" && cf
#elif [[ -n $v4 && -n $v6 ]]; then
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && red "The native dual-stack VPS has Wgcf-WARP-IPV4/IPV6 installed, please uninstall it first. Then install Socks5-WARP, and finally install Wgcf-WARP-IPV4/IPV6" && cf
fi
#systemctl start wg-quick@wgcf >/dev/null 2>&1
#checkwgcf
#if [[ $wgcfv4 =~ on|plus && $wgcfv6 =~ on|plus ]]; then
#red "Wgcf-WARP-IPV4+IPV6 has been installed, but Socks5-WARP is not supported." && cf
#fi
if [[ $release = Centos ]]; then 
yum -y install epel-release && yum -y install net-tools
curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo
yum update
#rpm -ivh https://pkg.cloudflareclient.com/cloudflare-release-el8.rpm
yum -y install cloudflare-warp
fi
if [[ $release = Debian ]]; then
[[ ! $(type -P gpg) ]] && apt update && apt install gnupg -y
[[ ! $(apt list 2>/dev/null | grep apt-transport-https | grep installed) ]] && apt update && apt install apt-transport-https -y
fi
if [[ $release != Centos ]]; then 
apt install net-tools -y
curl https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] http://pkg.cloudflareclient.com/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
apt update;apt install cloudflare-warp -y
fi
warpip
warp-cli --accept-tos register >/dev/null 2>&1 && sleep 2
warp-cli --accept-tos set-mode proxy >/dev/null 2>&1
warp-cli --accept-tos set-custom-endpoint "$endpoint" >/dev/null 2>&1
warp-cli --accept-tos connect >/dev/null 2>&1
warp-cli --accept-tos enable-always-on >/dev/null 2>&1
#wppluskey >/dev/null 2>&1
#ID=$(tail -n1 /root/WARP+Keys.txt | cut -d' ' -f1 2>/dev/null)
#if [[ -n $ID ]]; then
#green "Use warp+key"
#green "$(tail -n1 /root/WARP+Keys.txt | cut -d' ' -f1)"
#warp-cli --accept-tos set-license $ID >/dev/null 2>&1
#fi
#rm -rf warpplus.sh
#if [[ $(warp-cli --accept-tos account) =~ 'Limited' ]]; then
#green "Upgraded to Socks5-WARP+ account\nSocks5-WARP+ account remaining traffic: $((`warp-cli --accept-tos account | grep Quota | awk '{ print $(NF) }'`/1000000000)) GB"
#fi
green "The installation is complete, return to the menu"
sleep 2 && lncf && reswarp && cf
}
SOCKS5WARPUP(){
[[ ! $(type -P warp-cli) ]] && red "Socks5-WARP is not installed and cannot be upgraded to a Socks5-WARP+ account." && exit
[[ $(warp-cli --accept-tos account) =~ 'Limited' ]] && red "You are already a Socks5-WARP+ account and there is no need to upgrade." && exit
readp "Button license key (26 characters):" ID
[[ -n $ID ]] && warp-cli --accept-tos set-license $ID >/dev/null 2>&1 || (red "Key license key not entered (26 characters)" && exit)
yellow "If it prompts Error: Too many devices. It may be that the number of bound devices exceeds the limit of 5 or the key is entered incorrectly."
if [[ $(warp-cli --accept-tos account) =~ 'Limited' ]]; then
green "Upgraded to Socks5-WARP+ account\nSocks5-WARP+ account remaining traffic: $((`warp-cli --accept-tos account | grep Quota | awk '{ print $(NF) }'`/1000000000)) GB"
else
red "Failed to upgrade Socks5-WARP+ account" && exit
fi
sleep 2 && ShowSOCKS5 && S5menu
}
SOCKS5WARPPORT(){
[[ ! $(type -P warp-cli) ]] && red "Socks5-WARP(+) is not installed and the port cannot be changed" && exit
readp "Please enter the custom socks5 port [2000~65535] (press Enter to skip to a random port between 2000-65535):" port
if [[ -z $port ]]; then
port=$(shuf -i 2000-65535 -n 1)
until [[ -z $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom socks5 port:" port
done
else
until [[ -z $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]]
do
[[ -n $(ss -ntlp | awk '{print $4}' | sed 's/.*://g' | grep -w "$port") ]] && yellow "\nThe port is occupied, please re-enter the port." && readp "Custom socks5 port:" port
done
fi
[[ -n $port ]] && warp-cli --accept-tos set-proxy-port $port >/dev/null 2>&1
green "Current socks5 port: $port"
sleep 2 && ShowSOCKS5 && S5menu
}
WGCFmenu(){
name=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
[[ $name =~ "up" ]] && keepup="WARP monitoring is enabled" || keepup="WARP monitoring is closed"
white "------------------------------------------------------------------------------------"
white " Option 1: The current IPV4 takeover VPS outbound situation is as follows ($keepup)"
white " ${WARPIPv4Status}"
white "------------------------------------------------------------------------------------"
white " Option 1: The current IPV6 takeover VPS outbound situation is as follows ($keepup)"
white " ${WARPIPv6Status}"
white "------------------------------------------------------------------------------------"
if [[ "$WARPIPv4Status" == "No IPV4 address exists" &&"$WARPIPv6Status" == "No IPV6 address exists" ]]; then
yellow "Both IPV4 and IPV6 do not exist. The suggestions are as follows:"
red "1. If you originally installed wgcf, select 9 to switch to warp-go and reinstall warp."
red "2. If you originally installed warp-go, select 10 to switch to wgcf and reinstall warp."
red "Remember: If the problem persists, it is recommended to uninstall and restart the VPS, and then reinstall Solution 1"
fi
}
S5menu(){
white "------------------------------------------------------------------------------------------------"
white " Option 2: The current Socks5-WARP official client local agent situation is as follows"
blue " ${S5Status}"
white "------------------------------------------------------------------------------------------------"
}
reswarp(){
unreswarp
crontab -l > /tmp/crontab.tmp
echo "0 4 * * * systemctl stop warp-go;systemctl restart warp-go;systemctl restart wg-quick@wgcf;systemctl restart warp-svc" >> /tmp/crontab.tmp
echo "@reboot screen -UdmS up /bin/bash /root/WARP-UP.sh" >> /tmp/crontab.tmp
echo "0 0 * * * rm -f /root/warpip/warp_log.txt" >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
unreswarp(){
crontab -l > /tmp/crontab.tmp
sed -i '/systemctl stop warp-go;systemctl restart warp-go;systemctl restart wg-quick@wgcf;systemctl restart warp-svc/d' /tmp/crontab.tmp
sed -i '/@reboot screen/d' /tmp/crontab.tmp
sed -i '/warp_log.txt/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp
rm /tmp/crontab.tmp
}
wppluskey(){
if [[ $cpu = amd64 ]]; then
curl -sSL -o warpplus.sh --insecure https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/warpplus.sh >/dev/null 2>&1
elif [[ $cpu = arm64 ]]; then
curl -sSL -o warpplus.sh --insecure https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/warpplusa.sh >/dev/null 2>&1
fi
chmod +x warpplus.sh
timeout 60s ./warpplus.sh
}
ONEWARPGO(){
yellow "\n Please wait, it is currently in warp-go core installation mode, detecting the peer IP and outbound status..."
warpip
wgo1='sed -i "s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0#g" /usr/local/bin/warp.conf'
wgo2='sed -i "s#.*AllowedIPs.*#AllowedIPs = ::/0#g" /usr/local/bin/warp.conf'
wgo3='sed -i "s#.*AllowedIPs.*#AllowedIPs = 0.0.0.0/0,::/0#g" /usr/local/bin/warp.conf'
wgo4='sed -i "/Endpoint6/d" /usr/local/bin/warp.conf && sed -i "/Endpoint/s/.*/Endpoint = '"$endpoint"'/" /usr/local/bin/warp.conf'
wgo5='sed -i "/Endpoint6/d" /usr/local/bin/warp.conf && sed -i "/Endpoint/s/.*/Endpoint = '"$endpoint"'/" /usr/local/bin/warp.conf'
wgo6='sed -i "/\[Script\]/a PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf && sed -i "/\[Script\]/a PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf'
wgo7='sed -i "/\[Script\]/a PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf && sed -i "/\[Script\]/a PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf'
wgo8='sed -i "/\[Script\]/a PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf && sed -i "/\[Script\]/a PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf && sed -i "/\[Script\]/a PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf && sed -i "/\[Script\]/a PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP "src \K\S+") lookup main\n" /usr/local/bin/warp.conf'
STOPwgcf(){
if [[ -n $(type -P warp-cli) ]]; then
red "Socks5-WARP has been installed, and the currently selected WARP installation solution is not supported." 
systemctl restart warp-go && cf
fi
}
ShowWGCF(){
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4v6
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -sm4 "https://api.cloudflareclient.com/v0a884/reg/$(grep 'Device' /usr/local/bin/warp.conf 2>/dev/null | cut -d= -f2 | sed 's# ##g')" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'Token' /usr/local/bin/warp.conf 2>/dev/null | cut -d= -f2 | sed 's# ##g')")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
[[ -e /usr/local/bin/warpplus.log ]] && cfplus="WARP+ account (limited WARP+ traffic: $flow GB), device name: $(sed -n 1p /usr/local/bin/warpplus.log)" || cfplus="WARP+Teams account (unlimited WARP+ traffic)"
if [[ -n $v4 ]]; then
nf4
chatgpt4
checkgpt
wgcfv4=$(curl -s4 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp4a=`curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f13 -d ":" | cut -f2 -d '"'`
isp4b=`curl -sm3 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp4a ]] && isp4=$isp4a || isp4=$isp4b
nonf=$(curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -s4m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv4} in 
plus) 
WARPIPv4Status=$(white "WARP+ status: \c" ; rred "Running, $cfplus" ; white " Service provider Cloudflare obtains the IPV4 address:\c" ; rred "$v4  $country" ; white " Netflix NF unlocking status:\c" ; rred "$NF" ; white " ChatGPT unlocking status: \c" ; rred "$chat");;  
on) 
WARPIPv4Status=$(white "WARP status: \c" ; green "Running, WARP ordinary account (unlimited WARP traffic)" ; white " Service provider Cloudflare obtains the IPV4 address:\c" ; green "$v4  $country" ; white " Netflix NF unlocking status:\c" ; green "$NF" ; white " ChatGPT unlocking status: \c" ; green "$chat");;
off) 
WARPIPv4Status=$(white "WARP status: \c" ; yellow "Closed" ; white " Service provider $isp4 Get IPV4 address:\c" ; yellow "$v4  $country" ; white " Netflix NF unlocking status:\c" ; yellow "$NF" ; white " ChatGPT unlocking status: \c" ; yellow "$chat");; 
esac 
else
WARPIPv4Status=$(white "IPV4 status: \c" ; red "No IPV4 address exists")
fi 
if [[ -n $v6 ]]; then
nf6
chatgpt6
checkgpt
wgcfv6=$(curl -s6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp6a=`curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f13 -d":" | cut -f2 -d '"'`
isp6b=`curl -sm3 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v6 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp6a ]] && isp6=$isp6a || isp6=$isp6b
nonf=$(curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '8p')
#snnf=$(curl -s6m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv6} in 
plus) 
WARPIPv6Status=$(white "WARP+ status:\c" ; rred "Running, $cfplus" ; white " Service provider Cloudflare obtains the IPV6 address:\c" ; rred "$v6  $country" ; white " Netflix NF unlocking status:\c" ; rred "$NF" ; white " ChatGPT unlocking status: \c" ; rred "$chat");;  
on) 
WARPIPv6Status=$(white "WARP status:\c" ; green "Running, WARP ordinary account (unlimited WARP traffic)" ; white " Service provider Cloudflare obtains the IPV6 address:\c" ; green "$v6  $country" ; white " Netflix NF unlocking status:\c" ; green "$NF" ; white " ChatGPT unlocking status: \c" ; green "$chat");;
off) 
WARPIPv6Status=$(white "WARP status:\c" ; yellow "Closed" ; white " Service provider $isp6 Get IPV6 address:\c" ; yellow "$v6  $country" ; white " Netflix NF unlocking status:\c" ; yellow "$NF" ; white " ChatGPT unlocking status: \c" ; yellow "$chat");;
esac 
else
WARPIPv6Status=$(white "IPV6 status:\c" ; red "No IPV6 address exists")
fi 
}
CheckWARP(){
i=0
while [ $i -le 9 ]; do let i++
yellow "Executed 10 times in total, the IP of the warp is obtained for the $ith time..."
restwarpgo
checkwgcf
if [[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]; then
green "Congratulations! The IP of the warp was obtained successfully!" && dns
break
else
red "Pity! Warp IP acquisition failed"
fi
done
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
red "Failed to install WARP, restore VPS, uninstall WARP"
cwg
echo
[[ $release = Centos && ${vsid} -lt 7 ]] && yellow "Current system version number: Centos $vsid \nIt is recommended to use Centos 7 or above system" 
[[ $release = Ubuntu && ${vsid} -lt 18 ]] && yellow "Current system version number: Ubuntu $vsid \nIt is recommended to use Ubuntu 18 or above system" 
[[ $release = Debian && ${vsid} -lt 10 ]] && yellow "Current system version number: Debian $vsid \nIt is recommended to use Debian 10 or above system"
yellow "hint:"
red "You may be able to use option 2 or 3 to implement WARP"
red "You can also choose WGCF core to install WARP solution one"
exit
else 
green "ok" && systemctl restart warp-go
fi
}
nat4(){
[[ -n $(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+') ]] && wpgo4=$wgo6 || wpgo4=echo
}
WGCFv4(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installed for the first time with warp-go\nWARP IPV4 is now added (IP outbound performance: native IPV6 + WARP IPV4)" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps is installed for the first time with warp-go\nNow adding WARP IPV4 (IP outbound performance: native IPV6 + WARP IPV4)" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single stack vps is installed for the first time with warp-go\nNow add WARP IPV4 (IP outbound performance: only WARP IPV4)" && sleep 2
wpgo1=$wgo1 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
echo 'w4' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has installed warp-go\nNow quickly switch to WARP IPV4 (IP outbound performance: native IPV6 + WARP IPV4)" && sleep 2
wpgo1=$wgo1 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV4 (IP outbound performance: native IPV6 + WARP IPV4)" && sleep 2
wpgo1=$wgo1 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV4 (IP outbound performance: only WARP IPV4)" && sleep 2
wpgo1=$wgo1 && ABC
fi
echo 'w4' > /root/warpip/wp.log
cat /usr/local/bin/warp.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
WGCFv6(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installed for the first time with warp-go\nNow adding WARP IPV6 (IP outbound performance: native IPV4 + WARP IPV6)" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps is installed for the first time with warp-go\nWARP IPV6 is now added (IP outbound performance: only WARP IPV6)" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps is installed for the first time with warp-go\nNow adding WARP IPV6 (IP outbound performance: native IPV4 + WARP IPV6)" && sleep 2
wpgo1=$wgo2 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
echo 'w6' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has installed warp-go\nNow quickly switch to WARP IPV6 (IP outbound performance: native IPV4 + WARP IPV6)" && sleep 2
wpgo1=$wgo2 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV6 (IP outbound performance: only WARP IPV6)" && sleep 2
wpgo1=$wgo2 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV6 (IP outbound performance: native IPV4 + WARP IPV6)" && sleep 2
wpgo1=$wgo2 && ABC
fi
echo 'w6' > /root/warpip/wp.log
cat /usr/local/bin/warp.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
WGCFv4v6(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installed for the first time with warp-go\nNow adding WARP IPV4+IPV6 (IP outbound performance: WARP dual-stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo8 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single stack vps is installed for the first time with warp-go\nWARP IPV4+IPV6 is now added (IP outbound performance: WARP dual stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo5 && wpgo3=$wgo7 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps is installed for the first time with warp-go\nWARP IPV4+IPV6 is now added (IP outbound performance: WARP dual-stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && wpgo2=$wgo4 && wpgo3=$wgo6 && WGCFins
fi
echo 'w64' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
kill -15 $(pgrep warp-go) >/dev/null 2>&1
sleep 2 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has installed warp-go\nNow quickly switch to WARP IPV4+IPV6 (IP outbound performance: WARP dual-stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV4+IPV6 (IP outbound performance: WARP dual-stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has installed warp-go\nNow quickly switch to WARP IPV4+IPV6 (IP outbound performance: WARP dual-stack IPV4 + IPV6)" && sleep 2
wpgo1=$wgo3 && ABC
fi
echo 'w64' > /root/warpip/wp.log
cat /usr/local/bin/warp.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
ABC(){
echo $wpgo1 | sh
echo $wpgo2 | sh
echo $wpgo3 | sh
echo $wpgo4 | sh
}
dns(){
if [[ ! -f /etc/resolv.conf.bak ]]; then
mv /etc/resolv.conf /etc/resolv.conf.bak
rm -rf /etc/resolv.conf
cp -f /etc/resolv.conf.bak /etc/resolv.conf
chattr +i /etc/resolv.conf >/dev/null 2>&1
else
chattr +i /etc/resolv.conf >/dev/null 2>&1
fi
}
WGCFins(){
if [[ $release = Centos ]]; then
yum install epel-release -y;yum install iproute iputils -y
elif [[ $release = Debian ]]; then
apt install lsb-release -y
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update -y;apt install iproute2 openresolv dnsutils iputils-ping -y
elif [[ $release = Ubuntu ]]; then
apt update -y;apt install iproute2 openresolv dnsutils iputils-ping -y
fi
wget -N https://gitlab.com/rwkgyg/CFwarp/-/raw/main/warp-go_1.0.8_linux_${cpu} -O /usr/local/bin/warp-go && chmod +x /usr/local/bin/warp-go
yellow "Applying for WARP ordinary account, please wait!"
curl -L -o /usr/local/bin/warp.conf --retry 2 https://api.zeroteam.top/warp?format=warp-go
if [[ ! -s /usr/local/bin/warp.conf ]]; then
cpujg
curl -L -o warpapi -# --retry 2 https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/cpu1/$cpu
chmod +x warpapi
output=$(./warpapi)
private_key=$(echo "$output" | awk -F ': ' '/private_key/{print $2}')
device_id=$(echo "$output" | awk -F ': ' '/device_id/{print $2}')
warp_token=$(echo "$output" | awk -F ': ' '/token/{print $2}')
rm -rf warpapi
cat > /usr/local/bin/warp.conf <<EOF
[Account]
Device = $device_id
PrivateKey = $private_key
Token = $warp_token
Type = free
Name = WARP
MTU  = 1280
[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
Endpoint = 162.159.193.10:1701
# AllowedIPs = 0.0.0.0/0
# AllowedIPs = ::/0
KeepAlive = 30
EOF
fi
chmod +x /usr/local/bin/warp.conf
sed -i '0,/AllowedIPs/{/AllowedIPs/d;}' /usr/local/bin/warp.conf
sed -i '/KeepAlive/a [Script]' /usr/local/bin/warp.conf
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" /usr/local/bin/warp.conf
cat > /lib/systemd/system/warp-go.service << EOF
[Unit]
Description=warp-go service
After=network.target
Documentation=https://gitlab.com/ProjectWARP/warp-go
[Service]
WorkingDirectory=/root/
ExecStart=/usr/local/bin/warp-go --config=/usr/local/bin/warp.conf
Environment="LOG_LEVEL=verbose"
RemainAfterExit=yes
Restart=always
[Install]
WantedBy=multi-user.target
EOF
ABC
systemctl daemon-reload
systemctl enable warp-go
systemctl start warp-go
restwarpgo
cat /usr/local/bin/warp.conf && sleep 2
checkwgcf
if [[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]; then
green "Congratulations! The IP of the warp was obtained successfully!" && dns
else
CheckWARP
fi
ShowWGCF && lncf && reswarp
curl -s https://gitlab.com/rwkgyg/CFwarp/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1 > /root/warpip/v
}
warpinscha(){
yellow "Tip: The local outbound IP of the VPS will be taken over by the IP of the warp you choose. If the VPS does not have such an outbound IP locally, it will be taken over by the IP of another generated warp."
echo
green "1. Install/switch WARP single-stack IPV4 (press Enter to default)"
green "2. Install/switch WARP single-stack IPV6"
green "3. Install/switch WARP dual stack IPV4+IPV6"
readp "\nPlease select:" wgcfwarp
if [ -z "${wgcfwarp}" ] || [ $wgcfwarp == "1" ];then
WGCFv4
elif [ $wgcfwarp == "2" ];then
WGCFv6
elif [ $wgcfwarp == "3" ];then
WGCFv4v6
else 
red "Input error, please choose again" && warpinscha
fi
echo
} 
WARPup(){
freewarp(){
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4v6
allowips=$(cat /usr/local/bin/warp.conf | grep AllowedIPs)
if [[ -n $v4 && -n $v6 ]]; then
endp=$wgo4
post=$wgo8
elif [[ -n $v6 && -z $v4 ]]; then
endp=$wgo5
[[ -n $(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+') ]] && post=$wgo8 || post=$wgo7
elif [[ -z $v6 && -n $v4 ]]; then
endp=$wgo4
post=$wgo6
fi
yellow "Current execution: Apply for WARP ordinary account"
echo
yellow "Applying for WARP ordinary account, please wait!"
rm -rf /usr/local/bin/warp.conf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
curl -Ls -o /usr/local/bin/warp.conf --retry 2 https://api.zeroteam.top/warp?format=warp-go
if [[ ! -s /usr/local/bin/warp.conf ]]; then
cpujg
curl -Ls -o warpapi --retry 2 https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/cpu1/$cpu
chmod +x warpapi
output=$(./warpapi)
private_key=$(echo "$output" | awk -F ': ' '/private_key/{print $2}')
device_id=$(echo "$output" | awk -F ': ' '/device_id/{print $2}')
warp_token=$(echo "$output" | awk -F ': ' '/token/{print $2}')
rm -rf warpapi
cat > /usr/local/bin/warp.conf <<EOF
[Account]
Device = $device_id
PrivateKey = $private_key
Token = $warp_token
Type = free
Name = WARP
MTU  = 1280
[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
Endpoint = 162.159.193.10:1701
# AllowedIPs = 0.0.0.0/0
# AllowedIPs = ::/0
KeepAlive = 30
EOF
fi
chmod +x /usr/local/bin/warp.conf
sed -i '0,/AllowedIPs/{/AllowedIPs/d;}' /usr/local/bin/warp.conf
sed -i '/KeepAlive/a [Script]' /usr/local/bin/warp.conf
mtuwarp
sed -i "s/MTU.*/MTU = $MTU/g" /usr/local/bin/warp.conf
sed -i "s#.*AllowedIPs.*#$allowips#g" /usr/local/bin/warp.conf
echo $endp | sh
echo $post | sh
CheckWARP && ShowWGCF &&  WGCFmenu
}
green "1. WARP ordinary account (unlimited traffic)"
green "2. WARP+ account (limited traffic)"
green "3. WARP Teams (Zero Trust) team account (unlimited traffic)"
green "4. Socks5+WARP+ account (limited traffic)"
readp "Please select the account type you want to switch:" warpup
if [[ $warpup == 1 ]]; then
freewarp
fi
if [[ $warpup == 4 ]]; then
SOCKS5WARPUP
fi
if [[ $warpup == 2 ]]; then
[[ ! $(type -P warp-go) ]] && red "warp-go is not installed" && exit
green "Please copy the key license key in the WARP+ state of the mobile WARP client or the key shared on the network (26 characters). Currently, due to a bug in WARP-GO, there is a high probability that the upgrade will fail."
readp "Please enter the upgrade WARP+ key:" ID
if [[ -z $ID ]]; then
red "No content entered" && WARPup
fi
readp "Set the device name and press Enter to make it random:" dname
if [[ -z $dname ]]; then
dname=`date +%s%N |md5sum | cut -c 1-4`
fi
green "The device name is $dname"
/usr/local/bin/warp-go --update --config=/usr/local/bin/warp.conf --license=$ID --device-name=$dname
i=0
while [ $i -le 9 ]; do let i++
yellow "Executed 10 times in total, $i upgrade WARP+ account..." 
restwarpgo
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
echo "$dname" >> /usr/local/bin/warpplus.log && echo "$ID" >> /usr/local/bin/warpplus.log
green "WARP+ account upgrade successful!" && ShowWGCF && WGCFmenu && break
else
red "WARP+ account upgrade failed!" && sleep 1
fi
done
if [[ ! $wgcfv4 = plus && ! $wgcfv6 = plus ]]; then
green "suggestions below:"
yellow "1. Check whether the WARP+ account in 1.1.1.1 APP or the secret key shared by the network has traffic."
yellow "2. Check that the current WARP license key is bound to more than 5 devices. Please enter the mobile phone to remove the device and then try to upgrade the WARP+ account." && sleep 2
freewarp
fi
fi
    
if [[ $warpup == 3 ]]; then
[[ ! $(type -P warp-go) ]] && red "warp-go is not installed" && exit
green "Zero Trust team Token acquisition address: https://web--public--warp-team-api--coia-mfs4.code.run/"
readp "Please enter the team account Token:" token
curl -Ls -o /usr/local/bin/warp.conf.bak --retry 2 https://api.zeroteam.top/warp?format=warp-go
if [[ ! -s /usr/local/bin/warp.conf.bak ]]; then
cpujg
curl -Ls -o warpapi --retry 2 https://gitlab.com/rwkgyg/CFwarp/-/raw/main/point/cpu1/$cpu
chmod +x warpapi
output=$(./warpapi)
private_key=$(echo "$output" | awk -F ': ' '/private_key/{print $2}')
device_id=$(echo "$output" | awk -F ': ' '/device_id/{print $2}')
warp_token=$(echo "$output" | awk -F ': ' '/token/{print $2}')
rm -rf warpapi
cat > /usr/local/bin/warp.conf.bak <<EOF
[Account]
Device = $device_id
PrivateKey = $private_key
Token = $warp_token
Type = free
Name = WARP
MTU  = 1280
[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
Endpoint = 162.159.193.10:1701
# AllowedIPs = 0.0.0.0/0
# AllowedIPs = ::/0
KeepAlive = 30
EOF
fi
/usr/local/bin/warp-go --register --config=/usr/local/bin/warp.conf.bak --team-config=$token --device-name=vps+warp+teams+$(date +%s%N |md5sum | cut -c 1-3)
sed -i "2s#.*#$(sed -ne 2p /usr/local/bin/warp.conf.bak)#;3s#.*#$(sed -ne 3p /usr/local/bin/warp.conf.bak)#" /usr/local/bin/warp.conf >/dev/null 2>&1
sed -i "4s#.*#$(sed -ne 4p /usr/local/bin/warp.conf.bak)#;5s#.*#$(sed -ne 5p /usr/local/bin/warp.conf.bak)#" /usr/local/bin/warp.conf >/dev/null 2>&1
i=0
while [ $i -le 9 ]; do let i++
yellow "Executed 10 times in total, the IP of the warp is obtained for the $ith time..."
restwarpgo
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /usr/local/bin/warp.conf.bak /usr/local/bin/warpplus.log
green "WARP Teams account upgraded successfully!" && ShowWGCF && WGCFmenu && break
else
red "WARP Teams account upgrade failed!" && sleep 1
fi
done
if [[ ! $wgcfv4 = plus && ! $wgcfv6 = plus ]]; then
freewarp
fi
fi
}
WARPonoff(){
[[ ! $(type -P warp-go) ]] && red "WARP is not installed, it is recommended to reinstall it" && exit
readp "1. Turn off the WARP function (turn off WARP online monitoring)\n2. Enable/restart the WARP function (start WARP online monitoring)\n0. Return to the previous level\n Please select:" unwp
if [ "$unwp" == "1" ]; then
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
systemctl disable warp-go
screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null
unreswarp
checkwgcf 
[[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]] && green "Close WARP successfully" || red "Failed to close WARP"
elif [ "$unwp" == "2" ]; then
CheckWARP
xyz
name=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
[[ $name =~ "up" ]] && green "WARP online monitoring started successfully" || red "WARP online monitoring fails to start. Check whether screen is installed successfully."
reswarp
checkwgcf 
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "Opening warp successfully" || red "Failed to open warp"
else
cf
fi
}
cwg(){
screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null
systemctl disable warp-go >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 
chattr -i /etc/resolv.conf >/dev/null 2>&1
sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf 2>/dev/null
rm -rf /usr/local/bin/warp-go /usr/local/bin/warpplus.log /usr/local/bin/warp.conf /usr/local/bin/wgwarp.conf /usr/local/bin/sbwarp.json /usr/bin/warp-go /lib/systemd/system/warp-go.service /root/WARP-UP.sh
rm -rf /root/warpip
}
changewarp(){
cwg && ONEWGCFWARP
}
upwarpgo(){
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
wget -N https://gitlab.com/rwkgyg/CFwarp/-/raw/main/warp-go_1.0.8_linux_${cpu} -O /usr/local/bin/warp-go && chmod +x /usr/local/bin/warp-go
restwarpgo
loVERSION="$(/usr/local/bin/warp-go -v | sed -n 1p | awk '{print $1}' | awk -F"/" '{print $NF}')"
green " Currently WARP-GO has installed kernel version number: ${loVERSION}, which is the latest version"
}
start_menu(){
ShowWGCF;ShowSOCKS5
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "Yongge Github project: github.com/yonggekkk"
white "Yongge Blogger Blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow " You can choose any realistic warp solution that suits you (options 1, 2, and 3, single selection is available, and multiple selections can coexist)"
yellow " Enter the script shortcut: cf"
white " ================================================================="
green "  1. Option 1: Install/Switch WARP-GO"
[[ $cpu != amd64* ]] && red "  2. Option 2: Install Socks5-WARP (only supports amd64 architecture, currently Option 2 is not available)" || green "  2. Option 2: Install Socks5-WARP"
green "  3. Option 3: Generate WARP-Wireguard configuration file and QR code"
green "  4. Uninstall WARP"
white " -----------------------------------------------------------------"
green "  5. Close, enable/restart WARP"
green "  6. WARP other options"
green "  7. WARP three-type account upgrade/switching"
green "  8. Update CFwarp installation script"
green "  9. Update WARP-GO kernel"
green " 10. Replace the current WARP-GO kernel with the WGCF-WARP kernel"
green "  0. Exit script"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
cfwarpshow
if [[ $(type -P warp-go) ]] && [[ -f '/usr/bin/cf' ]]; then
loVERSION="$(/usr/local/bin/warp-go -v | sed -n 1p | awk '{print $1}' | awk -F"/" '{print $NF}')"
wgVERSION="$(curl -s https://gitlab.com/rwkgyg/CFwarp/raw/main/version/warpgoV)"
if [ "${loVERSION}" = "${wgVERSION}" ]; then
echo -e " Currently WARP-GO has installed kernel version number: ${bblue}${loVERSION}${plain}, which is the latest version"
else
echo -e " The current WARP-GO installed kernel version number is: ${bblue}${loVERSION}${plain}"
echo -e " The latest WARP-GO kernel version number detected: ${yellow}${wgVERSION}${plain}, you can choose 9 to update"
fi
fi
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white " VPS system information is as follows:"
white " Operating System: $(blue "$op") \c" && white " Kernel version: $(blue "$version") \c" && white " CPU architecture: $(blue "$cpu") \c" && white " Virtualization type: $(blue "$vi")"
WGCFmenu
S5menu
echo
readp " Please enter the number:" Input
case "$Input" in     
 1 ) warpinscha;;
 2 ) [[ $cpu = amd64* ]] && SOCKS5ins || exit;;
 3 ) WGproxy;;
 4 ) WARPun;;
 5 ) WARPonoff;;
 6 ) WARPtools;;
 7 ) WARPup;;
 8 ) UPwpyg;;
 9 ) upwarpgo;;
 10 ) changewarp;;
 * ) exit
esac
}
if [ $# == 0 ]; then
bit=`uname -m`
[[ $bit = aarch64 ]] && cpu=arm64
if [[ $bit = x86_64 ]]; then
amdv=$(cat /proc/cpuinfo | grep flags | head -n 1 | cut -d: -f2)
case "$amdv" in
*avx512*) cpu=amd64v4;;
*avx2*) cpu=amd64v3;;
*sse3*) cpu=amd64v2;;
*) cpu=amd64;;
esac
fi
start_menu
fi
}
ONEWGCFWARP(){
yellow "\n Please wait, it is currently in wgcf core installation mode, detecting the peer IP and outbound status..."
warpip
ud4='sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
ud6='sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
ud4ud6='sed -i "7 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf && sed -i "7 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" /etc/wireguard/wgcf.conf'
c1="sed -i '/0\.0\.0\.0\/0/d' /etc/wireguard/wgcf.conf"
c2="sed -i '/\:\:\/0/d' /etc/wireguard/wgcf.conf"
c3="sed -i "s/engage.cloudflareclient.com:2408/$endpoint/g" /etc/wireguard/wgcf.conf"
c4="sed -i "s/engage.cloudflareclient.com:2408/$endpoint/g" /etc/wireguard/wgcf.conf"
c5="sed -i 's/1.1.1.1/8.8.8.8,2001:4860:4860::8888/g' /etc/wireguard/wgcf.conf"
c6="sed -i 's/1.1.1.1/2001:4860:4860::8888,8.8.8.8/g' /etc/wireguard/wgcf.conf"
ShowWGCF(){
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
v4v6
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -sm4 "https://api.cloudflareclient.com/v0a884/reg/$(grep 'device_id' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'access_token' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
[[ -e /etc/wireguard/wgcf+p.log ]] && cfplus="WARP+ account (limited WARP+ traffic: $flow GB), device name: $(grep -s 'Device name' /etc/wireguard/wgcf+p.log | awk '{ print $NF }')" || cfplus="WARP+Teams account (unlimited WARP+ traffic)"
if [[ -n $v4 ]]; then
nf4
chatgpt4
checkgpt
wgcfv4=$(curl -s4 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp4a=`curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f13 -d ":" | cut -f2 -d '"'`
isp4b=`curl -sm3 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp4a ]] && isp4=$isp4a || isp4=$isp4b
nonf=$(curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '4p')
#snnf=$(curl -s4m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv4} in 
plus) 
WARPIPv4Status=$(white "WARP+ status:\c" ; rred "Running, $cfplus" ; white " Service provider Cloudflare obtains the IPV4 address:\c" ; rred "$v4  $country" ; white " Netflix NF unlocking status:\c" ; rred "$NF" ; white " ChatGPT unlocking status: \c" ; rred "$chat");;  
on) 
WARPIPv4Status=$(white "WARP status:\c" ; green "Running, WARP ordinary account (unlimited WARP traffic)" ; white " Service provider Cloudflare obtains the IPV4 address:\c" ; green "$v4  $country" ; white " Netflix NF unlocking status:\c" ; green "$NF" ; white " ChatGPT unlocking status: \c" ; green "$chat");;
off) 
WARPIPv4Status=$(white "WARP status:\c" ; yellow "Closed" ; white " Service provider $isp4 Get IPV4 address:\c" ; yellow "$v4  $country" ; white " Netflix NF unlocking status:\c" ; yellow "$NF" ; white " ChatGPT unlocking status: \c" ; yellow "$chat");; 
esac 
else
WARPIPv4Status=$(white "IPV4 status: \c" ; red "No IPV4 address exists")
fi 
if [[ -n $v6 ]]; then
nf6
chatgpt6
checkgpt
wgcfv6=$(curl -s6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
isp6a=`curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f13 -d":" | cut -f2 -d '"'`
isp6b=`curl -sm3 --user-agent "${UA_Browser}" https://api.ip.sb/geoip/$v6 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
[[ -n $isp6a ]] && isp6=$isp6a || isp6=$isp6b
nonf=$(curl -sm3 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
#sunf=$(./nf | awk '{print $1}' | sed -n '8p')
#snnf=$(curl -s6m6 ip.p3terx.com -k | sed -n 2p | awk '{print $3}')
country=$nonf
case ${wgcfv6} in 
plus) 
WARPIPv6Status=$(white "WARP+ status:\c" ; rred "Running, $cfplus" ; white " Service provider Cloudflare obtains the IPV6 address:\c" ; rred "$v6  $country" ; white " Netflix NF unlocking status:\c" ; rred "$NF" ; white " ChatGPT unlocking status: \c" ; rred "$chat");;  
on) 
WARPIPv6Status=$(white "WARP status:\c" ; green "Running, WARP ordinary account (unlimited WARP traffic)" ; white " Service provider Cloudflare obtains the IPV6 address:\c" ; green "$v6  $country" ; white " Netflix NF unlocking status:\c" ; green "$NF" ; white " ChatGPT unlocking status: \c" ; green "$chat");;
off) 
WARPIPv6Status=$(white "WARP status:\c" ; yellow "Closed" ; white " Service provider $isp6 Get IPV6 address:\c" ; yellow "$v6  $country" ; white " Netflix NF unlocking status:\c" ; yellow "$NF" ; white " ChatGPT unlocking status: \c" ; yellow "$chat");;
esac 
else
WARPIPv6Status=$(white "IPV6 status:\c" ; red "No IPV6 address exists")
fi 
}
STOPwgcf(){
if [[ $(type -P warp-cli) ]]; then
red "Socks5-WARP has been installed, and the currently selected wgcf-warp installation solution is not supported." 
systemctl restart wg-quick@wgcf && cf
fi
}
fawgcf(){
rm -f /etc/wireguard/wgcf+p.log
ID=$(cat /etc/wireguard/buckup-account.toml | grep license_key | awk '{print $3}')
sed -i "s/license_key.*/license_key = $ID/g" /etc/wireguard/wgcf-account.toml
cd /etc/wireguard && wgcf update >/dev/null 2>&1
wgcf generate >/dev/null 2>&1 && cd
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
CheckWARP && ShowWGCF &&  WGCFmenu
}
ABC(){
echo $ABC1 | sh
echo $ABC2 | sh
echo $ABC3 | sh
echo $ABC4 | sh
echo $ABC5 | sh
}
conf(){
rm -rf /etc/wireguard/wgcf.conf
cp -f /etc/wireguard/buckup-profile.conf /etc/wireguard/wgcf.conf >/dev/null 2>&1
cp -f /etc/wireguard/wgcf-profile.conf /etc/wireguard/buckup-profile.conf >/dev/null 2>&1
}
nat4(){
[[ -n $(ip route get 162.159.192.1 2>/dev/null | grep -oP 'src \K\S+') ]] && ABC4=$ud4 || ABC4=echo
}
WGCFv4(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installing wgcf-warp for the first time\nNow adding IPV4 single-stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c2 && ABC3=$ud4 && ABC4=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single stack vps is installing wgcf-warp for the first time\nNow adding IPV4 single stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c4 && ABC3=$c2 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single stack vps is installing wgcf-warp for the first time\nNow adding IPV4 single stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c2 && ABC3=$c3 && ABC4=$ud4 && WGCFins
fi
echo 'w4' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has wgcf-warp installed\nNow quickly switch to IPV4 single-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c2 && ABC3=$ud4 && ABC4=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV4 single-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c4 && ABC3=$c2 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV4 single-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c2 && ABC3=$c3 && ABC4=$ud4 && ABC
fi
echo 'w4' > /root/warpip/wp.log
cat /etc/wireguard/wgcf.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
WGCFv6(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installing wgcf-warp for the first time\nNow adding IPV6 single-stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c1 && ABC3=$ud6 && ABC4=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps is installing wgcf-warp for the first time\nNow adding IPV6 single-stack wgcf-warp mode (no IPV4!!!)" && sleep 2
ABC1=$c6 && ABC2=$c1 && ABC3=$c4 && nat4 && ABC5=$ud6 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single stack vps is installing wgcf-warp for the first time\nNow adding IPV6 single stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c3 && ABC3=$c1 && WGCFins
fi
echo 'w6' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has wgcf-warp installed\nNow quickly switch to IPV6 single-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c1 && ABC3=$ud6 && ABC4=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV6 single-stack wgcf-warp mode (no IPV4!!!)" && sleep 2
conf && ABC1=$c6 && ABC2=$c1 && ABC3=$c4 && nat4 && ABC5=$ud6 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV6 single-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c3 && ABC3=$c1 && ABC
fi
echo 'w6' > /root/warpip/wp.log
cat /etc/wireguard/wgcf.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
WGCFv4v6(){
yellow "Wait for 3 seconds to detect the warp environment in the VPS."
docker && checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps is installing wgcf-warp for the first time\nNow adding IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$ud4ud6 && ABC3=$c3 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps is installing wgcf-warp for the first time\nNow adding IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c4 && ABC3=$ud6 && nat4 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps is installing wgcf-warp for the first time\nNow adding IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
ABC1=$c5 && ABC2=$c3 && ABC3=$ud4 && WGCFins
fi
echo 'w64' > /root/warpip/wp.log && xyz && WGCFmenu
first4
else
wg-quick down wgcf >/dev/null 2>&1
sleep 1 && v4v6
if [[ -n $v4 && -n $v6 ]]; then
green "The current native v4+v6 dual-stack vps has wgcf-warp installed\nNow quickly switch to IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$ud4ud6 && ABC3=$c3 && ABC
fi
if [[ -n $v6 && -z $v4 ]]; then
green "The current native v6 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c4 && ABC3=$ud6 && nat4 && ABC
fi
if [[ -z $v6 && -n $v4 ]]; then
green "The current native v4 single-stack vps has wgcf-warp installed\nNow quickly switch to IPV4+IPV6 dual-stack wgcf-warp mode" && sleep 2
conf && ABC1=$c5 && ABC2=$c3 && ABC3=$ud4 && ABC
fi
echo 'w64' > /root/warpip/wp.log
cat /etc/wireguard/wgcf.conf && sleep 2
CheckWARP && first4 && ShowWGCF && WGCFmenu
fi
}
CheckWARP(){
i=0
wg-quick down wgcf >/dev/null 2>&1
while [ $i -le 9 ]; do let i++
yellow "Executed 10 times in total, the IP of the warp is obtained for the $ith time..."
systemctl restart wg-quick@wgcf >/dev/null 2>&1
checkwgcf
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "Congratulations! The IP of the warp was obtained successfully!" && break || red "Pity! Warp IP acquisition failed"
done
checkwgcf
if [[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]]; then
red "Failed to install WARP, restore VPS, uninstall Wgcf-WARP component..."
cwg
echo
[[ $release = Centos && ${vsid} -lt 7 ]] && yellow "Current system version number: Centos $vsid \nIt is recommended to use Centos 7 or above system" 
[[ $release = Ubuntu && ${vsid} -lt 18 ]] && yellow "Current system version number: Ubuntu $vsid \nIt is recommended to use Ubuntu 18 or above system" 
[[ $release = Debian && ${vsid} -lt 10 ]] && yellow "Current system version number: Debian $vsid \nIt is recommended to use Debian 10 or above system"
yellow "hint:"
red "You may be able to use option 2 or 3 to implement WARP"
red "You can also choose WARP-GO core to install WARP solution one"
exit
else 
green "ok"
fi
}
WGCFins(){
rm -rf /usr/local/bin/wgcf /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go /usr/bin/wgcf wgcf-account.toml wgcf-profile.conf /etc/wireguard/buckup-profile.conf
if [[ $release = Centos ]]; then
yum install epel-release -y;yum install iproute iptables wireguard-tools -y
elif [[ $release = Debian ]]; then
apt install lsb-release -y
echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update -y;apt install iproute2 openresolv dnsutils iptables iputils-ping -y;apt install wireguard-tools --no-install-recommends -y      		
elif [[ $release = Ubuntu ]]; then
apt update -y;apt install iproute2 openresolv dnsutils iptables iputils-ping -y;apt install wireguard-tools --no-install-recommends -y			
fi
wget -N https://gitlab.com/rwkgyg/cfwarp/raw/main/wgcf_2.2.19_$cpu -O /usr/local/bin/wgcf && chmod +x /usr/local/bin/wgcf         
if [[ $main -lt 5 || $minor -lt 6 ]] || [[ $vi =~ lxc|openvz ]]; then
[[ -e /usr/bin/wireguard-go ]] || wget -N https://gitlab.com/rwkgyg/cfwarp/raw/main/wireguard-go -O /usr/bin/wireguard-go && chmod +x /usr/bin/wireguard-go
fi
echo | wgcf register
until [[ -e wgcf-account.toml ]]
do
yellow "During the process of applying for a warp ordinary account, you may be prompted multiple times: 429 Too Many Requests, please wait 30 seconds." && sleep 1
echo | wgcf register --accept-tos
done
wgcf generate
mtuwarp
#blue "Check whether the warp+ account can be automatically generated and used. Please wait for 10 seconds."
#wppluskey >/dev/null 2>&1
sed -i "s/MTU.*/MTU = $MTU/g" wgcf-profile.conf
cp -f wgcf-profile.conf /etc/wireguard/wgcf.conf >/dev/null 2>&1
cp -f wgcf-account.toml /etc/wireguard/buckup-account.toml  >/dev/null 2>&1
cp -f wgcf-profile.conf /etc/wireguard/buckup-profile.conf  >/dev/null 2>&1
ABC
mv -f wgcf-profile.conf /etc/wireguard >/dev/null 2>&1
mv -f wgcf-account.toml /etc/wireguard >/dev/null 2>&1
#ID=$(tail -n1 /root/WARP+Keys.txt | cut -d' ' -f1 2>/dev/null)
#if [[ -n $ID ]]; then
#green "Use warp+key"
#green "$(tail -n1 /root/WARP+Keys.txt | cut -d' ' -f1 2>/dev/null)"
#sed -i "s/license_key.*/license_key = '$ID'/g" /etc/wireguard/wgcf-account.toml
#sbmc=warp+$(date +%s%N |md5sum | cut -c 1-3)
#SBID="--name $(echo $sbmc | sed s/[[:space:]]/_/g)"
#rm -rf warpplus.sh
#cd /etc/wireguard && wgcf update $SBID > /etc/wireguard/wgcf+p.log 2>&1
#wgcf generate && cd
#sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
#sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/buckup-profile.conf
#else
#yellow "Warp+ cannot be automatically generated, and a normal warp account can be generated directly."
#fi
systemctl enable wg-quick@wgcf
cat /etc/wireguard/wgcf.conf && sleep 2
CheckWARP && ShowWGCF && lncf && reswarp
curl -s https://gitlab.com/rwkgyg/CFwarp/-/raw/main/version/version | awk -F "update content" '{print $1}' | head -n 1 > /root/warpip/v
}
WARPup(){
backconf(){
red "If the upgrade fails, the ordinary warp account will be automatically restored."
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
CheckWARP && ShowWGCF && WGCFmenu
}
readp "1.Teams team account\n2.warp+ account\n3. Ordinary warp account\n4.Socks5+WARP+ account\n0. Return to the previous level\n Please choose:" cd
case "$cd" in 
1 )
result(){
sed -i "s#PrivateKey.*#PrivateKey = $PRIVATEKEY#g;s#Address.*128#Address = $ADDRESS6/128#g" /etc/wireguard/wgcf.conf
sed -i "s#PrivateKey.*#PrivateKey = $PRIVATEKEY#g;s#Address.*128#Address = $ADDRESS6/128#g" /etc/wireguard/buckup-profile.conf
CheckWARP
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
rm -rf /etc/wireguard/wgcf+p.log && green "wgcf-warp+Teams account has taken effect" && ShowWGCF && WGCFmenu
else
backconf
fi
}
[[ ! $(type -P wg-quick) ]] && red "wgcf-warp is not installed. Install wgcf-warp before execution." && exit
green "1. Use Token to obtain a Teams team account. Token acquisition address: https://web--public--warp-team-api--coia-mfs4.code.run/"
green "2. Manually copy the private key and IPV6 address"
green "0. Exit"
readp "please choose:" up
if [[ $up == 1 ]]; then
readp " Please copy the team account Token:" TEAM_TOKEN
PRIVATEKEY=$(wg genkey)
PUBLICKEY=$(wg pubkey <<< "$PRIVATEKEY")
INSTALL_ID=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 22)
FCM_TOKEN="${INSTALL_ID}:APA91b$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 134)"
ERROR_TIMES=0
while [ "$ERROR_TIMES" -le 3 ]; do
(( ERROR_TIMES++ ))
if [[ "$TEAMS" =~ 'token is expired' ]]; then
read -p " Please refresh the token and copy again" TEAM_TOKEN
elif [[ "$TEAMS" =~ 'error' ]]; then
read -p " Please refresh the token and copy again" TEAM_TOKEN
elif [[ "$TEAMS" =~ 'organization' ]]; then
break
fi
TEAMS=$(curl --silent --location --tlsv1.3 --request POST 'https://api.cloudflareclient.com/v0a2158/reg' \
--header 'User-Agent: okhttp/3.12.1' \
--header 'CF-Client-Version: a-6.10-2158' \
--header 'Content-Type: application/json' \
--header "Cf-Access-Jwt-Assertion: ${TEAM_TOKEN}" \
--data '{"key":"'${PUBLICKEY}'","install_id":"'${INSTALL_ID}'","fcm_token":"'${FCM_TOKEN}'","tos":"'$(date +"%Y-%m-%dT%H:%M:%S.%3NZ")'","model":"Linux","serial_number":"'${INSTALL_ID}'","locale":"zh_CN"}')
ADDRESS6=$(expr "$TEAMS" : '.*"v6":[ ]*"\([^"]*\).*')
done
result
elif [[ $up == 2 ]]; then
readp "Please copy privateKey (44 characters):" PRIVATEKEY
readp "Please copy the Address of IPV6:" ADDRESS6
result
else
exit
fi
;;
2 )
[[ ! $(type -P wg-quick) ]] && red "wgcf-warp is not installed. Install wgcf-warp before execution." && exit
readp "Please copy the key license key in the WARP+ state of the mobile WARP client or the key shared on the network (26 characters):" ID
[[ -n $ID ]] && sed -i "s/license_key.*/license_key = '$ID'/g" /etc/wireguard/wgcf-account.toml && readp "Rename the device name (just press Enter to name randomly):" sbmc || (red "Key license key not entered (26 characters)" && cf)
[[ -n $sbmc ]] && SBID="--name $(echo $sbmc | sed s/[[:space:]]/_/g)"
cd /etc/wireguard && wgcf update $SBID > /etc/wireguard/wgcf+p.log 2>&1
wgcf generate && cd
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/wgcf.conf
sed -i "2s#.*#$(sed -ne 2p /etc/wireguard/wgcf-profile.conf)#;4s#.*#$(sed -ne 4p /etc/wireguard/wgcf-profile.conf)#" /etc/wireguard/buckup-profile.conf
CheckWARP && checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
warppflow=$((`grep -oP '"quota":\K\d+' <<< $(curl -s "https://api.cloudflareclient.com/v0a884/reg/$(grep 'device_id' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $(grep 'access_token' /etc/wireguard/wgcf-account.toml 2>/dev/null | cut -d \' -f2)")`))
flow=`echo "scale=2; $warppflow/1000000000" | bc`
green "Upgraded to wgcf-warp+ account\nwgcf-warp+ account device name: $(grep -s 'Device name' /etc/wireguard/wgcf+p.log | awk '{ print $NF }')\nwgcf-warp+ account remaining Traffic: $flow GB"
ShowWGCF && WGCFmenu 
else
red "After IP detection, the upgrade to warp+ failed. Please ensure that the key is used by no more than 5 devices. It is recommended to change the key and try again. The script exits." && exit
fi;;
3 )
checkwgcf
if [[ $wgcfv4 = plus || $wgcfv6 = plus ]]; then
fawgcf
else
yellow "Currently it is a normal account of wgcf-warp"
ShowWGCF && WGCFmenu
fi;;
4 )
SOCKS5WARPUP;;
0 ) cf
esac
}
WARPonoff(){
[[ ! $(type -P wg-quick) ]] && red "WARP is not installed, it is recommended to reinstall it" && exit
readp "1. Turn off the WARP function (turn off WARP online monitoring)\n2. Enable/restart the WARP function (start WARP online monitoring)\n0. Return to the previous level\n Please select:" unwp
if [ "$unwp" == "1" ]; then
wg-quick down wgcf >/dev/null 2>&1
systemctl stop wg-quick@wgcf >/dev/null 2>&1
systemctl disable wg-quick@wgcf >/dev/null 2>&1
screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null
unreswarp
checkwgcf 
[[ ! $wgcfv4 =~ on|plus && ! $wgcfv6 =~ on|plus ]] && green "Close warp successfully" || red "Failed to close warp"
elif [ "$unwp" == "2" ]; then
wg-quick down wgcf >/dev/null 2>&1
systemctl restart wg-quick@wgcf >/dev/null 2>&1
xyz
name=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
[[ $name =~ "up" ]] && green "WARP online monitoring started successfully" || red "WARP online monitoring fails to start. Check whether screen is installed successfully."
reswarp
checkwgcf 
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]] && green "Opening warp successfully" || red "Failed to open warp"
else
cf
fi
}
cwg(){
screen -ls | awk '/\.up/ {print $1}' | cut -d "." -f 1 | xargs kill 2>/dev/null
wg-quick down wgcf >/dev/null 2>&1
systemctl disable wg-quick@wgcf >/dev/null 2>&1
$yumapt remove wireguard-tools
$yumapt autoremove
dig9
sed -i '/^precedence ::ffff:0:0\/96  100/d' /etc/gai.conf 2>/dev/null
rm -rf /usr/local/bin/wgcf /usr/bin/wg-quick /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/buckup-account.toml /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go /usr/bin/wgcf wgcf-account.toml wgcf-profile.conf /etc/wireguard/buckup-profile.conf /root/WARP-UP.sh
rm -rf /root/warpip /root/WARP+Keys.txt
}
warpinscha(){
yellow "Tip: The local outbound IP of the VPS will be taken over by the IP of the warp you choose. If the VPS does not have such an outbound IP locally, it will be taken over by the IP of another generated warp."
echo
green "1. Install/switch wgcf-warp single stack IPV4 (press Enter to default)"
green "2. Install/switch wgcf-warp single stack IPV6"
green "3. Install/switch wgcf-warp dual stack IPV4+IPV6"
readp "\nPlease select:" wgcfwarp
if [ -z "${wgcfwarp}" ] || [ $wgcfwarp == "1" ];then
WGCFv4
elif [ $wgcfwarp == "2" ];then
WGCFv6
elif [ $wgcfwarp == "3" ];then
WGCFv4v6
else 
red "Input error, please choose again" && warpinscha
fi
echo
}  
changewarp(){
cwg && ONEWARPGO
}
start_menu(){
ShowWGCF;ShowSOCKS5
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "Yongge Github project: github.com/yonggekkk"
white "Yongge Blogger Blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
yellow " You can choose any realistic warp solution that suits you (options 1, 2, and 3, single selection is available, and multiple selections can coexist)"
yellow " Enter the script shortcut: cf"
white " ================================================================="
green "  1. Solution 1: Install/Switch WGCF-WARP"
[[ $cpu != amd64* ]] && red "  2. Option 2: Install Socks5-WARP (only supports amd64 architecture, currently Option 2 is not available)" || green "  2. Option 2: Install Socks5-WARP"
green "  3. Option 3: Generate WARP-Wireguard configuration file and QR code"
green "  4. Uninstall WARP"
white " -----------------------------------------------------------------"
green "  5. Close, enable/restart WARP"
green "  6. WARP other options"
green "  7. WARP three-type account upgrade/switching"
green "  8. Update CFwarp installation script" 
green "  9. Replace the current WGCF-WARP kernel with the WARP-GO kernel"
green "  0. Exit script"
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
cfwarpshow
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white " VPS system information is as follows:"
white " Operating System: $(blue "$op") \c" && white " Kernel version: $(blue "$version") \c" && white " CPU architecture: $(blue "$cpu") \c" && white " Virtualization type: $(blue "$vi")"
WGCFmenu
S5menu
echo
readp " Please enter the number:" Input
case "$Input" in     
 1 ) warpinscha;;
 2 ) [[ $cpu = amd64 ]] && SOCKS5ins || exit;;
 3 ) WGproxy;;
 4 ) WARPun;;
 5 ) WARPonoff;;
 6 ) WARPtools;;
 7 ) WARPup;;
 8 ) UPwpyg;;
 9 ) changewarp;;
 * ) exit 
esac
}
if [ $# == 0 ]; then
cpujg
start_menu
fi
}
checkyl(){
if [ ! -f warp_update ]; then
green "Run the CFwarp-yg script for the first time and install the necessary dependencies... Please wait."
update(){
if [ -x "$(command -v apt-get)" ]; then
apt update -y
elif [ -x "$(command -v yum)" ]; then
yum update && yum install epel-release -y
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
packages=("curl" "openssl" "bc" "python3" "screen" "qrencode" "wget" "cron")
inspackages=("curl" "openssl" "bc" "python3" "screen" "qrencode" "wget" "cron")
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
fi
update
touch warp_update
tun
fi
}
startCFwarp(){
checkyl
clear
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"           
echo -e "${bblue} ░██     ░██      ░██ ██ ██         ░█${plain}█   ░██     ░██   ░██     ░█${red}█   ░██${plain}  "
echo -e "${bblue}  ░██   ░██      ░██    ░░██${plain}        ░██  ░██      ░██  ░██${red}      ░██  ░██${plain}   "
echo -e "${bblue}   ░██ ░██      ░██ ${plain}                ░██ ██        ░██ █${red}█        ░██ ██  ${plain}   "
echo -e "${bblue}     ░██        ░${plain}██    ░██ ██       ░██ ██        ░█${red}█ ██        ░██ ██  ${plain}  "
echo -e "${bblue}     ░██ ${plain}        ░██    ░░██        ░██ ░██       ░${red}██ ░██       ░██ ░██ ${plain}  "
echo -e "${bblue}     ░█${plain}█          ░██ ██ ██         ░██  ░░${red}██     ░██  ░░██     ░██  ░░██ ${plain}  "
echo
white "Yongge Github project: github.com/yonggekkk"
white "Yongge Blogger Blog: ygkkk.blogspot.com"
white "Brother Yong’s YouTube channel: www.youtube.com/@ygkkk"
yellow "Translated by Hosy: https://github.com/hrostami"
green "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
yellow "Please wait for 5 seconds to check whether Netflix and ChatGPT are unlocked"
echo
echo
v4v6
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
if [[ -n $v6 ]]; then
nonf=$(curl -s6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v6?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
nf6;chatgpt6;checkgpt
v6Status=$(white "IPV6 address: \c" ; blue "$v6   $nonf" ; white " Netflix： \c" ; blue "$NF" ; white " ChatGPT： \c" ; blue "$chat")
else
v6Status=$(white "IPV6 address: \c" ; red "No IPV6 address exists")
fi
if [[ -n $v4 ]]; then
nonf=$(curl -s4 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"')
nf4;chatgpt4;checkgpt
v4Status=$(white "IPv4 address:\c" ; blue "$v4   $nonf" ; white " Netflix： \c" ; blue "$NF" ; white " ChatGPT： \c" ; blue "$chat")
else
v4Status=$(white "IPv4 address:\c" ; red "No IPV4 address exists")
fi
echo "-----------------------------------------------------------------------"
white " ${v4Status}"
echo "-----------------------------------------------------------------------"
white " ${v6Status}"
echo "-----------------------------------------------------------------------"
echo
echo
white "=================================================================="
yellow " Do you want to install WARP?"
yellow " Two current advantages:"
yellow " 1. Chance to fully unlock Netflix and ChatGPT"
yellow " 2. You can choose to take over the outbound IP of local IPV4, IPV6, and Socks5"
echo "-------------------------------------------------------------------"
green " 1. Select the warp-go solution to enter the WARP installation menu (recommended)"
green " 2. Select the wgcf solution to enter the WARP installation menu"
green " 0. Exit script"
white "=================================================================="
echo
readp " Please enter a number [0-2]:" Input
case "$Input" in
 1 ) ONEWARPGO;;
 2 ) ONEWGCFWARP;;
 * ) exit
esac
}
if [ $# == 0 ]; then
if [[ -n $(type -P warp-go) && -z $(type -P wg-quick) ]] && [[ -f '/usr/bin/cf' ]]; then
ONEWARPGO
elif [[ -n $(type -P warp-go) && -n $(type -P warp-cli) && -z $(type -P wg-quick) ]] && [[ -f '/usr/bin/cf' ]]; then
ONEWARPGO
elif [[ -z $(type -P warp-go) && -z $(type -P wg-quick) && -n $(type -P warp-cli) ]] && [[ -f '/usr/bin/cf' ]]; then
ONEWARPGO
elif [[ -n $(type -P wg-quick) && -z $(type -P warp-go) ]] && [[ -f '/usr/bin/cf' ]]; then
ONEWGCFWARP
elif [[ -n $(type -P wg-quick) && -n $(type -P warp-cli) && -z $(type -P warp-go) ]] && [[ -f '/usr/bin/cf' ]]; then
ONEWGCFWARP
else
startCFwarp
fi
fi
