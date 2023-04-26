#!/bin/bash

get_web_server() {
    if command -v apache2 > /dev/null || command -v httpd > /dev/null; then
        echo "apache"
    elif command -v nginx > /dev/null; then
        echo "nginx"
    else
        echo "N/A"
    fi
}

title() {
    printf '\e[?25l'
    color_codes=(31 32 34 36 91 94 95 97 32)
    for color_code in "${color_codes[@]}"; do
        clear
        echo -e "\033[${color_code}m
 _    _      _                            _
| |  | |    | |                          | |
| |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___
| |/\| |/ _ \ |/ __/ _ \| '_ ' _ \ / _ \ | __/ _-
\  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) |
 \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/


 _____       _   _      _____           _
|  _  |     | | (_)    |_   _|         | |
| | | |_ __ | |_ _ ______| | ___   ___ | |
| | | | '_ \| __| |______| |/ _ \ / _ \| |
\ \_/ / |_) | |_| |      | | (_) | (_) | |
 \___/| .__/ \__|_|      \_/\___/ \___/|_|
      | |
      |_|"
        sleep 0.3
    done
    printf '\e[?25h'
}

vps_information() {
    
    title
    # Set the text color to gold
    echo -e "\033[33m"

    # Source variables
    sed -i 's/\r//' vars
    source vars

    # Print table header
    printf "+--------------------+--------------------------+\n"
    printf "| %-18s | %-24s |\n" "Info" "Value"
    printf "+--------------------+--------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "Linux distribution" "${distro_name} ${distro_version}" && sleep 0.1
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "Machine IP Address" "${ip_address}" && sleep 0.1
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "Web Server" "$(echo "${web_server^}")" && sleep 0.1
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "Disk Usage" "${disk_usage}" && sleep 0.1
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "RAM Memory Usage" "${ram_usage}" && sleep 0.1
    printf "| \033[31m%-18s\033[33m | \033[5m%-24s\033[0m\033[33m |\n" "CPU Usage" "${cpu_usage}" && sleep 0.1

    # Print table footer
    printf "+--------------------+--------------------------+\n"
}
menu() {
    while true; do
        # Display the options menu
        echo -e "\033[1m\033[36mPlease choose an option:\033[0m"
        echo -e "\033[32m1. Install Content Management System"
        echo -e "2. Configure a domain for a website"
        echo -e "3. Configure a file browser"
        echo -e "4. Configure SSL certificate"
        echo -e "5. Exit\033[0m"
        
        # Get the user's choice
        read -p "Enter the number of your choice (1-4): " choice

        # Handle the user's selection
        case $choice in
            1)
                source "cms/select_cms.sh"
                ;;
            2)
                source "domain/add_domain_${web_server}.sh"
                ;;
            3)
                echo "Installing file browser"
                source "filebrowser/fb.sh" "${web_server}"
                ;;
            4) 
                echo "Domain must be pointed to IP Address and"
                sleep 3
                source "domain/add_domain_${web_server}.sh"
                ;;
            5)
                # Exit the script
                break
                ;;
            *)
                # Invalid input
                echo -e "\033[31mInvalid input. Please enter a number between 1 and 4.\033[0m"
                ;;
        esac
    done
}

vps_information && menu
