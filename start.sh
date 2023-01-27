#!/bin/bash

get_web_server() {
    if command -v apache2 > /dev/null; then
        echo "Apache"
    elif command -v nginx > /dev/null; then
        echo "Nginx"
    elif command -v lighttpd > /dev/null; then
        echo "Lighttpd"
    else
        echo "N/A"
    fi
}

vps_information() {
echo " _    _      _                            _
| |  | |    | |                          | |
| |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___
| |/\| |/ _ \ |/ __/ _ \| '_ \` _ \ / _ \ | __/ _ \
\  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) |
 \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/


 _____       _   _      _____           _
|  _  |     | | (_)    |_   _|         | |
| | | |_ __ | |_ _ ______| | ___   ___ | |
| | | | '_ \| __| |______| |/ _ \ / _ \| |
\ \_/ / |_) | |_| |      | | (_) | (_) | |
 \___/| .__/ \__|_|      \_/\___/ \___/|_|
      | |
      |_|

-----------------------------------------------------      "

    # Set the text color to gold
    echo -e "\033[33m"

    # Display the Linux distro name and version
    distro_name=$(grep '^NAME=' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
    distro_version=$(grep '^VERSION_ID=' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
    echo "Linux distro: $distro_name $distro_version"

    # Set the text color to red
    echo -e "\033[31m"

    web_server=$(get_web_server)
    echo -e "Web Server:\033[32m\033[5m $web_server \033[0m"

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
    echo "2. Install Content Management System"
    echo "3. Exit"

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
            bash cms/select_cms.sh
            ;;

        3)
            # Exit the script
            run=false
            ;;
    esac
}
run=true
while $run; do
vps_information
menu
done
