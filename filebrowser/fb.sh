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
    local ip_address=$(hostname -I | awk '{if ($1 != "127.0.0.1") {print $1} else {print $2}}')
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
    systemctl start filebrowser.service
}

enable_port() {

    read -p "Enter a port number (default: 8080): " port
    port=${port:-8080}

    if [[ ! "${port}" =~ ^[0-9]+$ ]] || [ "${port}" -lt 80 ] || [ "${port}" -gt 65353 ]; then
        echo "Invalid port number. Please enter a number between 80 and 65353."
        exit 1
    fi

    source port_a2.sh "${port}"
    exit_status=$?

    if [ "${exit_status}" -eq 0 ]; then
        echo "Apache2 is now listening on port ${port}."
    elif [ "${exit_status}" -eq 2 ]; then
        echo "Port ${port} is already in use."
    else
        echo "An error occurred. Check the output of the enable_a2.sh script for details."
    fi
}

main() {
    echo "Enter the root folder for File Browser (default: /var/www/html):"
    read -r root_folder

    update_system && install_filebrowser && enable_port && create_configuration "${root_folder:-/var/www/html}" && create_service && enable_service

    echo "You can access your filebrowser here http://$ip_address:8080"
}

main
