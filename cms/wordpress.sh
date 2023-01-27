#!/bin/bash

# Function to check if a command is installed
check_installed() {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "$1 is not installed, installing it now"
        sudo apt-get install -y "$1"
    else
        echo "$1 is already installed"
    fi
}

# Function to check which web server is running
check_webserver() {
    if [ -x "$(command -v nginx)" ]; then
        WEBSERVER='nginx'
    elif [ -x "$(command -v apache2)" ]; then
        WEBSERVER='apache2'
    else
        echo "Neither Apache nor Nginx is installed. Please install one of them and try again."
        exit 1
    fi
}

# Function to install WordPress
install_wordpress() {
    i=1
    while [ -d "/var/www/html/wordpress$i" ]; do
        i=$((i+1))
    done
    sudo apt-get update
    sudo mkdir -p /srv/www/
    sudo chown www-data: /srv/www/
    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www/ && mv wordpress wordpress$i
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R www-data:www-data /var/www/html/wordpress$i
}

# Function to configure the database for WordPress
configure_database() {
    if [ -x "$(command -v mysql)" ]; then
        echo "MySQL is already installed"
    else
        check_installed "mysql-server"
    fi
    DBNAME="wordpress$i"
    sudo mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mysql -e "GRANT ALL ON $DBNAME.* TO 'wpuser'@'localhost' IDENTIFIED BY 'password';"
    sudo mysql -e "FLUSH PRIVILEGES;"
}

# Function to configure WordPress for the chosen web server
configure_webserver() {
    if [ "$WEBSERVER" == "nginx" ]; then
        sudo service nginx restart
    else
        sudo service apache2 restart
    fi
}

# Check and install dependencies
deps=("ghostscript" "libapache2-mod-php" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip")
for dep in "${deps[@]}"
do
    check_installed "$dep"
done

check_webserver
install_wordpress
configure_database
configure_webserver
