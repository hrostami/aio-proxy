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
    echo -e "\033[1;32m     Hysteria and Tuic Setup Menu\033[0m"
    echo "**********************************************"
    echo "1. Run Hysteria Setup"
    echo "2. Run Tuic Setup"
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

# Function to run Tuic setup script
run_tuic_setup() {
    clear
    echo "Running Tuic Setup..."
    sleep 2
    bash tuic_setup_script.sh
    read -p "Press Enter to continue..."
}

while true; do
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        1) run_hysteria_setup ;;
        2) run_tuic_setup ;;
        0) clear; echo "Exiting..."; exit ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done
