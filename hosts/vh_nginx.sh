#!/bin/bash

# Check if the script received the required arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 directory"
    exit 1
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

if command -v nginx &> /dev/null; then
    config_dir="/etc/nginx/conf.d"
else
    echo "Nginx web server not found."
    exit 1
fi

# Create the virtual host configuration file
cat <<- EOF | sudo tee "${config_dir}/${directory}.conf"
server {
    listen $port;
    server_name ${directory};
    root /var/www/html/${directory};
    index index.html index.htm index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE "upload_max_filesize=32M";
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

sudo chown -R nginx:nginx /var/www/html/${directory}
# Restart the Nginx web server
sudo systemctl restart nginx

echo "Virtual host created successfully."