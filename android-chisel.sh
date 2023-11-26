#!/bin/bash
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

CONFIG_FILE="config.json"
CHISEL_DIR="chisel"
LATEST_VERSION=$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')

apt-get update
pkg install curl -y 
pkg install jq -y
apt install go -y
pkg install golang -y

clear
termux-setup-storage

if [ ! -d "$CHISEL_DIR" ]; then
    mkdir "$CHISEL_DIR" && cd "$CHISEL_DIR"
else
    cd "$CHISEL_DIR"

curl -LO "https://github.com/jpillora/chisel/releases/download/v${LATEST_VERSION}/chisel_${LATEST_VERSION}_linux_arm64.gz"
gunzip "chisel_${LATEST_VERSION}_linux_arm64.gz"
chmod +x "chisel_${LATEST_VERSION}_linux_arm64"
termux-chroot

load_config() {
    SOCKS5_PORT=$(jq -r '.SOCKS5_PORT' $CONFIG_FILE)
    DOMAIN=$(jq -r '.DOMAIN' $CONFIG_FILE)
    echo "----------------Current Config-----------------"
    echo -e "${plain} Proxy Port:${yellow} $SOCKS5_PORT${plain}"
    echo -e "${plain} Domain:${yellow} $DOMAIN${plain}"
    echo "--------------------------------------------"
}
get_user_input() {
    if [ -f "$CONFIG_FILE" ]; then
        load_config
        readp "Do you want to change Chisel configuration? (y/n): " CHANGE_CONFIG
        if [ "$CHANGE_CONFIG" == "y" ]; then
            :
        else
            return
        fi
    else 
        SOCKS5_PORT=443
        DOMAIN="example.com"
    fi

    readp "Enter SOCKS5 port (default $SOCKS5_PORT): " USER_SOCKS5_PORT 
    SOCKS5_PORT=${USER_SOCKS5_PORT:-$SOCKS5_PORT}

    readp "Enter domain: " USER_DOMAIN
    DOMAIN=${USER_DOMAIN:-$DOMAIN}
    echo -e "{\n\"SOCKS5_PORT\": \"$SOCKS5_PORT\", \n\"DOMAIN\": \"$DOMAIN\"\n}" > "$CONFIG_FILE"
}
get_user_input

"./chisel_${LATEST_VERSION}_linux_arm64" client "http://$DOMAIN" "5050:127.0.0.1:$SOCKS5_PORT"