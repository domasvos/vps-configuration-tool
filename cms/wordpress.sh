#!/bin/bash

#Check what webserver is running
if [ -x "$(command -v nginx)" ]; then
    WEBSERVER='nginx'
elif [ -x "$(command -v apache2)" ]; then
    WEBSERVER='apache2'
else
    echo "Neither Apache nor Nginx is installed. Please install one of them and try again."
    source ../start.sh
fi

#Adding loop for ability to install several WordPress websites
i=1
while [ -d "/var/www/html/wordpress$i" ]; do
    i=$((i+1))
done

# Install WordPress
sudo apt-get update
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www/wordpress$i

#Checking and installing dependancy
deps=("ghostscript" "libapache2-mod-php" "mysql-server" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip")
for dep in "${deps[@]}"
do
    if ! [ -x "$(command -v "$dep")" ]; then
        echo "$dep is not installed, installing it now"
        sudo apt-get install -y "$dep"
    else
        echo "$dep is already installed"
    fi
done

# Configure WordPress for the chosen web server
if [ "$WEBSERVER" == "nginx" ]; then
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R www-data:www-data /var/www/html/wordpress$i
    sudo service nginx restart
else
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R www-data:www-data /var/www/html/wordpress$i
    sudo service apache2 restart
fi

# Configure the database for WordPress
DBNAME="wordpress$i"
sudo mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "GRANT ALL ON $DBNAME.* TO 'wpuser'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "FLUSH PRIVILEGES;"