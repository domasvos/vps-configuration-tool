#!/bin/bash

# Check if DNF or YUM is used as package manager
if [ -x "$(command -v dnf)" ]; then
    PACKAGE_MANAGER="dnf"
else
    PACKAGE_MANAGER="yum"
fi

run_cmd() {
    sudo $PACKAGE_MANAGER $@
}


# Function to check if a command is installed
check_installed() {
    if ! [ -x "$(command -v "$1")" ]; then
        run_cmd install -y "$1" > /dev/null 2>&1
        systemctl start "$1" > /dev/null 2>&1
        echo "$1 Installed Successfully"
    else
        echo "$1 is already installed"
    fi
}


# Function to install WordPress
install_wordpress() {
    i=1
    while [ -d "/var/www/html/wordpress$i" ]; do
        i=$((i+1))
    done
    run_cmd update -y
    sudo mkdir -p /srv/www/
    sudo chown apache: /srv/www/
    curl https://wordpress.org/latest.tar.gz | sudo -u apache tar zx -C /srv/www/ && sudo mv /srv/www/wordpress /srv/www/wordpress$i
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R apache:apache /var/www/html/wordpress$i
}


# Function to install and configure PHP
install_php() {
    # Get current PHP version
    os_version=$(rpm -E %{rhel})

    PHP_VER=$(php -v 2>/dev/null | grep -o -m 1 -E '[0-9]\.[0-9]+' || echo '0')

    # Compare PHP version with 8.0 using bc since bash doesn't support floating point comparisons
    PHP_VER_CHK=$(echo "$PHP_VER < 8.0" | bc)

    # If PHP version is less than 8.0 or doesn't exist, install PHP 8.1
    if [ "$PHP_VER_CHK" -eq "1" ]; then
        if [ "$os_version" -le 7 ]; then
        sudo run_cmd install -y epel-release
        fi

        if [ "$PACKAGE_MANAGER" == "yum" ]; then
            run_cmd install -y yum-utils
        fi

        # Install Remi repository
        sudo run_cmd install -y https://rpms.remirepo.net/enterprise/remi-release-$os_version.rpm

        # Enable the desired PHP version (e.g., PHP 8.0)
        if [ "$PACKAGE_MANAGER" == "yum" ]; then
            sudo yum-config-manager --enable remi-php81
        fi

        if [ "$PACKAGE_MANAGER" == "dnf" ]; then
            dnf module reset php
            dnf module install php:remi-8.1
        fi

    else
        echo "PHP version $PHP_VER is already installed and is equal to or greater than 8.0"
    fi
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
    if ! [ -x "$(command -v mysql)" ]; then
        echo "No database engine found. Installing MariaDB..."
        sudo run_cmd install -y mariadb-server
        sudo systemctl enable mariadb
        sudo systemctl start mariadb
    else
        echo "A database engine is already installed."
    fi
    read -p "Enter WordPress database username: " dbuser
    read -p "Enter WordPress database password: " dbpass
    read -p "Enter WordPress database password: " dbname
    sudo mysql -e "CREATE DATABASE $dbname DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mysql -e "GRANT ALL ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo -u apache cp -r "/var/www/html/wordpress$i/wp-config-sample.php" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/database_name_here/$dbname/" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/username_here/$dbuser/" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/password_here/$dbpass/" "/var/www/html/wordpress$i/wp-config.php"
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
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Name" "$dbname" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Username" "$dbuser" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Password" "$dbpass" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}


# Check and install dependencies

install_php
deps=("ghostscript" "php" "php-bcmath" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-xml" "php-zip" "openssl")
for dep in "${deps[@]}"
do
    check_installed "$dep"
done

install_wordpress && configure_database && configure_webserver && finalizing
