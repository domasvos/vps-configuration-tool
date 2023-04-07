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
        dnf module enable -y php:remi-8.0
        dnf config-manager --set-enabled remi-safe
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        yum install -y epel-release
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
        yum install -y yum-utils
        yum-config-manager --disable 'remi-php*'
        yum-config-manager --enable remi-php80
    fi
}


check_modules() {

    enable_php_repo

    $PACKAGE_MANAGER update -y

    # Dependencies
    deps=("httpd" "php" "php-bcmath" "php-cli" "php-common" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-opcache" "php-pdo" "php-pecl-zip" "php-xml" "php-process" "unzip" "wget" "curl" "make" "gcc" "nodejs")

    for dep in "${deps[@]}"
    do
        check_installed "$dep"
    done

    if ! which composer >/dev/null 2>&1; then
        install_composer
    else
        echo "Composer already installed"
    fi

    if ! which npm >/dev/null 2>&1; then
        install_npm
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

install_npm() {
    if [ "$PACKAGE_MANAGER" == "dnf" ]; then
        dnf install -y nodejs
    elif [ "$PACKAGE_MANAGER" == "yum" ]; then
        curl -sL https://rpm.nodesource.com/setup_16.x | bash -
        yum install -y nodejs
    fi
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
    composer install -d /var/www/html/prestashop$i/ -n

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

configure_apache() {
    read -p "Enter the desired port number [default 80][0 - 65535]: " port
    if [ -z "$port" ]; then
        port=80
    fi
    if ! [[ $input =~ ^[0-9]+$ ]] && ! [ "$port" -le 65535 ]; then
        echo "Invalid port. Port must be a number and not greater than 65535"
        configure_apache
    fi
    if [ "$(sudo lsof -i:$port | grep -c "LISTEN")" -ne 0 ]; then
        echo "Port $port is already in use. Please choose a different port"
        configure_apache
    fi

    cat <<- EOF | sudo tee /etc/httpd/conf.d/prestashop$i.conf
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/prestashop$i
        ServerName prestashop$i
        <Directory /var/www/html/prestashop$i>
        AllowOverride All
        </Directory>
        ErrorLog /var/log/httpd/prestashop.error.log
        CustomLog /var/log/httpd/prestashop.access.log combined
</VirtualHost>
EOF
    echo -e "\n# Added by Opti-Tool PrestaShop installation\nListen $port" >> /etc/httpd/conf/httpd.conf
    sudo systemctl enable httpd
    sudo systemctl restart httpd
}

finalizing() {
    ip_address=$(hostname -I | awk '{print $2}')
    echo "You can access your website on http://$ip_address:$port"
    echo "You will need to setup your database in the website, here are your website details:"
    echo "Database Name: $dbname"
    echo "Database Username: $dbuser"
    echo "Database Password: $dbpass"
}

prerequisites && check_modules && install_presta && configure_apache && configure_database && finalizing