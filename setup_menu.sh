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

# Function to display the menu
display_menu() {
    clear
    echo "**********************************************"
    echo -e "\033[1;32m     Proxy Setup Menu\033[0m"
    echo "**********************************************"
    echo "1. Run Hysteria Setup"
    echo "2. Run Hysteria v2 Setup"
    echo "3. Run Tuic Setup"
    echo "4. Delete Hysteria Proxy"
    echo "5. Delete Hysteria v2 Proxy"
    echo "6. Delete Tuic Proxy"
    echo "0. Exit"
    echo "**********************************************"
}

# Function to run Hysteria setup script
run_hysteria_setup() {
    clear
    echo "Running Hysteria Setup..."
    sleep 2
    bash hysteria_setup_script.sh
    read -p "Press Enter to continue..."
}

# Function to run Hysteria v2 setup script
run_hysteria_v2_setup() {
    clear
    echo "Running Hysteria v2 Setup..."
    sleep 2
    bash hy2_setup_script.sh  # Use the actual script name and path
    read -p "Press Enter to continue..."
}

# Function to run Tuic setup script
run_tuic_setup() {
    clear
    echo "Running Tuic Setup..."
    sleep 2
    bash tuic_setup_script.sh
    read -p "Press Enter to continue..."
}

# Function to delete Hysteria Proxy
delete_hysteria_proxy() {
    clear
    echo "Deleting Hysteria Proxy..."
    sleep 2
    rm -r ../hy
    systemctl stop hy
    systemctl disable hy
    read -p "Press Enter to continue..."
}

# Function to delete Hysteria v2 Proxy
delete_hysteria_v2_proxy() {
    clear
    echo "Deleting Hysteria v2 Proxy..."
    sleep 2
    rm -r ../hy2
    systemctl stop hy2
    systemctl disable hy2
    read -p "Press Enter to continue..."
}

# Function to delete Tuic Proxy
delete_tuic_proxy() {
    clear
    echo "Deleting Tuic Proxy..."
    sleep 2
    rm -r ../tuic
    systemctl stop tuic
    systemctl disable tuic
    read -p "Press Enter to continue..."
}

while true; do
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        1) run_hysteria_setup ;;
        2) run_hysteria_v2_setup ;;
        3) run_tuic_setup ;;
        4) delete_hysteria_proxy ;;
        5) delete_hysteria_v2_proxy ;;
        6) delete_tuic_proxy ;;
        0) clear; echo "Exiting..."; exit ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done
