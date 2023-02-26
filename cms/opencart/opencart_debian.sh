#!/bin/bash

prerequisites() {
    echo "Making sure system is up to date..."
    apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1
}

check_modules() {
    # Dependancies
    deps=("libapache2-mod-php" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip")

    for dep in "${deps[@]}"
    do
        check_installed "$dep"
        # Need to install php8.1 for opencart 4, need to install php8.1-curl, php8.1-mbstring, php8.1-gd, php8.1-zip, php8.1-mysql
    done
}

check_installed() {

    # Install software-properties-common to help manage distributions and independent software source
    sudo apt install -y software-properties-common

    # Add the ondrej/php PPA which provides different PHP versions
    echo | sudo add-apt-repository ppa:ondrej/php
    sudo apt update

    if ! [ -x "$(command -v "$1")" ]; then
        apt-get install -y "$1" > /dev/null 2>&1
        echo "$1 installed successfully"
        
    else
        echo "$1 is already installed"
    fi
}

install_opencart() {

    # Checking OpenCart installations
    i=1
    while [ -d "/var/www/html/opencart$i" ]; do
        i=$((i+1))
    done

    # Download the latest version of OpenCart
    echo "Fetching the latest version of OpenCart..."
    latest=$(curl -s https://api.github.com/repos/opencart/opencart/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
    wget -O /tmp/opencart-$latest.zip https://github.com/opencart/opencart/archive/refs/tags/$latest.zip

    # Extract OpenCart to the document root of your Apache web server
    unzip -q /tmp/opencart-$latest.zip -d /var/www/html/
    mv /var/www/html/opencart-$latest/upload /var/www/html/opencart$i
    rm -rf /tmp/opencart-$latest.zip

    # Set proper permissions on the OpenCart directory
    chown -R www-data:www-data /var/www/html/opencart$i/
    chmod -R 755 /var/www/html/opencart$i/
}

configure_database() {

    # Ask for database variables
    read -p "Enter a name for the new database: " dbname
    read -p "Enter a username for the new database: " dbuser
    read -p "Enter a password for the new database: " dbpass

    # Setup database for OpenCart
    mysql -u root -e "CREATE DATABASE $dbname;"
    mysql -u root -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
}

configure_config() {

    # Setup config files
    mv /var/www/html/opencart$i/config-dist.php /var/www/html/opencart$i/config.php
    mv /var/www/html/opencart$i/admin/config-dist.php /var/www/html/opencart$i/admin/config.php

    # Set correct permissions
    chmod 0777 /var/www/html/opencart$i/config.php
    chmod 0777 /var/www/html/opencart$i/admin/config.php
    
}

configure_apache() {

    read -p "Enter the desired port number [default 80][0 - 65535]: " port
    if [ -z "$port" ]; then
        port=80
    fi
    if ! [[ $input =~ ^[0-9]+$ ]] && ! [ "$port" -le 65535 ]; then
        echo "Invalid port. Port must be a number and not greater than 65535"
        configure_apache
    fi
    if [ "$(lsof -i:$port | grep -c "LISTEN")" -ne 0 ]; then
        echo "Port $port is already in use. Please choose a different port"
        configure_apache
    fi

    cat <<- EOF | sudo tee /etc/apache2/sites-available/opencart$i.conf
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/opencart$i
        ServerName opencart$i
        <Directory /var/www/html/opencart$i>
            AllowOverride All
        </Directory>
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    echo -e "\n# Added by Opti-Tool OpenCart installation\nListen $port" >> /etc/apache2/ports.conf
    sudo a2ensite opencart$i
    sudo service apache2 restart
}

prerequisites && check_modules && install_opencart && configure_database && configure_config && configure_apache