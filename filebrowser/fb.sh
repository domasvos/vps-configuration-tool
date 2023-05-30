#!/bin/bash

update_system() {
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get upgrade -y
    elif command -v dnf &> /dev/null; then
        dnf update -y
    elif command -v yum &> /dev/null; then
        yum update -y
    else
        echo "Unsupported package manager. Please update your system manually."
        exit 1
    fi
}

install_filebrowser() {
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
}

create_configuration() {
    local root_folder=${1:-/var/www/html}

    cat > /etc/filebrowser.json <<EOF
{
  "port": $port,
  "baseURL": "",
  "address": "$ip_address",
  "log": "stdout",
  "database": "/etc/filebrowser.db",
  "root": "$root_folder"
}
EOF
}

create_service() {
    cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=File Browser
After=network.target
[Service]
ExecStart=/usr/local/bin/filebrowser -c /etc/filebrowser.json
[Install]
WantedBy=multi-user.target
EOF
}

enable_service() {
    systemctl enable filebrowser.service
    systemctl restart filebrowser.service
}

enable_port() {
    while true; do
        read -p "Enter a port number (default: 8080): " input_port
        port=${input_port:-8080}

        if [[ "${port}" =~ ^[0-9]+$ ]] && [ "${port}" -ge 80 ] && [ "${port}" -le 65353 ]; then
            break
        else
            echo "Invalid port number. Please enter a number between 80 and 65353."
        fi
    done
}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "FileBrowser" "Installation Completed"
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "FileBrowser URL" "http://$ip_address:$port" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}


main() {
    echo "Enter the root folder for File Browser (default: /var/www/html):"
    read -r root_folder

    update_system && install_filebrowser && enable_port && create_configuration "${root_folder:-/var/www/html}" && create_service && enable_service && finalizing
}

web_server=$1
main
