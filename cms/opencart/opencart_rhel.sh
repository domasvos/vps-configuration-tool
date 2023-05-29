#!/bin/bash

prerequisites() {
    echo "Making sure system is up to date..."

    if [ "$(command -v dnf)" ]; then
        PACKAGE_MANAGER="dnf"
    elif [ "$(command -v yum)" ]; then
        PACKAGE_MANAGER="yum"
    else
        echo "No suitable package manager found. Exiting."
        exit 1
    fi

    run_cmd update -y
}

run_cmd() {
    if [ "$PACKAGE_MANAGER" == "dnf" ]; then
        dnf $@
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        yum $@
    fi
}

enable_php_repo() {
    if [ "$PACKAGE_MANAGER" == "dnf" ]; then
        run_cmd install -y epel-release
        run_cmd install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        run_cmd module reset -y php
        run_cmd module enable -y php:remi-8.0
        run_cmd config-manager --set-enabled remi-safe
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        run_cmd install -y epel-release
        run_cmd install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        run_cmd install -y yum-utils
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable remi-php80
    fi
}

check_modules() {

    enable_php_repo
    run_cmd update -y

    # Dependencies
    deps=("php" "php-bcmath" "php-cli" "php-common" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-opcache" "php-pdo" "php-pecl-zip" "php-xml" "php-process" "unzip" "wget" "curl" "make" "gcc")

    for dep in "${deps[@]}"
    do
        check_installed "$dep"
    done
}

check_installed() {

    if ! rpm -q "$1"; then
        run_cmd install -y "$1" 
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
    rm -rf /tmp/opencart-$latest.zip && rm -rf /var/www/html/opencart-$latest

    # Set proper permissions on the OpenCart directory
    chown -R apache:apache /var/www/html/opencart$i/
    chmod -R 755 /var/www/html/opencart$i/
}

configure_database() {
    # Check if MySQL/MariaDB is already installed
    if ! [ -x "$(command -v mysql)" ]; then
        echo "Installing MariaDB server..."
        run_cmd install -y mariadb-server
    else
        echo "MySQL/MariaDB is already installed."
    fi

    # Check if MariaDB service is running and enable it if necessary
    if ! systemctl is-active --quiet mariadb; then
        echo "Starting and enabling MariaDB server..."
        systemctl start mariadb
        systemctl enable mariadb
    else
        echo "MariaDB server is already running."
    fi

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

configure_webserver() {

    source "$main_pwd/hosts/vh_${web_server}.sh" "opencart$i"

}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "OpenCart" ""
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Website URL" "http://$ip_address:$port" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Name" "$dbname" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Username" "$dbuser" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Password" "$dbpass" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}


prerequisites && check_modules && install_opencart && configure_database && configure_config && configure_webserver && finalizing
