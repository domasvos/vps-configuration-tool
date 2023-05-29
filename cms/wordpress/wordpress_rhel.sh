#!/bin/bash

# Function to check if a command is installed
check_installed() {
    if ! [ -x "$(command -v "$1")" ]; then
        sudo yum install -y "$1" > /dev/null 2>&1
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
    sudo yum update -y
    sudo mkdir -p /srv/www/
    sudo chown apache: /srv/www/
    curl https://wordpress.org/latest.tar.gz | sudo -u apache tar zx -C /srv/www/ && sudo mv /srv/www/wordpress /srv/www/wordpress$i
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R apache:apache /var/www/html/wordpress$i
}

# Function to install and configure PHP
install_php() {
    # Detect the OS version
    os_version=$(rpm -E %{rhel})

    # Install EPEL repository for older systems
    if [ "$os_version" -le 7 ]; then
      sudo yum install -y epel-release
    fi

    # Install required dependencies
    sudo yum install -y yum-utils

    # Install Remi repository
    sudo yum install -y https://rpms.remirepo.net/enterprise/remi-release-$os_version.rpm

    # Enable the desired PHP version (e.g., PHP 8.0)
    sudo yum-config-manager --enable remi-php80

    # Install PHP and necessary extensions
    sudo yum install -y php php-{bcmath,curl,gd,intl,json,mbstring,mysqlnd,xml,zip}
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
        sudo yum install -y mariadb-server
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
deps=("ghostscript" "httpd" "php" "php-bcmath" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-xml" "php-zip" "openssl")
for dep in "${deps[@]}"
do
    check_installed "$dep"
done

install_wordpress && install_php && configure_database && configure_webserver && finalizing
