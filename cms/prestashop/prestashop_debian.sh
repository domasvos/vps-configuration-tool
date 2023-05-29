#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

prerequisites() {
    echo "Making sure system is up to date..."
    apt-get update  && apt-get upgrade -y 
}

enable_php_repo() {
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
}

check_modules() {

    sudo apt update -y

    # Dependancies
    deps=("libapache2-mod-php" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip" "php-gd" "php-common" "php-xsl")

    # Check if PHP does not exist, if not - install it
    if ! which php >/dev/null 2>&1; then 
        for dep in "${deps[@]}"
        do
            check_installed "$dep"
        done
    else
        echo "PHP Already installed"
    fi

    # Check if Composer does not exist, if not - install it
    if ! which composer >/dev/null 2>&1; then
        install_composer
    else
        echo "Composer already installed"
    fi

    # Check if NPM does not exist, if not - install it
    if ! which npm >/dev/null 2>&1; then
        install_node
    else
        echo "npm already installed"
    fi

    # Check if MySQL does not exist, if not - install it.
    if ! which mysql >/dev/null 2>&1; then 
        echo "Installing MariaDB"
        sudo apt-get install -y mariadb-server
    else
        echo "MySQL is already installed"
    fi

}

check_installed() {

    if ! [ -x "$(command -v "$1")" ]; then
        apt-get install -y "$1" 
        echo "$1 installed successfully"
        
    else
        echo "$1 is already installed"
    fi
}

install_composer() {

    # Install Composer globally, necessary for PrestaShop
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    HASH='curl -sS https://composer.github.io/installer.sig'
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
}

install_node() {

    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - &&\
    apt-get install -y nodejs
}

install_presta() {

    # Checking PrestaShop installations
    i=1
    while [ -d "/var/www/html/presta$i" ]; do
        i=$((i+1))
    done

    # Download the latest version of PrestaShop
    echo "Fetching the latest version..."
    latest=$(curl -s https://api.github.com/repos/PrestaShop/PrestaShop/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
    wget -O /tmp/prestashop-$latest.zip https://github.com/PrestaShop/PrestaShop/archive/refs/tags/$latest.zip

    # Extract prestashop to the document root of your Apache web server
    unzip -q /tmp/prestashop-$latest.zip -d /var/www/html/
    mv /var/www/html/PrestaShop-$latest /var/www/html/prestashop$i
    rm -rf /tmp/prestashop-$latest.zip

    # Use Composer to Download project's dependencies
    COMPOSER_ALLOW_SUPERUSER=1 composer install -d /var/www/html/prestashop$i/ -n --ignore-platform-req=ext-gd

    # Use NPM to create project's assets
    cd /var/www/html/prestashop$i/
    npm install --legacy-peer-deps -g npm@6
    make assets
    cd -

    # Set proper permissions on PrestaShop folder
    chown -R www-data:www-data /var/www/html/prestashop$i/
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

# Adding choice to configure website on Port or Full domain

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