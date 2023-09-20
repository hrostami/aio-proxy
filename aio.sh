#!/bin/bash

# install requirements
if ! command -v qrencode &> /dev/null; then
    echo "qrencode is not installed. Installing..."
    sudo apt-get install qrencode -y

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        echo "qrencode is now installed."
    else
        echo "Error: Failed to install qrencode."
    fi
else
    echo "qrencode is already installed."
fi

if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    if ! sudo apt-get install jq -y; then
        echo "Error: Failed to install jq."
        exit 1
    fi
    echo "jq installed successfully."
fi

# ----------------------------------------Show Menus------------------------------------------------
display_main_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Main Menu\033[0m"
    echo "**********************************************"
    echo "1. Hysteria"
    echo "2. Hysteria v2"
    echo "3. Tuic"
    echo "4. Tunnel"
    echo "5. Install Panels"
    echo "6. Warp"
    echo "7. Show Ports in use"
    echo "0. Exit"
    echo "**********************************************"
}

display_hysteria_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Hysteria Menu\033[0m"
    echo "**********************************************"
    echo "1. Install/Update"
    echo "2. Change Parameters"
    echo "3. Show Configs"
    echo "4. Delete"
    echo "0. Back to Main Menu"
    echo "**********************************************"
}

display_hysteria_v2_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Hysteria v2 Menu\033[0m"
    echo "**********************************************"
    echo "1. Install/Update"
    echo "2. Change Parameters"
    echo "3. Show Configs"
    echo "4. Delete"
    echo "0. Back to Main Menu"
    echo "**********************************************"
}

display_tuic_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Tuic Menu\033[0m"
    echo "**********************************************"
    echo "1. Install/Update"
    echo "2. Change Parameters"
    echo "3. Show Configs"
    echo "4. Delete"
    echo "0. Back to Main Menu"
    echo "**********************************************"
}

display_install_panels_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Install Panels Menu\033[0m"
    echo "**********************************************"
    echo "1. X-UI Alireza"
    echo "2. X-UI Sanaei"
    echo "3. RealityEZPZ by Aleskxyz"
    echo "4. Hiddify"
    echo "5. Marzban"
    echo "0. Back to Main Menu"
    echo "**********************************************"
}

display_warp_menu() {
    clear
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
    echo "**********************************************"
    echo -e "\033[1;32m     Warp Menu\033[0m"
    echo "**********************************************"
    echo -e "\e[1;33mIPv4: $IPV4\e[0m"
    echo -e "\e[1;33mIPv6: $IPV6\e[0m"
    echo "**********************************************"
    echo "1. Install"
    echo "2. Disable"
    echo "3. Enable"
    echo "0. Back to Main Menu"
    echo "**********************************************"
}
# ----------------------------------------Hysteria stuff------------------------------------------------
run_hysteria_setup() {
    clear
    echo "Running Hysteria Setup..."
    sleep 2
    #!/bin/bash

    apt-get update 
    apt-get install wget nano -y
    apt-get install net-tools -y

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy"
    else
        user_directory="/home/$USER/hy"
    fi

    if [ -d "$user_directory" ]; then
        clear
        echo "--------------------------------------------------------------------------------"
        echo -e "\e[1;33mHysteria directory already exists. Checking for latest version..\e[0m"
        echo "--------------------------------------------------------------------------------"
        sleep 2

        if [ -f "$user_directory/config.json" ]; then
            port=$(jq -r '.listen' "$user_directory/config.json" | cut -c 2-)
            password=$(jq -r '.obfs' "$user_directory/config.json")
        else
            echo "Error: config.json file not found in Hysteria directory."
            return
        fi
    else
        read -p "Enter the listening port: " port
        read -p "Enter the obfuscation password: " password

        mkdir -p "$user_directory"
        cd "$user_directory"

        cat << EOF > "$user_directory/config.json"
        {
        "listen": ":$port",
        "cert": "$user_directory/ca.crt",
        "key": "$user_directory/ca.key",
        "obfs": "$password",
        "recv_window_conn": 3407872,
        "recv_window": 13631488,
        "disable_mtu_discovery": true,
        "resolver": "https://223.5.5.5/dns-query"
        }
EOF
    fi

    # latest_version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    latest_version="v1.3.5"
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

    # Generate encryption keys if they don't exist
    if [ ! -f "$user_directory/ca.key" ] || [ ! -f "$user_directory/ca.crt" ]; then
        openssl ecparam -genkey -name prime256v1 -out "$user_directory/ca.key"
        openssl req -new -x509 -days 36500 -key "$user_directory/ca.key" -out "$user_directory/ca.crt" -subj "/CN=bing.com"
    fi

    # Create a systemd service for hysteria if it doesn't exist
    if [ ! -f "/etc/systemd/system/hy.service" ]; then
        cat << EOF > /etc/systemd/system/hy.service
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
        systemctl enable hy
    fi


    systemctl restart hy
}

