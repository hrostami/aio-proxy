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
vsid=$(grep -i version_id /etc/os-release 2>/dev/null | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
red "The script does not support the current $op system, please choose to use Ubuntu, Debian, Centos system." && exit
fi
case $(uname -m) in
aarch64) cpu=arm64;;
x86_64) cpu=amd64;;
*) red "Currently the script does not support the $(uname -m) schema" && exit;;
esac
if [ ! -x "$(command -v bzip2)" ]; then
yellow "Please wait……"
if [[ $release = Centos && ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
cd
fi
if [ -x "$(command -v apt-get)" ]; then
apt update -y 
apt install bzip2 -y 
elif [ -x "$(command -v yum)" ]; then
yum update -y 
yum install epel-release -y
yum install bzip2 -y
elif [ -x "$(command -v dnf)" ]; then
dnf update -y 
dnf install bzip2 -y 
fi
fi
if [ -x "$(command -v bzip2)" ]; then
rm -rf sb.sh
wget -qN https://gitlab.com/rwkgyg/sing-box-yg/raw/main/1sb.sh || curl -sSfLO https://gitlab.com/rwkgyg/sing-box-yg/raw/main/1sb.sh
chmod +x 1sb.sh
mv 1sb.sh sb.sh
bash sb.sh
else
red "An error occurred when VPS updated dependencies. It is recommended to restart VPS. If the problem persists, it is recommended to replace the system and reinstall the VPS."
fi
