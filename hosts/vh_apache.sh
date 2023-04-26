#!/bin/bash

# Check if the script received the required arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 directory"
    return 1
fi

directory="$1"

# Prompt for a valid port number
while true; do
    read -p "Enter the desired port number [default 80][0 - 65535]: " port
    if [ -z "$port" ]; then
        port=80
    fi

    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -le 65535 ]; then
        if [ "$(lsof -i:$port | grep -c "LISTEN")" -ne 0 ]; then
            echo "Port $port is already in use. Please choose a different port"
        else
            break
        fi
    else
        echo "Invalid port. Port must be a number and not greater than 65535"
    fi
done

# Check for Apache2 or Httpd and set the configuration directory and log paths accordingly
if command -v apache2 &> /dev/null; then
    config_dir="/etc/apache2/sites-available"
    log_dir="/var/log/apache2"
    error_log="\${APACHE_LOG_DIR}/error.log"
    custom_log="\${APACHE_LOG_DIR}/access.log combined"
elif command -v httpd &> /dev/null; then
    config_dir="/etc/httpd/conf.d"
    log_dir="/var/log/httpd"
    error_log="${log_dir}/${directory}_error.log"
    custom_log="${log_dir}/${directory}_access.log combined"
else
    echo "No supported web server found."
    return 1
fi

# Create the virtual host configuration file
cat <<- EOF | sudo tee "${config_dir}/${directory}.conf"
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/${directory}
        ServerName ${directory}
        <Directory /var/www/html/${directory}>
            AllowOverride All
        </Directory>
        ErrorLog ${error_log}
        CustomLog ${custom_log}
</VirtualHost>
EOF

# Add the Listen directive for the specified port
if command -v apache2 &> /dev/null; then
    echo -e "\n# Added by Opti-Tool WordPres installation\nListen $port" | sudo tee -a /etc/apache2/ports.conf
fi

# Enable the site and restart the web server
if command -v apache2 &> /dev/null; then
    sudo a2ensite "${directory}"
    sudo systemctl restart apache2
elif command -v httpd &> /dev/null; then
    sudo systemctl restart httpd
else
    echo "No supported web server found."
    return 1
fi

echo "VirtualHost created successfully."
