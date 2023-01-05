#!/bin/bash

vps_information() {
    # Set the text color to gold
    echo -e "\033[33m"

    # Display the Linux distro name and version
    distro_name=$(grep '^NAME=' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
    distro_version=$(grep '^VERSION_ID=' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
    echo "Linux distro: $distro_name $distro_version"

    # Set the text color to red
    echo -e "\033[31m"

    # Display the disk usage with green and blinking text for used and total amount
    df -h | awk 'NR==2{print "Disk Usage: " "\033[32m" "\033[5m" $3 "/" "\033[32m" $2 "\033[0m"}'

    # Set the text color to red
    echo -e "\033[31m"

    # Display the RAM memory usage with green and blinking text for used and total amount
    free -h | awk 'NR==2{print "RAM Memory usage: " "\033[32m" "\033[5m" $3 "/" "\033[32m" $2 "\033[0m"}'

    # Set the text color to red
    echo -e "\033[31m"

    # Display the CPU usage with green and blinking text for used and total amount
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "CPU usage: " "\033[32m" "\033[5m" "%.1f%%/100%%\033[32m\033[5m\n", usage}'

    # Set the text color back to the default
    echo -e "\033[0m"

    # Display the options menu
    echo "Please choose an option:"
    echo "1. Install CyberPanel"
    echo "2. Exit"

    # Read in the user's selection
    read -p "Enter your choice: " choice

    # Set the text color back to the default
    echo -e "\033[0m"
}

menu() {
    # Handle the user's selection
    case $choice in
        1)
            # Display the necessary requirements for CyberPanel
            echo -e "\033[31mPython is necessary and will be installed."
            echo -e "CyberPanel requires at least 1024MB of Ram memory."
            echo -e "CyberPanel requires at least 10GB of free disk space.\033[0m"

            # Ask the user if they still want to install CyberPanel
            read -p "Do you want to install CyberPanel (y/N)? " install_cyberpanel
            if [[ $install_cyberpanel =~ ^[Yy]$ ]]; then
                bash install_cyberpanel.sh
            else
                # Return to the options menu
                vps_information
		        menu
            fi
            ;;
        2)
            # Exit the script
            break
            ;;
    esac
}

while true; do 
    vps_information
    menu
done
