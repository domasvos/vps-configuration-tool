#!/bin/bash

set -e

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

    $PACKAGE_MANAGER update -y
}

enable_php_repo() {
    if [ "$PACKAGE_MANAGER" == "dnf" ]; then
        dnf install -y epel-release
        dnf install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        dnf module reset -y php
        dnf module enable -y php:remi-8.1
        dnf config-manager --set-enabled remi-safe
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        yum install -y epel-release
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        yum install -y yum-utils
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable remi-php81
    fi
}


check_modules() {

    enable_php_repo

    $PACKAGE_MANAGER update -y

    # Dependencies
    deps=("php" "php-bcmath" "php-cli" "php-common" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-opcache" "php-pdo" "php-pecl-zip" "php-xml" "php-process" "unzip" "wget" "curl" "make" "gcc")

    for dep in "${deps[@]}"
    do
        check_installed "$dep"
    done

    if ! which composer >/dev/null 2>&1; then
        install_composer
    else
        echo "Composer already installed"
    fi

    if ! which node >/dev/null 2>&1; then
        install_node
    else
        echo "npm already installed"
    fi

    if ! which mysql >/dev/null 2>&1; then 
        echo "Installing MariaDB"
        $PACKAGE_MANAGER install -y mariadb mariadb-server
        systemctl start mariadb
        systemctl enable mariadb
    else
        echo "MySQL is already installed"
    fi

}

check_installed() {

    if ! [ -x "$(command -v "$1")" ]; then
        $PACKAGE_MANAGER install -y "$1" 
        echo "$1 installed successfully"
    else
        echo "$1 is already installed"
    fi
}

install_composer() {
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    HASH="$(curl -sS https://composer.github.io/installer.sig)"
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
}

install_node() {
    curl -sL https://rpm.nodesource.com/setup_16.x | bash -
    $PACKAGE_MANAGER install -y nodejs
}

install_presta() {
    # Checking PrestaShop installations
    i=1
    while [ -d "/var/www/html/prestashop$i" ]; do
        i=$((i+1))
    done

    # Download the latest version of PrestaShop
    echo "Fetching the latest version..."
    latest=$(curl -s https://api.github.com/repos/PrestaShop/PrestaShop/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
    wget -O /tmp/prestashop-$latest.zip https://github.com/PrestaShop/PrestaShop/archive/refs/tags/$latest.zip

    # Extract PrestaShop to the document root of your Apache web server
    sudo mkdir -p /var/www/html
    sudo unzip -q /tmp/prestashop-$latest.zip -d /var/www/html/
    sudo mv /var/www/html/PrestaShop-$latest /var/www/html/prestashop$i
    sudo rm -rf /tmp/prestashop-$latest.zip

    # Use Composer to Download project's dependencies
    COMPOSER_ALLOW_SUPERUSER=1 composer install -d /var/www/html/prestashop$i/ -n --ignore-platform-req=ext-gd

    # Use NPM to create project's assets
    cd /var/www/html/prestashop$i/
    npm install --legacy-peer-deps -g npm@6
    make assets
    cd -

    # Set proper permissions on PrestaShop folder
    sudo chown -R apache:apache /var/www/html/prestashop$i/
}

configure_database() {
    # Ask for database variables
    while [ -z "$dbname" ]; do
        read -p "Enter a name for the new database: " dbname
    done

    while [ -z "$dbuser" ]; do
        read -p "Enter a username for the new database: " dbuser
    done

    while [ -z "$dbpass" ]; do
        read -p "Enter a password for the new database: " dbpass
    done

    # Setup database for OpenCart
    mysql -u root -e "CREATE DATABASE $dbname;"
    mysql -u root -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
}

configure_webserver() {

    source "$main_pwd/hosts/vh_${web_server}.sh" "prestashop$i"

}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "PrestaShop" ""
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Website URL" "http://$ip_address:$port" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Name" "$dbname" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Username" "$dbuser" && sleep 0.1
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Database Password" "$dbpass" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}


prerequisites && check_modules && install_presta && configure_webserver && configure_database && finalizing