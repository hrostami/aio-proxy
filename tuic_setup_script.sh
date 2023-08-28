#!/bin/bash
# Install jq if not already installed
if ! command -v jq &>/dev/null; then
    echo "Installing jq..."
    if ! sudo apt-get install jq -y; then
        echo "Error: Failed to install jq."
        exit 1
    fi
    echo "jq installed successfully."
fi

# Determine the appropriate TUIC_FOLDER based on the user
if [ "$EUID" -eq 0 ]; then
    TUIC_FOLDER="/root/tuic"
else
    TUIC_FOLDER="$HOME/tuic"
fi

CONFIG_FILE="$TUIC_FOLDER/config.json"

# Update packages  
apt update
apt install nano net-tools uuid-runtime wget openssl -y

# Create TUIC directory and navigate to it 
mkdir ~/tuic
cd ~/tuic

# Download TUIC server binary
wget -O tuic-server https://github.com/EAimTY/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-linux-gnu
chmod 755 tuic-server

# Generate certificate
openssl ecparam -genkey -name prime256v1 -out ca.key
openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/CN=bing.com"

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
cat <<EOF >config.json
{
"server": "[::]:$PORT", 
"users": {
"${UUID}": "$PASSWORD"
},
"certificate": "/root/tuic/ca.crt",
"private_key": "/root/tuic/ca.key",
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


cat <<EOF > /etc/systemd/system/tuic.service
[Unit]
Description=tuic service
Documentation=by iSegaro  
After=network.target nss-lookup.target

[Service] 
User=root
WorkingDirectory=/root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
ExecStart=/root/tuic/tuic-server -c /root/tuic/config.json
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
IPV4_URL="tuic://$UUID:$PASSWORD@$IPV4:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3%2Cspdy%2F3.1&allow_insecure=1"

IPV6_URL="tuic://$UUID:$PASSWORD@[$IPV6]:$PORT/?congestion_control=$CONGESTION_CONTROL&udp_relay_mode=native&alpn=h3%2Cspdy%2F3.1&allow_insecure=1"

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
echo "----------------Config IPv4-----------------"
echo -e "\e[1;33m$IPV4_URL\e[0m"
echo "--------------------------------------------"
echo
echo "-----------------Config IPv6----------------"
echo -e "\e[1;33m$IPV6_URL\e[0m"
echo "--------------------------------------------"