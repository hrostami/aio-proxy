#!/bin/bash

# Update the system
apt-get update 

# Install necessary packages
apt-get install wget nano -y

# Install net-tools
apt-get install net-tools -y

# Detect user and set the directory path
if [ "$EUID" -eq 0 ]; then
    user_directory="/root/hy2"
else
    user_directory="/home/$USER/hy2"
fi

# Check if Hysteria directory exists
if [ -d "$user_directory" ]; then
    clear
    echo "--------------------------------------------------------------------------------"
    echo -e "\e[1;33mHysteria directory already exists. Checking for latest version..\e[0m"
    echo "--------------------------------------------------------------------------------"
    sleep 2
    # Check if the config.json file exists
    if [ -f "$user_directory/config.json" ]; then
        # Read the port and obfuscation password from config.json
        port=$(jq -r '.listen' <<< "$(< "$user_directory/config.json")" | cut -c 2-)
        password=$(jq -r '.obfs.salamander.password' <<< "$(< "$user_directory/config.json")")

    else
        echo "Error: config.json file not found in Hysteria directory."
        return
    fi
else
    # Prompt user for port and password
    read -p "Enter the listening port: " port
    read -p "Enter the obfuscation password: " password

    # Create the directory
    mkdir -p "$user_directory"

    # Create the hysteria configuration file (config.json) with variables
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

# Detect the latest version of the GitHub repository
latest_version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
echo -e "\e[1;33m---> Installing hysteria ver $latest_version\e[0m"
echo "--------------------------------------------------------------------------------"
sleep 2

# Detect architecture and download the appropriate file
architecture=$(uname -m)
if [ "$architecture" = "x86_64" ]; then
    wget "https://github.com/apernet/hysteria/releases/download/$latest_version/hysteria-linux-amd64"
else
    wget "https://github.com/apernet/hysteria/releases/download/$latest_version/hysteria-linux-arm"
    mv hysteria-linux-arm hysteria-linux-amd64
fi

# Provide execute permissions to the downloaded file
chmod 755 hysteria-linux-amd64

# Generate encryption keys if they don't exist
if [ ! -f "$user_directory/ca.key" ] || [ ! -f "$user_directory/ca.crt" ]; then
    openssl ecparam -genkey -name prime256v1 -out "$user_directory/ca.key"
    openssl req -new -x509 -days 36500 -key "$user_directory/ca.key" -out "$user_directory/ca.crt" -subj "/CN=bing.com"
fi

# Create a systemd service for hysteria if it doesn't exist
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

    # Reload systemd and enable the service
    systemctl daemon-reload
    systemctl enable hy2
fi


# Restart the hysteria service and display its status
systemctl restart hy2

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

# V2rayN config
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

# Create URLs
IPV4_URL="hysteria2://$password@$IPV4:$port/?insecure=1&obfs=salamander&obfs-password=$password&sni=google.com#HysteriaV2"
IPV6_URL="hysteria2://$password@[$IPV6]:$port/?insecure=1&obfs=salamander&obfs-password=$password&sni=google.com#HysteriaV2"

# Print URLs
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
echo "----------------V2rayN Config IPv-----------------"
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
