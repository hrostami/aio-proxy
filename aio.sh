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

# install requirements
if ! command -v qrencode &> /dev/null || ! command -v jq &> /dev/null || ! dpkg -l | grep -q net-tools; then
    sudo apt-get update
    if ! command -v qrencode &> /dev/null; then
        rred "qrencode is not installed. Installing..."
        sudo apt-get install qrencode -y

        # Check if installation was successful
        if [ $? -eq 0 ]; then
            red "qrencode is now installed."
        else
            red "Error: Failed to install qrencode."
        fi
    else
        green "qrencode is already installed."
    fi

    if ! command -v jq &> /dev/null; then
        rred "Installing jq..."
        if sudo apt-get install jq -y; then
            red "jq installed successfully."
        else
            red "Error: Failed to install jq."
            exit 1
        fi
    else
        green "jq is already installed."
    fi

    if ! dpkg -l | grep -q net-tools; then
        rred "net-tools is not installed. Installing..."
        sudo apt-get install net-tools -y

        # Check if installation was successful
        if [ $? -eq 0 ]; then
            red "net-tools is now installed."
        else
            red "Error: Failed to install net-tools."
            exit 1
        fi
    else
        green "net-tools is already installed."
    fi
else
    green "qrencode, jq, and net-tools are already installed."
fi

# ----------------------------------------Show Menus------------------------------------------------
display_main_menu() {
    clear 
    echo
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
    white " Github: https://github.com/hrostami"
    white " Twitter: https://twitter.com/hosy000"
    echo -e "${plain}Thank you ${red}iSegaro${plain} for all your efforts! "
    echo
    yellow "-------------------Protocols------------------"
    green "1. Chisel                2. Hysteria V2"
    echo
    green "3. Tuic                  4. Hiddify Reality Scanner"
    echo
    green "5. SSH                   6. 4 In 1 Script"
    echo
    yellow "---------------------Tools--------------------"
    green "7. Reverse TLS Tunnel    8. Install Panels"
    echo
    green "9. Warp                  10. Telegram Proxy"
    echo
    green "11. Show used Ports      12. Set Domains"
    echo
    rred "0. Exit"
    echo "----------------------------------------------"
}