show_hy_configs() {
    local user_directory

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy"
    else
        user_directory="/home/$USER/hy"
    fi

    if [ -d "$user_directory" ]; then
        echo "Here are the current configurations:"
        
        password=$(jq -r '.obfs' "$user_directory/config.json")
        port=$(jq -r '.listen' "$user_directory/config.json" | cut -c 2-)
        
        
        systemctl stop wg-quick@wgcf

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

        systemctl restart wg-quick@wgcf

        IPV4_URL="hysteria://$IPV4:$port?protocol=udp&insecure=1&upmbps=100&downmbps=100&obfs=xplus&obfsParam=$password#hysteria IPv4"
        IPV6_URL="hysteria://[$IPV6]:$port?protocol=udp&insecure=1&upmbps=100&downmbps=100&obfs=xplus&obfsParam=$password#hysteria IPv6"

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
        echo "----------------Hysteria Config IPv4-----------------"
        echo -e "\e[1;33m$IPV4_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV4_URL"
        echo "--------------------------------------------"
        echo
        echo "-----------------Hysteria Config IPv6----------------"
        echo -e "\e[1;33m$IPV6_URL\e[0m"
        qrencode -t ANSIUTF8 "$IPV6_URL"
        echo "--------------------------------------------"
    else
        echo "Hysteria directory does not exist. Please install Hysteria first."
    fi

    read -p "Press Enter to continue..."
}

change_hy_parameters() {
    local user_directory

    if [ "$EUID" -eq 0 ]; then
        user_directory="/root/hy"
    else
        user_directory="/home/$USER/hy"
    fi

    if [ -d "$user_directory" ]; then
        echo "Hysteria directory exists. You can change parameters here."
        
        port=$(jq -r '.listen' "$user_directory/config.json" | cut -c 2-)
        password=$(jq -r '.obfs' "$user_directory/config.json")
        
        read -p "Enter a new listening port [$port]: " new_port
        read -p "Enter a new obfuscation password [$password]: " new_password
        
        # Update the config.json file with the new or existing values
        jq ".listen = \":${new_port:-$port}\" | .obfs = \"$new_password\"" "$user_directory/config.json" > tmp_config.json
        mv tmp_config.json "$user_directory/config.json"

        systemctl restart hy

        echo "Parameters updated successfully."
        show_hy_configs
    else
        echo "Hysteria directory does not exist. Please install Hysteria first."
    fi

}

delete_hysteria() {
    clear
    echo "Deleting Hysteria Proxy..."
    sleep 2
    rm -r ~/hy
    systemctl stop hy
    systemctl disable hy
    read -p "Press Enter to continue..."
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
        read -p "Enter the listening port: " port
        read -p "Enter the obfuscation password: " password

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
        read -p "Enter a new listening port [$port]: " new_port
        read -p "Enter a new obfuscation password [$password]: " new_password
        jq ".listen = \":${new_port:-$port}\" | .obfs.salamander.password = \"$new_password\"" "$user_directory/config.json" > tmp_config.json
        mv tmp_config.json "$user_directory/config.json"
        systemctl restart hy2
        echo "Parameters updated successfully."
        show_hy2_configs
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

    read -p "Press Enter to continue..."
}
delete_hysteria_v2() {
    clear
    echo "Deleting Hysteria v2 Proxy..."
    sleep 2
    rm -r ~/hy2
    systemctl stop hy2
    systemctl disable hy2
    read -p "Press Enter to continue..."
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
        read -p "Enter port number: " PORT

        # Prompt for password
        read -p "Enter a password for the server: " PASSWORD

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
    read -p "Press Enter to continue..."
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
        
        read -p "Enter a new port number [$PORT]: " NEW_PORT
        read -p "Enter a new congestion control [$CONGESTION_CONTROL]: " NEW_CONGESTION
        read -p "Enter a new password [$PASSWORD]: " NEW_PASSWORD
        
        jq ".server = \"[::]:${NEW_PORT:-$PORT}\" | .congestion_control = \"${NEW_CONGESTION:-$CONGESTION_CONTROL}\" | .users[\"$UUID\"] = \"${NEW_PASSWORD:-$PASSWORD}\"" "$CONFIG_FILE" > tmp_config.json
        mv tmp_config.json "$CONFIG_FILE"
        
        echo "Parameters updated successfully."
        systemctl restart tuic
        show_tuic_configs
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
    read -p "Press Enter to continue..."
}

