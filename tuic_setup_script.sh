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

# Get public IPs
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

# Generate and print URLs
IPV4_URL="tuic://$UUID:$PASSWORD@$IPV4:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3,spdy/3.1&allow_insecure=1#Tuic"

IPV6_URL="tuic://$UUID:$PASSWORD@[$IPV6]:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3,spdy/3.1&allow_insecure=1#Tuic"

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