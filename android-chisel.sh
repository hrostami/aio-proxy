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


CHISEL_DIR="$HOME/chisel"
CONFIG_FILE="$CHISEL_DIR/config.json"
LATEST_VERSION=$(curl -sL https://github.com/jpillora/chisel/releases/latest | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | awk '{sub(/^v/, ""); print; exit}')



# Function to check if a package is installed
check_package() {
    command -v "$1" >/dev/null 2>&1
}

if ! check_package "proot"; then
    apt-get update
    pkg update
    clear
    pkg install proot -y
fi
# Install required packages if not already installed
if ! check_package "jq"; then
    pkg install jq -y
fi

if ! check_package "go" || ! check_package "golang"; then
    pkg install golang -y
fi

if [ -n "$(find "$CHISEL_DIR" -maxdepth 1 -type f -name 'chisel_*' -print -quit)" ]; then
    INSTALLED_VERSION=$(basename "$(find "$CHISEL_DIR" -maxdepth 1 -type f -name 'chisel_*' -print -quit)" | cut -d_ -f2)
    CHISEL_BIN="chisel_${INSTALLED_VERSION}_linux_arm64"
fi

INSTALL_CHISEL=0

if [ ! -d "$CHISEL_DIR" ]; then
    mkdir "$CHISEL_DIR" && cd "$CHISEL_DIR"
    INSTALL_CHISEL=1
else
    if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
        yellow "Updating chisel $INSTALLED_VERSION -> $LATEST_VERSION"
        
        if [ -f "$CHISEL_DIR/$CHISEL_BIN" ]; then
            rm "$CHISEL_DIR/$CHISEL_BIN" 
        fi
        INSTALL_CHISEL=1
    else
        :
    fi
fi

load_config() {
    SOCKS5_PORT=$(jq -r '.SOCKS5_PORT' $CONFIG_FILE)
    DOMAIN=$(jq -r '.DOMAIN' $CONFIG_FILE)
    echo
    echo "----------------Current Config-----------------"
    echo -e "${plain} Proxy Port:${yellow} $SOCKS5_PORT${plain}"
    echo -e "${plain} Domain:${yellow} $DOMAIN${plain}"
    echo "--------------------------------------------"
    echo
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

echo
white "---------------------------------------------"
echo
bblue "             █████╗ ██╗ ██████╗              "
bblue "            ██╔══██╗██║██╔═══██╗             "
bblue "            ███████║██║██║   ██║             "
bblue "            ██╔══██║██║██║   ██║             "
bblue "            ██║  ██║██║╚██████╔╝             "
bblue "            ╚═╝  ╚═╝╚═╝ ╚═════╝              "
bblue "           All-in-one Proxy Tool             "
white "              Created by Hosy                "
white "---------------------------------------------"
echo
cd "$CHISEL_DIR"
if [[ "$INSTALL_CHISEL" -eq '1' ]]; then
    yellow "Installing Chisel ver ($LATEST_VERSION)"
    curl -LO "https://github.com/jpillora/chisel/releases/download/v${LATEST_VERSION}/chisel_${LATEST_VERSION}_linux_arm64.gz"
    gunzip "chisel_${LATEST_VERSION}_linux_arm64.gz"
    chmod +x "chisel_${LATEST_VERSION}_linux_arm64"
else
    yellow "Chisel already latest version ($LATEST_VERSION)"
fi

get_user_input

green "Run Nekobox using these values:"
white "---------------------------------------------"
white "server: 127.0.0.1"
white "Remote Port: 5050"
white "---------------------------------------------"
"./chisel_${LATEST_VERSION}_linux_arm64" client "http://$DOMAIN" "5050:127.0.0.1:$SOCKS5_PORT"