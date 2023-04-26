#!/bin/bash

# Function to check if a command is installed
check_installed() {
    if ! [ -x "$(command -v "$1")" ]; then
        sudo apt-get install -y "$1" > /dev/null 2>&1
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
    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www/ && mv /srv/www/wordpress /srv/www/wordpress$i
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R www-data:www-data /var/www/html/wordpress$i
}

generate_keys() {
  for key in "AUTH_KEY" "SECURE_AUTH_KEY" "LOGGED_IN_KEY" "NONCE_KEY" "AUTH_SALT" "SECURE_AUTH_SALT" "LOGGED_IN_SALT" "NONCE_SALT"; do
    # Generate a random 64-character string
    random_string=$(openssl rand -base64 48 | tr -d '\n')

    # Replace the placeholder with the random string in the wp-config.php file
    sed -i "s|define( '$key',\s*'put your unique phrase here' );|define( '$key',  '$random_string' );|" "/srv/www/wordpress$i/wp-config.php"
  done
}

# Function to configure the database for WordPress
configure_database() {
    if [ -x "$(command -v mariadb)" ]; then
        echo "MariaDB is installed"
    else
        check_installed "mariadb-server"
    fi
    read -p "Enter WordPress database username: " wpuser
    read -p "Enter WordPress database password: " wppass
    DBNAME="wordpress$i"
    sudo mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mysql -e "GRANT ALL ON $DBNAME.* TO '$wpuser'@'localhost' IDENTIFIED BY '$wppass';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo -u www-data cp -r "/srv/www/wordpress$i/wp-config-sample.php" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/database_name_here/$DBNAME/" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/username_here/$wpuser/" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/password_here/$wppass/" "/srv/www/wordpress$i/wp-config.php"
    generate_keys
}

configure_webserver() {

    bash "../../hosts/vh_apache.sh" "wordpress$i"
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