display_chisel_menu() {
    clear
    echo "**********************************************"
    yellow "                Chisel Menu                 "
    echo "**********************************************"
    green "1. Server Setup"
    echo
    green "2. Android Setup"
    echo
    green "3. Windows Command"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_hysteria_v2_menu() {
    clear
    echo "**********************************************"
    yellow "               Hysteria V2 Menu               "
    echo "**********************************************"
    green "1. Install/Update"
    echo
    green "2. Change Parameters"
    echo
    green "3. Show Configs"
    echo
    green "4. Delete"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_tuic_menu() {
    clear
    echo "**********************************************"
    yellow "                   Tuic Menu                  "
    echo "**********************************************"
    green "1. Install/Update"
    echo
    green "2. Change Parameters"
    echo
    green "3. Show Configs"
    echo
    green "4. Delete"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_reality_menu() {
    clear
    white "---------------------------------------------"
    echo -e "${plain}The script for RealityEZPZ is created by ${yellow}@Aleskxyz${plain}"
    echo -e "Please check out and ${yellow}star ${plain}his Github repo"
    echo -e "${yellow}https://github.com/aleskxyz/reality-ezpz${plain}"
    white "---------------------------------------------"
    echo
    echo "**********************************************"
    yellow "                   Reality Menu                  "
    echo "**********************************************"
    green "1. Install tcp"
    echo
    green "2. Install grpc"
    echo
    green "3. Show Configs"
    echo
    green "4. Change Port"
    echo
    green "5. Change SNI"
    echo
    green "6. Delete"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_ssh_menu() {
    clear
    echo "**********************************************"
    yellow "                   SSH Menu                  "
    echo "**********************************************"
    green "1. Add user"
    echo
    green "2. Modify/Delete user"
    echo
    green "3. Show all users"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_install_panels_menu() {
    clear
    echo "**********************************************"
    yellow "                  Panels Menu                  "
    echo "**********************************************"
    green "1. X-UI Alireza"
    echo
    green "2. X-UI Sanaei"
    echo
    green "3. RealityEZPZ by Aleskxyz"
    echo
    green "4. Hiddify"
    echo
    green "5. Marzban"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_warp_menu() {
    clear
    echo "**********************************************"
    yellow "                  Warp Menu                  "
    echo "**********************************************"
    green "1. Install"
    echo
    green "2. Disable"
    echo
    green "3. Enable"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
    white "Getting current IPs, please wait..."
    IPV4=$(curl -s https://v4.ident.me)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to get IPv4 address"
            return
        fi

    IPV6=$(curl -s https://v6.ident.me)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get IPv6 address" 
        return
    fi
    if [[ $IPV4 == 104* ]]; then
        echo -e "${plain}IPv4:${green} $IPV4 [Warp]${plain}"
    else
        echo -e "${plain}IPv4:${red} $IPV4${plain}"
    fi

    echo -e "${plain}IPv6:${red} $IPV6${plain}"
    echo "**********************************************"
}

display_telegram_menu() {
    clear
    white "---------------------------------------------"
    echo -e "This part's script is created by ${yellow}@HirbodBehnam${plain}"
    echo -e "Please check out and ${yellow}star ${plain}his Github repo"
    echo -e "${yellow}https://github.com/HirbodBehnam/MTProtoProxyInstaller${plain}"
    white "---------------------------------------------"
    echo
    echo "**********************************************"
    yellow "                Telegram Menu                  "
    echo "**********************************************"
    green "1. Python(for 1 core/lowend servers)"
    echo
    green "2. Official Method"
    echo
    green "3. Golang"
    echo
    green "4. Erlang"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
}

display_domains_menu() {
    clear
    echo "**********************************************"
    yellow "                Domains Menu                  "
    echo "**********************************************"
    green "1. IPv4 Domain"
    echo
    green "2. IPv6 Domain"
    echo
    green "3. Cert + Nginx Setup"
    echo
    green "4. NAT Nginx Setup (get certs manually from Cloudflare)"
    echo
    green "0. Back to Main Menu"
    echo "**********************************************"
    echo -e "${plain}IPv4 Domain:${red} $IPV4_DOMAIN${plain}"
    echo -e "${plain}IPv6 Domain:${red} $IPV6_DOMAIN${plain}"
    echo "**********************************************"
}
# ----------------------------------------Chisel Tunnel stuff----------------------------------------------
chisel_tunnel_setup() {

    install_chisel_termux() {
        apt-get update
        pkg install wget
        apt install go
        pkg install golang
        termux-setup-storage
        mkdir chisel && cd chisel
        wget "https://github.com/jpillora/chisel/releases/download/v${LATEST_VERSION}/chisel_${LATEST_VERSION}_linux_arm64.gz"
        gunzip "chisel_${LATEST_VERSION}_linux_arm64.gz"
        chmod +x "chisel_${LATEST_VERSION}_linux_arm64"
        termux-chroot

        read -p "Enter port number: " USER_PORT
        PORT=${USER_PORT:-5050}

        read -p "Enter domain: " USER_DOMAIN
        DOMAIN=${USER_DOMAIN:-example.com}

        "./chisel_${LATEST_VERSION}_linux_arm64" client "http://$DOMAIN" "$USER_PORT:127.0.0.1:$SOCKS5_PORT"
    }

    install_chisel() {
        mkdir -p "$CHISEL_DIR"
        cd "$CHISEL_DIR"

        wget "https://github.com/jpillora/chisel/releases/download/v${LATEST_VERSION}/${CHISEL_BIN}.gz"
        gunzip "$CHISEL_BIN".gz
        chmod +x "$CHISEL_BIN"
    }

    stop_chisel() {
        CHISEL_PID=$(pgrep -f "chisel_$INSTALLED_VERSION")  

        if [ -n "$CHISEL_PID" ]; then
            echo "Stopping chisel server (PID $CHISEL_PID)"   
            kill "$CHISEL_PID" 
        else
            echo "Chisel server not running"
        fi
    }

    update_chisel() {
        if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
            stop_chisel
            echo "Updating chisel $INSTALLED_VERSION -> $LATEST_VERSION"
            
            if [ -f "$CHISEL_DIR/$CHISEL_BIN" ]; then
                rm "$CHISEL_DIR/$CHISEL_BIN" 
            fi
            
            install_chisel
        else
            echo "Chisel already latest version ($LATEST_VERSION)"
        fi
    }

    load_config() {
        PORT=$(jq -r '.PORT' $CONFIG_FILE)
        SOCKS5_PORT=$(jq -r '.SOCKS5_PORT' $CONFIG_FILE)
        DOMAIN=$(jq -r '.DOMAIN' $CONFIG_FILE)
        echo "Current config:"
        echo "Port: $PORT"
        echo "SOCKS5 Port: $SOCKS5_PORT"
        echo "Domain: $DOMAIN"
    }

    get_user_input() {
        if [ -f "$CONFIG_FILE" ]; then
            read -p "Do you want to change Chisel configuration? (y/n): " CHANGE_CONFIG
            if [ "$CHANGE_CONFIG" == "y" ]; then
                load_config
            else
                break
            fi
        else 
            PORT=80
            SOCKS5_PORT=443
            DOMAIN="example.com"
        fi
        read -p "Enter port (default $PORT): " USER_PORT
        PORT=${USER_PORT:-$PORT}

        read -p "Enter SOCKS5 port (default $SOCKS5_PORT): " USER_SOCKS5_PORT 
        SOCKS5_PORT=${USER_SOCKS5_PORT:-$SOCKS5_PORT}

        read -p "Enter domain: " USER_DOMAIN
        DOMAIN=${USER_DOMAIN:-$DOMAIN}
        echo -e "{\n\"PORT\": \"$PORT\", \n\"SOCKS5_PORT\": \"$SOCKS5_PORT\", \n\"DOMAIN\": \"$DOMAIN\"\n}" > "$CONFIG_FILE"
    }

    start_chisel() {
        load_config
        tmux new-session -d "./$CHISEL_DIR/$CHISEL_BIN" server --port "$PORT" --socks5 "$SOCKS5_PORT" --proxy "http://$DOMAIN" -v  
    }

    CONFIG_FILE="/etc/chisel/config.json"
    CHISEL_DIR="/etc/chisel"

    UNAME_M=$(uname -m)

    case ${UNAME_M} in
        x86_64)
            ARCH=amd64
            ;;
        aarch64)  
            ARCH=arm64  
            ;; 
        armv*)  
            ARCH=${UNAME_M}     
            ;;  
        *)  
            ARCH=amd64
    esac

    LATEST_VERSION=$(curl -s https://api.github.com/repos/jpillora/chisel/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
    CHISEL_BIN="chisel_${LATEST_VERSION}_linux_${ARCH}"

    if [ -f "$CHISEL_DIR/$CHISEL_BIN" ]; then
        INSTALLED_VERSION=$(echo $CHISEL_BIN | cut -d_ -f2)
    fi 

    if [ -n "$ANDROID_ROOT" ]; then
        install_chisel_termux
    else
        if [ -f "$CONFIG_FILE" ]; then
            load_config
            get_user_input
        else 
            get_user_input
            echo -e "{\n\"PORT\": \"$PORT\", \n\"SOCKS5_PORT\": \"$SOCKS5_PORT\", \n\"DOMAIN\": \"$DOMAIN\"\n}" > "$CONFIG_FILE"
        fi

        if [ ! -d "$CHISEL_DIR" ]; then
            install_chisel
        fi

        if pgrep -f "chisel_$INSTALLED_VERSION" > /dev/null; then
            read -p "Chisel is already running. Do you want to: (s)top/(c)hange config/(u)pdate Chisel? " USER_CHOICE
            case $USER_CHOICE in
                s)
                    stop_chisel
                    ;;
                c)
                    get_user_input
                    ;;
                u)
                    update_chisel
                    ;;
                *)
                    echo "Invalid choice. Exiting."
                    exit 1
                    ;;
            esac
        else
            update_chisel
            start_chisel
            echo "Chisel is now running with config:"
            echo "Port: $PORT"
            echo "SOCKS5 Port: $SOCKS5_PORT"
            echo "Domain: $DOMAIN"
            echo "To connect on Windows run:"
            echo "chisel.exe client http://$DOMAIN 127.0.0.1:$PORT:127.0.0.1:$SOCKS5_PORT"
        fi
    fi

}


# ----------------------------------------Hysteria V2 stuff------------------------------------------------
run_hysteria_v2_setup() {
    clear
    echo "Running Hysteria v2 Setup..."
    sleep 2
    #!/bin/bash

    apt-get update 

    apt-get install wget nano -y

    apt-get install net-tools -y

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy2"
    else
        user_directory="/home/$USER/hy2"
    fi

    if [ -d "$user_directory" ]; then
        clear
        echo "--------------------------------------------------------------------------------"
        echo -e "\e[1;33mHysteria directory already exists. Checking for latest version..\e[0m"
        echo "--------------------------------------------------------------------------------"
        sleep 2

        if [ -f "$user_directory/config.json" ]; then
            port=$(jq -r '.listen' <<< "$(< "$user_directory/config.json")" | cut -c 2-)
            password=$(jq -r '.obfs.salamander.password' <<< "$(< "$user_directory/config.json")")

        else
            echo "Error: config.json file not found in Hysteria directory."
            return
        fi
    else
        readp "Enter the listening port: " port
        readp "Enter the obfuscation password: " password

        mkdir -p "$user_directory"
        cd "$user_directory"

    cat << EOF > "$user_directory/config.json"
    {
    "listen": ":$port",
    "tls": {
        "cert": "$user_directory/ca.crt",
        "key": "$user_directory/ca.key"
    },
    "obfs": {
        "type": "salamander",
        "salamander": {
        "password": "$password"
        }
    },
    "auth": {
        "type": "password",
        "password": "$password"
    },
    "quic": {
        "initStreamReceiveWindow": 8388608,
        "maxStreamReceiveWindow": 8388608,
        "initConnReceiveWindow": 20971520,
        "maxConnReceiveWindow": 20971520,
        "maxIdleTimeout": "60s",
        "maxIncomingStreams": 1024,
        "disablePathMTUDiscovery": false
    },
    "bandwidth": {
        "up": "1 gbps",
        "down": "1 gbps"
    },
    "ignoreClientBandwidth": false,
    "disableUDP": false,
    "udpIdleTimeout": "60s",
    "resolver": {
        "type": "udp",
        "tcp": {
        "addr": "8.8.8.8:53",
        "timeout": "4s"
        },
        "udp": {
        "addr": "8.8.4.4:53",
        "timeout": "4s"
        },
        "tls": {
        "addr": "1.1.1.1:853",
        "timeout": "10s",
        "sni": "cloudflare-dns.com",
        "insecure": false
        },
        "https": {
        "addr": "1.1.1.1:443",
        "timeout": "10s",
        "sni": "cloudflare-dns.com",
        "insecure": false
        }
    }
    }
EOF
    fi

    latest_version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    echo -e "\e[1;33m---> Installing hysteria ver $latest_version\e[0m"
    echo "--------------------------------------------------------------------------------"
    sleep 2

    rm hysteria-linux-amd64

    architecture=$(uname -m)
    if [ "$architecture" = "x86_64" ]; then
        wget "https://github.com/apernet/hysteria/releases/download/$latest_version/hysteria-linux-amd64"
    else
        wget "https://github.com/apernet/hysteria/releases/download/$latest_version/hysteria-linux-arm"
        mv hysteria-linux-arm hysteria-linux-amd64
    fi

    chmod 755 hysteria-linux-amd64

    if [ ! -f "$user_directory/ca.key" ] || [ ! -f "$user_directory/ca.crt" ]; then
        openssl ecparam -genkey -name prime256v1 -out "$user_directory/ca.key"
        openssl req -new -x509 -days 36500 -key "$user_directory/ca.key" -out "$user_directory/ca.crt" -subj "/CN=bing.com"
    fi

    if [ ! -f "/etc/systemd/system/hy2.service" ]; then
        cat << EOF > /etc/systemd/system/hy2.service
        [Unit]
        After=network.target nss-lookup.target

        [Service]
        User=root
        WorkingDirectory=$user_directory
        CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
        AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
        ExecStart=$user_directory/hysteria-linux-amd64 -c $user_directory/config.json server
        ExecReload=/bin/kill -HUP $MAINPID
        Restart=always
        RestartSec=5
        LimitNOFILE=infinity

        [Install]
        WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable hy2
    fi


    systemctl restart hy2
}
change_hy2_parameters() {
    local user_directory

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy2"
    else
        user_directory="/home/$USER/hy2"
    fi

    if [ -d "$user_directory" ]; then
        echo "Hysteria directory exists. You can change parameters here."
        port=$(jq -r '.listen' "$user_directory/config.json" | cut -c 2-)
        password=$(jq -r '.obfs.salamander.password' "$user_directory/config.json")
        readp "Enter a new listening port [$port]: " new_port
        readp "Enter a new obfuscation password [$password]: " new_password
        jq ".listen = \":${new_port:-$port}\" | .obfs.salamander.password = \"$new_password\"" "$user_directory/config.json" > tmp_config.json
        mv tmp_config.json "$user_directory/config.json"
        systemctl restart hy2
        echo "Parameters updated successfully."
    else
        echo "Hysteria directory does not exist. Please install Hysteria first."
    fi

}
show_hy2_configs() {
    local user_directory

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy2"
    else
        user_directory="/home/$USER/hy2"
    fi

    if [ -d "$user_directory" ]; then
        echo "Hysteria directory exists. Here are the current configurations:"
        password=$(jq -r '.obfs.salamander.password' "$user_directory/config.json")
        port=$(jq -r '.listen' "$user_directory/config.json" | cut -c 2-)
        
        systemctl stop wg-quick@wgcf

        if [ -z "$IPV4_DOMAIN" ]; then
            IPV4=$(curl -s https://v4.ident.me)
        else
            IPV4="$IPV4_DOMAIN"
        fi

        if [ -z "$IPV6_DOMAIN" ]; then
            IPV6=$(curl -s https://v6.ident.me)
        else
            IPV6="$IPV6_DOMAIN"
        fi

        systemctl restart wg-quick@wgcf

        v2rayN_config="server: $IPV6:$port
        auth: $password
        transport:
        type: udp
        udp:
            hopInterval: 30s
        obfs:
        type: salamander
        salamander:
            password: $password
        tls:
        sni: google.com
        insecure: true
        bandwidth:
        up: 100 mbps
        down: 100 mbps
        quic:
        initStreamReceiveWindow: 8388608
        maxStreamReceiveWindow: 8388608
        initConnReceiveWindow: 20971520
        maxConnReceiveWindow: 20971520
        maxIdleTimeout: 30s
        keepAlivePeriod: 10s
        disablePathMTUDiscovery: false
        fastOpen: true
        lazy: true
        socks5:
        listen: 127.0.0.1:10808
        http:
        listen: 127.0.0.1:10809"

        IPV4_URL="hysteria2://$password@$IPV4:$port/?insecure=1&obfs=salamander&obfs-password=$password&sni=google.com#HysteriaV2 IPv4"
        IPV6_URL="hysteria2://$password@[$IPV6]:$port/?insecure=1&obfs=salamander&obfs-password=$password&sni=google.com#HysteriaV2 IPv6"

        echo "----------------config info-----------------"
        echo -e "\e[1;33mPassword: $password\e[0m"
        echo "--------------------------------------------"
        echo
        echo "----------------IP and Port-----------------"
        echo -e "\e[1;33mPort: $port\e[0m"
        echo -e "\e[1;33mIPv4: $IPV4\e[0m"
        echo -e "\e[1;33mIPv6: $IPV6\e[0m"
        echo "--------------------------------------------"
        echo
        echo "----------------V2rayN Config IPv6-----------------"
        echo -e "\e[1;33m$v2rayN_config\e[0m"
        echo "--------------------------------------------"
        echo
        echo "----------------Nekobox Config IPv4-----------------"
        echo -e "\e[1;33m$IPV4_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV4_URL"
        echo "--------------------------------------------"
        echo
        echo "-----------------Nekobox Config IPv6----------------"
        echo -e "\e[1;33m$IPV6_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV6_URL"
        echo "--------------------------------------------"
    else
        echo "Hysteria directory does not exist. Please install Hysteria first."
    fi

    readp "Press Enter to continue..."
}
delete_hysteria_v2() {
    clear
    echo "Deleting Hysteria v2 Proxy..."
    sleep 2
    rm -r ~/hy2
    systemctl stop hy2
    systemctl disable hy2
    readp "Press Enter to continue..."
}

# ----------------------------------------TUIC stuff------------------------------------------------
run_tuic_setup() {
    clear
    echo "Running Tuic Setup..."
    sleep 2
    #!/bin/bash

    # Determine the appropriate TUIC_FOLDER based on the user
    if [ "$EUID" -eq 0 ]; then
        TUIC_FOLDER="/root/tuic"
        WORKING_DIR="/root"
    else
        TUIC_FOLDER="$HOME/tuic"
        WORKING_DIR="$HOME"
    fi

    CONFIG_FILE="$TUIC_FOLDER/config.json"

    # Detect server architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        TUIC_ARCH="x86_64-unknown-linux-gnu"
    elif [ "$ARCH" = "aarch64" ]; then
        TUIC_ARCH="aarch64-unknown-linux-gnu"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    # Fetch all releases from the GitHub API
    ALL_VERSIONS=$(curl -s "https://api.github.com/repos/EAimTY/tuic/releases" | jq -r '.[].tag_name')

    # Find the latest TUIC server version
    LATEST_SERVER_VERSION=""
    for VERSION in $ALL_VERSIONS; do
        if [[ "$VERSION" == *"tuic-server-"* && "$VERSION" =~ ^tuic-server-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            LATEST_SERVER_VERSION=$VERSION
            break
        fi
    done

    if [ -z "$LATEST_SERVER_VERSION" ]; then
        echo "No TUIC server version found in GitHub releases."
        exit 1
    fi

    # Construct the URL for the latest TUIC server binary
    TUIC_URL="https://github.com/EAimTY/tuic/releases/download/$LATEST_SERVER_VERSION/$LATEST_SERVER_VERSION-$TUIC_ARCH"

    # Check if TUIC directory exists
    if [ -d "$TUIC_FOLDER" ]; then
        systemctl stop tuic
        clear
        echo "--------------------------------------------------------------------------------"
        echo -e "\e[1;33m TUIC directory already exists. Checking for latest version..\e[0m"
        echo "--------------------------------------------------------------------------------"
        sleep 2
        # Directory exists, download the latest version of TUIC
        cd "$TUIC_FOLDER"

        echo -e "\e[1;33m---> Installing $LATEST_SERVER_VERSION\e[0m"
        echo "--------------------------------------------------------------------------------"
        sleep 2

        # Construct the URL for the latest TUIC server binary
        TUIC_URL="https://github.com/EAimTY/tuic/releases/download/$LATEST_SERVER_VERSION/$LATEST_SERVER_VERSION-$TUIC_ARCH"

        # Download the latest TUIC server binary
        wget -O tuic-server "$TUIC_URL"
        chmod 755 tuic-server

        # Get password, port, and congestion from config file
        PORT=$(jq -r '.server' "$CONFIG_FILE" | awk -F ':' '{print $NF}')
        CONGESTION_CONTROL=$(jq -r '.congestion_control' "$CONFIG_FILE")
        UUID=$(jq -r '.users | keys[0]' "$CONFIG_FILE")
        PASSWORD=$(jq -r ".users[\"$UUID\"]" "$CONFIG_FILE")

        # Restart the service
        systemctl restart tuic

    else
        # Update packages
        apt update
        apt install nano net-tools uuid-runtime wget openssl -y

        # Create TUIC directory and navigate to it
        mkdir -p "$TUIC_FOLDER"
        cd "$TUIC_FOLDER"

        
        # Download the latest TUIC server binary
        clear
        echo "--------------------------------------------------------------------------------"
        echo -e "\e[1;33m---> Installing $LATEST_SERVER_VERSION\e[0m"
        echo "--------------------------------------------------------------------------------"
        sleep 2

        wget -O tuic-server "$TUIC_URL"
        chmod 755 tuic-server

        # Generate certificate
        openssl ecparam -genkey -name prime256v1 -out "$TUIC_FOLDER/ca.key"
        openssl req -new -x509 -days 36500 -key "$TUIC_FOLDER/ca.key" -out "$TUIC_FOLDER/ca.crt" -subj "/CN=bing.com"

        # Generate random UUID
        UUID=$(uuidgen)

        # Prompt for port
        readp "Enter port number: " PORT

        # Prompt for password
        readp "Enter a password for the server: " PASSWORD

        # Prompt for congestion control
        OPTIONS=("cubic" "new_reno" "bbr")
        PS3='Select congestion control: '
        select OPT in "${OPTIONS[@]}"
        do
            CONGESTION_CONTROL=$OPT
            break
        done

        # Create config file
        cat <<EOF >"$CONFIG_FILE"
        {
        "server": "[::]:$PORT",
        "users": {
        "${UUID}": "$PASSWORD"
        },
        "certificate": "$TUIC_FOLDER/ca.crt",
        "private_key": "$TUIC_FOLDER/ca.key",
        "congestion_control": "$CONGESTION_CONTROL",
        "alpn": ["h3", "spdy/3.1"],
        "udp_relay_ipv6": true,
        "zero_rtt_handshake": false,
        "dual_stack": true,
        "auth_timeout": "3s",
        "task_negotiation_timeout": "3s",
        "max_idle_time": "10s",
        "max_external_packet_size": 1500,
        "send_window": 16777216,
        "receive_window": 8388608,
        "gc_interval": "3s",
        "gc_lifetime": "15s",
        "log_level": "warn"
        }
EOF

        # Determine the user for the service
        SERVICE_USER="root"
        if [ "$EUID" -ne 0 ]; then
            SERVICE_USER="$USER"
        fi

        cat <<EOF > /etc/systemd/system/tuic.service
        [Unit]
        Description=tuic service
        After=network.target nss-lookup.target

        [Service]
        User=$SERVICE_USER
        WorkingDirectory=$WORKING_DIR
        CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
        AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
        ExecStart=$WORKING_DIR/tuic/tuic-server -c $WORKING_DIR/tuic/config.json
        Restart=on-failure
        RestartSec=10
        LimitNOFILE=infinity

        [Install]
        WantedBy=multi-user.target
EOF


        # Reload and start service
        systemctl daemon-reload
        systemctl enable tuic
        systemctl start tuic


    fi
}
show_tuic_configs() {
    local TUIC_FOLDER
    local CONFIG_FILE
    
    if [ "$EUID" -eq 0 ]; then
        TUIC_FOLDER="/root/tuic"
    else
        TUIC_FOLDER="$HOME/tuic"
    fi
    
    CONFIG_FILE="$TUIC_FOLDER/config.json"

    if [ -d "$TUIC_FOLDER" ]; then
        echo "Here are the current configurations:"
        
        PORT=$(jq -r '.server' "$CONFIG_FILE" | awk -F ':' '{print $NF}')
        CONGESTION_CONTROL=$(jq -r '.congestion_control' "$CONFIG_FILE")
        UUID=$(jq -r '.users | keys[0]' "$CONFIG_FILE")
        PASSWORD=$(jq -r ".users[\"$UUID\"]" "$CONFIG_FILE")

        systemctl stop wg-quick@wgcf

        if [ -z "$IPV4_DOMAIN" ]; then
            IPV4=$(curl -s https://v4.ident.me)
        else
            IPV4="$IPV4_DOMAIN"
        fi

        if [ -z "$IPV6_DOMAIN" ]; then
            IPV6=$(curl -s https://v6.ident.me)
        else
            IPV6="$IPV6_DOMAIN"
        fi

        systemctl restart wg-quick@wgcf

        IPV4_URL="tuic://$UUID:$PASSWORD@$IPV4:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3,spdy/3.1&allow_insecure=1#Tuic IPv4"

        IPV6_URL="tuic://$UUID:$PASSWORD@[$IPV6]:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3,spdy/3.1&allow_insecure=1#Tuic IPv6"

        echo "----------------config info-----------------"
        echo -e "\e[1;33mUUID: $UUID\e[0m"
        echo -e "\e[1;33mPassword: $PASSWORD\e[0m"
        echo "--------------------------------------------"
        echo
        echo "----------------IP and Port-----------------"
        echo -e "\e[1;33mPort: $PORT\e[0m"
        echo -e "\e[1;33mIPv4: $IPV4\e[0m"
        echo -e "\e[1;33mIPv6: $IPV6\e[0m"
        echo "--------------------------------------------"
        echo
        echo "----------------Tuic Config IPv4-----------------"
        echo -e "\e[1;33m$IPV4_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV4_URL"
        echo "--------------------------------------------"
        echo
        echo "-----------------Tuic Config IPv6----------------"
        echo -e "\e[1;33m$IPV6_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV6_URL"
        echo "--------------------------------------------"
    else
        echo "TUIC directory does not exist. Please install TUIC first."
    fi
    readp "Press Enter to continue..."
}
change_tuic_parameters() {
    local TUIC_FOLDER
    local CONFIG_FILE
    
    if [ "$EUID" -eq 0 ]; then
        TUIC_FOLDER="/root/tuic"
    else
        TUIC_FOLDER="$HOME/tuic"
    fi
    
    CONFIG_FILE="$TUIC_FOLDER/config.json"

    if [ -d "$TUIC_FOLDER" ]; then
        echo "TUIC directory exists. You can change parameters here."
        
        PORT=$(jq -r '.server' "$CONFIG_FILE" | awk -F ':' '{print $NF}')
        CONGESTION_CONTROL=$(jq -r '.congestion_control' "$CONFIG_FILE")
        UUID=$(jq -r '.users | keys[0]' "$CONFIG_FILE")
        PASSWORD=$(jq -r ".users[\"$UUID\"]" "$CONFIG_FILE")
        
        readp "Enter a new port number [$PORT]: " NEW_PORT
        readp "Enter a new congestion control [$CONGESTION_CONTROL]: " NEW_CONGESTION
        readp "Enter a new password [$PASSWORD]: " NEW_PASSWORD
        
        jq ".server = \"[::]:${NEW_PORT:-$PORT}\" | .congestion_control = \"${NEW_CONGESTION:-$CONGESTION_CONTROL}\" | .users[\"$UUID\"] = \"${NEW_PASSWORD:-$PASSWORD}\"" "$CONFIG_FILE" > tmp_config.json
        mv tmp_config.json "$CONFIG_FILE"
        
        echo "Parameters updated successfully."
        systemctl restart tuic
    else
        echo "TUIC directory does not exist. Please install TUIC first."
    fi
}
delete_tuic() {
    clear
    echo "Deleting Tuic Proxy..."
    sleep 2
    rm -r ~/tuic
    systemctl stop tuic
    systemctl disable tuic
    readp "Press Enter to continue..."
}

# ----------------------------------------SSH stuff------------------------------------------------
contains_substring() {
    string="$1"
    substring="$2"
    if [[ "$string" == *"$substring"* ]]; then
        return 0
    else
        return 1
    fi
}

add_or_modify_line() {
    file="$1"
    line="$2"

    # Check if the line already exists
    if grep -q "^$line" "$file"; then
        # Modify the line if it exists
        sudo sed -i "/^$line/c $line" "$file"
        echo "Modified line in $file"
    else
        # Add the line if it doesn't exist
        echo "$line" | sudo tee -a "$file" > /dev/null
        echo "Added line to $file"
    fi
}

add_ssh_user() {
    read -p "Enter the username: " username
    read -s -p "Enter the password: " password
    echo
    read -p "Enter the SSH port (press Enter to use default 22): " port

    if [ -z "$port" ]; then
        port=22
    fi

    sudo useradd "$username" -M -s /bin/false
    echo "$username:$password" | sudo chpasswd

    sshd_config_file="/etc/ssh/sshd_config"
    if ! contains_substring "$(jq -c . /etc/ssh/sshd_config)" "port $port"; then
        add_or_modify_line "$sshd_config_file" "port $port"
    fi

    allow_users_line="Match User $username Address *:$port"
    add_or_modify_line "$sshd_config_file" "$allow_users_line"

    sudo systemctl restart ssh

    echo "Configuration completed and SSH service restarted."

}

modify_delete_ssh_user() {

    read -p "Enter the username: " username

    user_exists=$(getent passwd "$username")
    if [ -z "$user_exists" ]; then
        echo
        red "User not found."
        echo
        return
    fi

    sshd_config_file="/etc/ssh/sshd_config"

    if [ -z "$port" ]; then
        port_from_config=$(grep -Eo "Match User $username Address \*:(\d+)" "$sshd_config_file" | grep -Eo "\d+")
        port=${port_from_config:-22}
    fi
    yellow "Port from config= $port"
    sudo sed -i "/Match User $username Address/d" "$sshd_config_file"
    sudo sed -i "/port $port/d" "$sshd_config_file"
    echo
    rred "Select an option:"
    green "1) Modify user"
    green "2) Delete user"
    readp "Enter your choice: " choice

    case "$choice" in
        1)  # Modify user
            read -s -p "Enter the new password: " password
            echo
            read -p "Enter the new SSH port (press Enter to keep current port): " port

            if [ -z "$port" ]; then
                port=22
            fi

            sudo usermod -p "$(echo "$password" | openssl passwd -1 -stdin)" "$username"

            allow_users_line="Match User $username Address *:$port"
            add_or_modify_line "$sshd_config_file" "port $port"
            add_or_modify_line "$sshd_config_file" "$allow_users_line"

            sudo systemctl restart ssh

            echo "User modified and SSH service restarted."
            ;;

        2)  # Delete user
            sudo userdel -r "$username"
            red "User deleted."
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac

}


# ----------------------------------------Tunnel stuff------------------------------------------------
run_tunnel_setup() {
    clear
    echo "Running Tunnel Setup..."
    bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/ReverseTlsTunnel/main/RtTunnel.sh)
    sleep 2
    readp "Press Enter to continue..."
}

# ----------------------------------------Install Panels stuff------------------------------------------------
install_x_ui_alireza() {
    clear
    echo "Installing X-UI Alireza..."
    sleep 2
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    readp "Press Enter to continue..."
}

install_x_ui_sanaei() {
    clear
    echo "Installing X-UI Sanaei..."
    sleep 2
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    readp "Press Enter to continue..."
}

install_reality_ezpz() {
    clear
    echo "Installing RealityEZPZ by Aleskxyz..."
    sleep 2
    bash <(curl -sL https://raw.githubusercontent.com/aleskxyz/reality-ezpz/master/reality-ezpz.sh) -m
    readp "Press Enter to continue..."
}

install_hiddify() {
    clear
    echo "Installing Hiddify..."
    sudo apt update&&sudo apt install curl&& sudo bash -c "$(curl -Lfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
    sleep 2
    readp "Press Enter to continue..."
}
install_marzban() {
    clear
    echo "Installing Marzban..."
    sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install
    sleep 2
    readp "Press Enter to continue..."
}
# ----------------------------------------Warp stuff------------------------------------------------
install_warp() {
    echo "Installing Warp..."
    bash <(curl -sL https://raw.githubusercontent.com/hrostami/aio-proxy/master/warp.sh)
    readp "Press Enter to continue..."
}

disable_warp() {
    echo "Disabling Warp..."
    systemctl stop wg-quick@wgcf
    readp "Press Enter to continue..."
}

enable_warp() {
    echo "Enabling Warp..."
    systemctl restart wg-quick@wgcf
    readp "Press Enter to continue..."
}

# ----------------------------------------Domains stuff------------------------------------------------
setup_ipv4_domain() {
    if [ -z "$IPV4_DOMAIN" ]; then
        rred "IPV4_DOMAIN is not set."
        echo "Please enter the new domain:"
        read -r DOMAIN
        export IPV4_DOMAIN=$DOMAIN
        if grep -q "export IPV4_DOMAIN" ~/.bashrc; then
            echo "IPV4_DOMAIN is set in ~/.bashrc. Updating the value..."
            sed -i "s/export IPV4_DOMAIN=.*/export IPV4_DOMAIN=$DOMAIN/" ~/.bashrc
            source ~/.bashrc
        else
            echo "IPV4_DOMAIN is not set in ~/.bashrc. Adding the export command..."
            echo -e "export IPV4_DOMAIN=$DOMAIN" >> ~/.bashrc
            source ~/.bashrc
        fi
        echo -e "IPV4_DOMAIN updated to:${yellow} $IPV4_DOMAIN${plain}"
    else
        echo "Current value of IPV4_DOMAIN is: $DOMAIN"
        read -p "Do you want to change the domain? (y/n): " choice
        if [[ $choice =~ ^[Yy] ]]; then
            echo "Please enter the new domain:"
            read -r DOMAIN
            export IPV4_DOMAIN=$DOMAIN
            sed -i "s/export IPV4_DOMAIN=.*/export IPV4_DOMAIN=$IPV4_DOMAIN/" ~/.bashrc
            source ~/.bashrc
            echo -e "IPV4_DOMAIN updated to:${yellow} $IPV4_DOMAIN${plain}"
        else
            echo "IPV4_DOMAIN remains unchanged."
        fi
    fi
    readp "Press Enter to continue..."
    
}

setup_ipv6_domain() {
    if [ -z "$IPV6_DOMAIN" ]; then
        rred "IPV6_DOMAIN is not set."
        echo "Please enter the new domain:"
        read -r DOMAIN
        export IPV6_DOMAIN=$DOMAIN
        if grep -q "export IPV6_DOMAIN" ~/.bashrc; then
            echo "IPV6_DOMAIN is set in ~/.bashrc. Updating the value..."
            sed -i "s/export IPV6_DOMAIN=.*/export IPV6_DOMAIN=$DOMAIN/" ~/.bashrc
            source ~/.bashrc
        else
            echo "IPV6_DOMAIN is not set in ~/.bashrc. Adding the export command..."
            echo -e "export IPV6_DOMAIN=$DOMAIN" >> ~/.bashrc
            source ~/.bashrc
        fi
        echo -e "IPV6_DOMAIN updated to:${yellow} $IPV6_DOMAIN${plain}"
    else
        echo "Current value of IPV6_DOMAIN is: $DOMAIN"
        read -p "Do you want to change the domain? (y/n): " choice
        if [[ $choice =~ ^[Yy] ]]; then
            echo "Please enter the new domain:"
            read -r DOMAIN
            export IPV6_DOMAIN=$DOMAIN
            sed -i "s/export IPV6_DOMAIN=.*/export IPV6_DOMAIN=$IPV6_DOMAIN/" ~/.bashrc
            source ~/.bashrc
            echo -e "IPV6_DOMAIN updated to:${yellow} $IPV6_DOMAIN${plain}"
        else
            echo "IPV6_DOMAIN remains unchanged."
        fi
    fi
    readp "Press Enter to continue..."
}

setup_cert() {
    if [ -z "$IPV4_DOMAIN" ]; then
       rred "IPv4 Domain is not set. Please set it first using option 1 in Domains menu."
       return
    else
        source ~/.bashrc
        # Install Certbot
        sudo apt-get update
        clear
        yellow "Installing Certbot..."
        sudo apt-get install -y certbot python3-certbot-nginx
        sudo apt install ufw -y
        sudo ufw enable
        sudo ufw allow ssh

        # Ensure Nginx is installed and set up
        if ! command -v nginx &> /dev/null; then            
            sudo apt-get install -y nginx
            sudo systemctl enable nginx
            echo "Nginx installed."
            sleep 2
        fi
        
        sudo ufw allow 'Nginx HTTPS'
        sudo ufw allow 'Nginx HTTP'
        
        # Prompt user for HTTPS port
        clear

        sudo systemctl stop nginx

        readp "Enter your email: " email
        # Request SSL certificate using Certbot and specify the chosen port
        sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email "$email" -d "$IPV4_DOMAIN"

        sudo ufw delete allow 'Nginx HTTP'
        
        sudo systemctl start nginx

        your_domain="$IPV4_DOMAIN"

        sudo mkdir -p /var/www/$your_domain/html

        html_content=$(cat <<EOF
        <html><head>
        <title>AIO by Hosy</title>
        <style>
            .banner {
                text-align: center;
                padding: 5px;
                font-size: 169px;
                color: lightblue;
                padding-bottom: 0;
            }
            .created-by {
                text-align: center;
                color: lightblue;
                font-size: 18px;
                margin-bottom: 40px;
            }
            .link {
            display: block;
            color: gold;
            text-align: center;
            font-size: 18px;
            margin-top: 10px;
            text-decoration: none;
            }
            .link:hover {
            text-decoration: underline;
            }
        </style>
        </head>
        <body style="
            background-color: #03031f;
        ">
        <div class="banner">
            AIO
        </div>
        <div class="created-by">
            Created by Hosy
        </div>
        <a href="https://github.com/hrostami" class="link" target="_blank">
            Github: github.com/hrostami
        </a>
        <a href="https://twitter.com/hosy000" class="link" target="_blank">
            Twitter: twitter.com/hosy000
        </a>


        </body></html>
EOF
        )

        echo "$html_content" | sudo tee /var/www/$your_domain/html/index.html > /dev/null

        nginx_conf=$(cat <<EOF
        server {
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name $your_domain;
        ssl_certificate /etc/letsencrypt/live/$your_domain/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$your_domain/privkey.pem;
        
        root /var/www/$your_domain/html;
        index index.html index.htm;
        }

EOF
        )

        # Write Nginx server block configuration to file
        echo "$nginx_conf" | sudo tee /etc/nginx/sites-available/$your_domain > /dev/null

        # Enable the Nginx server block
        sudo ln -s /etc/nginx/sites-available/$your_domain /etc/nginx/sites-enabled/

        # Test the Nginx configuration and restart Nginx
        sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default_disabled
        sudo service apache2 stop
        sudo nginx -t
        sudo systemctl restart nginx
        sudo nginx -s reload

        green "Nginx configured to use HTTPS for $IPV4_DOMAIN."
    fi
    readp "Press Enter to continue..."
}

setup_nginx_nat() {
    if [ -z "$IPV4_DOMAIN" ] && [ ! -f "/etc/letsencrypt/live/$IPV4_DOMAIN/fullchain.pem" ]; then
        rred "IPv4 Domain is not set. Please set it first using option 1 in Domains menu."
        echo
        yellow "Please get the certificate and key from Cloudflare and use the commands below: "
        echo
        white "Command for certficate: "
        yellow "nano /etc/letsencrypt/live/$your_domain/fullchain.pem"
        echo
        white "Command for Key: "
        yellow "nano /etc/letsencrypt/live/$your_domain/privkey.pem"
        echo
        readp "Press Enter to continue..."
        return
    else
        source ~/.bashrc
        sudo apt-get update
        clear
        sudo apt install ufw -y
        sudo ufw enable
        sudo ufw allow ssh

        sudo apt-get install -y nginx

        # Ensure Nginx is installed and set up
        if ! command -v nginx &> /dev/null; then
            sudo systemctl enable nginx
            echo "Nginx installed."
            sleep 2
        fi

        clear
        
        # Prompt user for HTTPS port
        your_domain="$IPV4_DOMAIN"

        sudo mkdir -p /etc/letsencrypt/live/$your_domain
        
        sudo systemctl start nginx

        readp "Please Enter the port number: " port

        sudo ufw allow 'Nginx HTTPS'

        sudo mkdir -p /var/www/$your_domain/html

        html_content=$(cat <<EOF
        <html><head>
        <style>
            .banner {
                text-align: center;
                padding: 5px;
                font-size: 169px;
                color: lightblue;
                padding-bottom: 0;
            }
            .created-by {
                text-align: center;
                color: lightblue;
                font-size: 18px;
                margin-bottom: 40px;
            }
            .link {
            display: block;
            color: gold;
            text-align: center;
            font-size: 18px;
            margin-top: 10px;
            text-decoration: none;
            }
            .link:hover {
            text-decoration: underline;
            }
        </style>
        </head>
        <body style="
            background-color: #03031f;
        ">
        <div class="banner">
            AIO
        </div>
        <div class="created-by">
            Created by Hosy
        </div>
        <a href="https://github.com/hrostami" class="link" target="_blank">
            Github: github.com/hrostami
        </a>
        <a href="https://twitter.com/hosy000" class="link" target="_blank">
            Twitter: twitter.com/hosy000
        </a>


        </body></html>
EOF
        )

        echo "$html_content" | sudo tee /var/www/$your_domain/html/index.html > /dev/null

        nginx_conf=$(cat <<EOF
server {
    listen $port ssl;
    listen [::]:$port ssl;

    server_name $your_domain;
    ssl_certificate /etc/letsencrypt/live/$your_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$your_domain/privkey.pem;
    
    root /var/www/$your_domain/html;
    index index.html index.htm;
}
EOF
        )

        # Write Nginx server block configuration to file
        echo "$nginx_conf" | sudo tee /etc/nginx/sites-available/$your_domain > /dev/null

        # Enable the Nginx server block
        sudo ln -s /etc/nginx/sites-available/$your_domain /etc/nginx/sites-enabled/

        # Test the Nginx configuration and restart Nginx
        sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default_disabled
        sudo service apache2 stop
        sudo nginx -t
        sudo systemctl restart nginx
        sudo nginx -s reload

        green "Nginx configured to use HTTPS for $IPV4_DOMAIN."
    fi
    readp "Press Enter to continue..."
}
# ----------------------------------------Menu options------------------------------------------------
while true; do
    display_main_menu
    readp "Enter your choice: " main_choice

    case "$main_choice" in
        1) # Chisel
            while true; do
                chisel_tunnel_setup
                readp "Press Enter to continue..."
                break
            done
            ;;
        2) # Hysteria v2
            while true; do
                display_hysteria_v2_menu
                readp "Enter your choice: " hysteria_v2_choice

                case "$hysteria_v2_choice" in
                    1) # Install/Update
                        run_hysteria_v2_setup
                        show_hy2_configs
                        ;;
                    2) # Change Parameters
                        change_hy2_parameters
                        show_hy2_configs
                        ;;
                    3) # Show Configs
                        show_hy2_configs
                        ;;
                    4) # Delete
                        delete_hysteria_v2
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        3) # Tuic
            while true; do
                display_tuic_menu
                readp "Enter your choice: " tuic_choice

                case "$tuic_choice" in
                    1) # Install/Update
                        run_tuic_setup
                        show_tuic_configs
                        ;;
                    2) # Change Parameters
                        change_tuic_parameters
                        show_tuic_configs
                        ;;
                    3) # Show Configs
                        show_tuic_configs
                        ;;
                    4) # Delete
                        delete_tuic
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        4) # Reality
            while true; do
                display_reality_menu
                readp "Enter your choice: " reality_choice

                case "$reality_choice" in
                    1) # Install tcp
                        bash <(curl -sL https://bit.ly/realityez) -t tcp -d www.datadoghq.com
                        readp "Press Enter to continue..."
                        ;;
                    2) # Install grpc
                        bash <(curl -sL https://bit.ly/realityez) -t grpc -d www.datadoghq.com
                        readp "Press Enter to continue..."
                        ;;
                    3) # Show Configs
                        bash <(curl -sL https://bit.ly/realityez)
                        readp "Press Enter to continue..."
                        ;;
                    4) # Change port
                        readp "Please enter port number: " port
                        bash <(curl -sL https://bit.ly/realityez) --port $port 
                        readp "Press Enter to continue..."
                        ;;
                    5) # Change SNI
                        readp "Please enter new SNI: " sni
                        bash <(curl -sL https://bit.ly/realityez) -d "$sni"
                        readp "Press Enter to continue..."
                        ;;
                    6) # Delete
                        bash <(curl -sL https://bit.ly/realityez) -u
                        readp "Press Enter to continue..."
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;

        5) # SSH
            while true; do
                display_ssh_menu
                readp "Enter your choice: " ssh_choice

                case "$ssh_choice" in
                    1) # Add user
                        add_ssh_user
                        readp "Press Enter to continue..."
                        ;;
                    2) # Modify or Delete user
                        modify_delete_ssh_user
                        readp "Press Enter to continue..."
                        ;;
                    3) # Show all users
                        echo
                        rred "Non-system users created by root:"
                        rred "---------------------------------------------"
                        awk -F: '($3 >= 1000 && $1 != "root") {print $1}' /etc/passwd
                        rred "---------------------------------------------"
                        echo
                        readp "Press Enter to continue..."
                        ;;
                    4) # Delete
                        delete_ssh
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        6) # 4in1
            while true; do
                dir1="/root/hy2"
                dir2="/root/tuic"

                if [ -d "$dir1" ] || [ -d "$dir2" ]; then
                    rred "Please Disable hysteria and other common protocols manually."
                    readp "Press Enter to continue..."
                else
                    echo "4in1 script loading..."
                fi
                bash <(curl -sL https://raw.githubusercontent.com/hrostami/aio-proxy/master/4in1.sh)
                readp "Press Enter to continue..."
                break
            done
            ;;
        7) # Tunnel
            while true; do
                run_tunnel_setup
                break
            done
            ;;
        8) # Install Panels
            while true; do
                display_install_panels_menu
                readp "Enter your choice: " install_panels_choice

                case "$install_panels_choice" in
                    1) # X-UI Alireza
                        install_x_ui_alireza
                        ;;
                    2) # X-UI Sanaei
                        install_x_ui_sanaei
                        ;;
                    3) # RealityEZPZ by Aleskxyz
                        install_reality_ezpz
                        ;;
                    4) # RealityEZPZ by Aleskxyz
                        install_hiddify
                        ;;
                    5) # Marzban
                        install_marzban
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        9) # Warp
            while true; do
                display_warp_menu
                readp "Enter your choice: " warp_choice

                case "$warp_choice" in
                    1) # Install
                        install_warp
                        ;;
                    2) # Disable
                        disable_warp
                        ;;
                    3) # Enable
                        enable_warp
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        10) # Telegram Proxy
            while true; do
                display_telegram_menu
                readp "Enter your choice: " telegram_choice

                case "$telegram_choice" in
                    1) # Python
                        curl -o MTProtoProxyInstall.sh -L https://git.io/fjo34 && bash MTProtoProxyInstall.sh
                        readp "Press Enter to continue..."
                        ;;
                    2) # Official Method
                        curl -o MTProtoProxyOfficialInstall.sh -L https://git.io/fjo3u && bash MTProtoProxyOfficialInstall.sh
                        readp "Press Enter to continue..."
                        ;;
                    3) # Golang
                        curl -o MTGInstall.sh -L https://git.io/mtg_installer && bash MTGInstall.sh
                        readp "Press Enter to continue..."
                        ;;
                    4) # Erlang
                        curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh
                        readp "Press Enter to continue..."
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        11) # show ports in use
            clear
            echo "Ports in use and their corresponding processes:"
            echo "----------------------------------------------"

            # Get the list of ports and their corresponding processes
            sudo ss -tulpn | awk '{if(NR>1) print $5, $7}' | column -t

            echo "----------------------------------------------"
            readp "Press Enter to continue..."
            ;;
        12) # Domains
            while true; do
                display_domains_menu
                readp "Enter your choice: " domains_choice

                case "$domains_choice" in
                    1) # IPv4 Domain
                        setup_ipv4_domain
                        ;;
                    2) # IPv6 Domain
                        setup_ipv6_domain
                        ;;
                    3) # Cert + nginx setup
                        setup_cert
                        ;;
                    4) # NAT nginx setup
                        setup_nginx_nat
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        0) # Exit
            clear
            echo "Exiting..."
            exit
            ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done