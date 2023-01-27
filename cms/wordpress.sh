#!/bin/bash

# Check if PHP is already installed
if ! [ -x "$(command -v php)" ]; then
    echo "PHP is not installed, installing it now"
    sudo apt-get update
    sudo apt-get install -y php-fpm php-mysql
fi

# Check if Apache or Nginx is already installed
if [ -x "$(command -v nginx)" ]; then
    WEBSERVER='nginx'
elif [ -x "$(command -v apache2)" ]; then
    WEBSERVER='apache2'
else
    echo "Neither Apache nor Nginx is installed. Please install one of them and try again."
    exit 1
fi

# Install WordPress
sudo apt-get update
sudo apt-get install -y wordpress

# Configure WordPress for the chosen web server
if [ "$WEBSERVER" == "nginx" ]; then
    sudo ln -s /usr/share/wordpress /var/www/html
    sudo chown -R www-data:www-data /var/www/html
    sudo service nginx restart
else
    sudo ln -s /usr/share/wordpress /var/www/html
    sudo chown -R www-data:www-data /var/www/html
    sudo service apache2 restart
fi

# Configure the database for WordPress
sudo mysql -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "GRANT ALL ON wordpress.* TO 'wpuser'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "FLUSH PRIVILEGES;"