# ----------------------------------------Tunnel stuff------------------------------------------------
run_tunnel_setup() {
    clear
    echo "Running Tunnel Setup..."
    bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/ReverseTlsTunnel/main/RtTunnel.sh)
    sleep 2
    read -p "Press Enter to continue..."
}

# ----------------------------------------Install Panels stuff------------------------------------------------
install_x_ui_alireza() {
    clear
    echo "Installing X-UI Alireza..."
    sleep 2
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    read -p "Press Enter to continue..."
}

install_x_ui_sanaei() {
    clear
    echo "Installing X-UI Sanaei..."
    sleep 2
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    read -p "Press Enter to continue..."
}

install_reality_ezpz() {
    clear
    echo "Installing RealityEZPZ by Aleskxyz..."
    sleep 2
    bash <(curl -sL https://raw.githubusercontent.com/aleskxyz/reality-ezpz/master/reality-ezpz.sh) -m
    read -p "Press Enter to continue..."
}

install_hiddify() {
    clear
    echo "Installing Hiddify..."
    sudo apt update&&sudo apt install curl&& sudo bash -c "$(curl -Lfo- https://raw.githubusercontent.com/hiddify/hiddify-config/main/common/download_install.sh)"
    sleep 2
    read -p "Press Enter to continue..."
}
install_marzban() {
    clear
    echo "Installing Marzban..."
    sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install
    sleep 2
    read -p "Press Enter to continue..."
}
# ----------------------------------------Warp stuff------------------------------------------------
install_warp() {
    echo "Installing Warp..."
    bash <(curl -sL https://raw.githubusercontent.com/hrostami/aio-proxy/master/warp.sh)
    read -p "Press Enter to continue..."
}

disable_warp() {
    echo "Disabling Warp..."
    systemctl stop wg-quick@wgcf
    read -p "Press Enter to continue..."
}

enable_warp() {
    echo "Enabling Warp..."
    systemctl restart wg-quick@wgcf
    read -p "Press Enter to continue..."
}

# ----------------------------------------Menu options------------------------------------------------
while true; do
    display_main_menu
    read -p "Enter your choice: " main_choice

    case $main_choice in
        1) # Hysteria
            while true; do
                display_hysteria_menu
                read -p "Enter your choice: " hysteria_choice

                case $hysteria_choice in
                    1) # Install/Update
                        run_hysteria_setup
                        show_hy_configs
                        ;;
                    2) # Change Parameters
                        change_hy_parameters
                        show_hy_configs
                        ;;
                    3) # Show Configs
                        show_hy_configs
                        ;;
                    4) # Delete
                        delete_hysteria
                        ;;
                    0) # Back to Main Menu
                        break
                        ;;
                    *) echo "Invalid choice. Please select a valid option." ;;
                esac
            done
            ;;
        2) # Hysteria v2
            while true; do
                display_hysteria_v2_menu
                read -p "Enter your choice: " hysteria_v2_choice

                case $hysteria_v2_choice in
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
                read -p "Enter your choice: " tuic_choice

                case $tuic_choice in
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
        4) # Tunnel
            while true; do
                run_tunnel_setup
                break
            done
            ;;
        5) # Install Panels
            while true; do
                display_install_panels_menu
                read -p "Enter your choice: " install_panels_choice

                case $install_panels_choice in
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
        6) # Warp
            while true; do
                display_warp_menu
                read -p "Enter your choice: " warp_choice

                case $warp_choice in
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
        7) # show ports in use
            clear
            echo "Ports in use and their corresponding processes:"
            echo "----------------------------------------------"

            # Get the list of ports and their corresponding processes
            sudo ss -tulpn | awk '{if(NR>1) print $5, $7}' | column -t

            echo "----------------------------------------------"
            read -p "Press Enter to continue..."
            ;;
        0) # Exit
            clear
            echo "Exiting..."
            exit
            ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done