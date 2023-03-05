#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

prerequisites() {
    echo "Making sure system is up to date..."
    apt-get update  && apt-get upgrade -y 
}

check_modules() {

    sudo apt update -y

    # Dependancies
    deps=("mariadb-server" "libapache2-mod-php" "php" "php-bcmath" "php-curl" "php-imagick" "php-intl" "php-json" "php-mbstring" "php-mysql" "php-xml" "php-zip" "php-gd" "php-common" "php-xsl")

    for dep in "${deps[@]}"
    do
        check_installed "$dep"
    done
    
}

check_installed() {

    if ! [ -x "$(command -v "$1")" ]; then
        apt-get install -y "$1" 
        echo "$1 installed successfully"
        
    else
        echo "$1 is already installed"
    fi
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
    mv /var/www/html/prestashop-$latest /var/www/html/prestashop$i
    rm -rf /tmp/prestashop-$latest.zip

    # Set proper permissions on the prestashop directory
    chown -R www-data:www-data /var/www/html/prestashop$i/
    chmod -R 755 /var/www/html/prestashop$i/
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
    if [ "$(lsof -i:$port | grep -c "LISTEN")" -ne 0 ]; then
        echo "Port $port is already in use. Please choose a different port"
        configure_apache
    fi

    cat <<- EOF | sudo tee /etc/apache2/sites-available/prestashop$i.conf
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/prestashop$i
        ServerName prestashop$i
        <Directory /var/www/html/prestashop$i>
            AllowOverride All
        </Directory>
        ErrorLog /var/log/apache2/prestashop.error.log
        CustomLog /var/log/apache2/prestashop.access.log combined
</VirtualHost>
EOF
    echo -e "\n# Added by Opti-Tool PrestaShop installation\nListen $port" >> /etc/apache2/ports.conf
    sudo a2ensite prestashop$i
    sudo service apache2 restart
}