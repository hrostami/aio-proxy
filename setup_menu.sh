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

# Function to display the main menu
display_main_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Main Menu\033[0m"
    echo "**********************************************"
    echo "1. Hysteria"
    echo "2. Hysteria v2"
    echo "3. Tuic"
    echo "0. Exit"
    echo "**********************************************"
}

# Function to display the Hysteria sub-menu
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

# Function to display the Hysteria v2 sub-menu
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

# Function to display the Tuic sub-menu
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


# ----------------------------------------Hysteria stuff------------------------------------------------
run_hysteria_setup() {
    clear
    echo "Running Hysteria Setup..."
    sleep 2
    bash hysteria_setup_script.sh
    read -p "Press Enter to continue..."
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

    read -p "Press Enter to continue..."
}

delete_hysteria() {
    clear
    echo "Deleting Hysteria Proxy..."
    sleep 2
    rm -r ../hy
    systemctl stop hy
    systemctl disable hy
    read -p "Press Enter to continue..."
}
# ----------------------------------------Hysteria V2 stuff------------------------------------------------
run_hysteria_v2_setup() {
    clear
    echo "Running Hysteria v2 Setup..."
    sleep 2
    bash hy2_setup_script.sh
    read -p "Press Enter to continue..."
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

    read -p "Press Enter to continue..."
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
    rm -r ../hy2
    systemctl stop hy2
    systemctl disable hy2
    read -p "Press Enter to continue..."
}
# ----------------------------------------TUIC stuff------------------------------------------------
run_tuic_setup() {
    clear
    echo "Running Tuic Setup..."
    sleep 2
    bash tuic_setup_script.sh
    read -p "Press Enter to continue..."
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
    read -p "Press Enter to continue..."
}
delete_tuic() {
    clear
    echo "Deleting Tuic Proxy..."
    sleep 2
    rm -r ../tuic
    systemctl stop tuic
    systemctl disable tuic
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
                        ;;
                    2) # Change Parameters
                        change_hy_parameters
                        ;;
                    3) # Show Configs
                        show_hy_configs
                        ;;
                    4) # Delete
                        delete_hysteria
                        ;;
                    0) # Back to Main Menu
                        cd "../aio-proxy"
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
                        ;;
                    2) # Change Parameters
                        change_hy2_parameters
                        ;;
                    3) # Show Configs
                        show_hy2_configs
                        ;;
                    4) # Delete
                        delete_hysteria_v2
                        ;;
                    0) # Back to Main Menu
                        cd "../aio-proxy"
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
                        ;;
                    2) # Change Parameters
                        change_tuic_parameters
                        ;;
                    3) # Show Configs
                        show_tuic_configs
                        ;;
                    4) # Delete
                        delete_tuic
                        ;;
                    0) # Back to Main Menu
                        cd "../aio-proxy"
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