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

# Function to install and configure PHP
install_php() {
    # Get current PHP version
    PHP_VER=$(php -v 2>/dev/null | grep -o -m 1 -E '[0-9]\.[0-9]+' || echo '0')

    # Compare PHP version with 8.0 using bc since bash doesn't support floating point comparisons
    PHP_VER_CHK=$(echo "$PHP_VER < 8.0" | bc)

    # If PHP version is less than 8.0 or doesn't exist, install PHP 8.1
    if [ "$PHP_VER_CHK" -eq "1" ]; then
        # Add Ondrej's repository
        sudo apt-get install -y software-properties-common apt-transport-https lsb-release ca-certificates curl
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

        # Update the package lists
        sudo apt-get update

    else
        echo "PHP version $PHP_VER is already installed and is equal to or greater than 8.0"
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

    source "$main_pwd/hosts/vh_${web_server}.sh" "wordpress$i"
}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "WordPress" ""
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Website URL" "http://$ip_address:$port" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Name" "$DBNAME" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Username" "$wpuser" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Password" "$wppass" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}


# Check and install dependencies
install_php
deps=("ghostscript" "libapache2-mod-php" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip")
for dep in "${deps[@]}"
do
    check_installed "$dep"
done

install_wordpress
configure_database
configure_webserver && finalizing