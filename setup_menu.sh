#!/bin/bash

# Function to display the menu
display_menu() {
    echo -e "\033[1;32mHysteria and Tuic Setup Menu\033[0m"
    echo "1. Run Hysteria Setup"
    echo "2. Run Tuic Setup"
    echo "0. Exit"
}

# Function to run Hysteria setup script
run_hysteria_setup() {
    bash hysteria_setup_script.sh
}

# Function to run Tuic setup script
run_tuic_setup() {
    bash tuic_setup_script.sh
}

while true; do
    display_menu
    read -p "Enter your choice: " choice

    case $choice in
        1) run_hysteria_setup ;;
        2) run_tuic_setup ;;
        0) echo "Exiting..."; exit ;;
        *) echo "Invalid choice. Please select a valid option." ;;
    esac
done
