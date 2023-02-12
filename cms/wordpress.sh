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

# Function to configure the database for WordPress
configure_database() {
    if [ -x "$(command -v mysql)" ]; then
        echo "MySQL is installed"
    else
        check_installed "mysql-server"
    fi
    read -p "Enter WordPress database username: " wpuser
    read -p "Enter WordPress database password: " wppass
    DBNAME="wordpress$i"
    salt=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    sudo mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mysql -e "GRANT ALL ON $DBNAME.* TO '$wpuser'@'localhost' IDENTIFIED BY '$wppass';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo -u www-data cp -r "/srv/www/wordpress$i/wp-config-sample.php" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/database_name_here/$DBNAME/" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/username_here/$wpuser/" "/srv/www/wordpress$i/wp-config.php"
    sudo -u www-data sed -i "s/password_here/$wppass/" "/srv/www/wordpress$i/wp-config.php"
    sed -i "/define( 'AUTH_KEY/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'SECURE_AUTH_KEY/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'LOGGED_IN_KEY/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'NONCE_KEY/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'AUTH_SALT/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'SECURE_AUTH_SALT/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'LOGGED_IN_SALT/d" "/srv/www/wordpress$i/wp-config.php";
    sed -i "/define( 'NONCE_SALT/d" "/srv/www/wordpress$i/wp-config.php";
    echo "$salt" >> "/srv/www/wordpress$i/wp-config.php"
}

# Function to configure WordPress for the chosen web server
configure_webserver() {
    if [ "$WEBSERVER" == "nginx" ]; then
        sudo service nginx restart
    else
        sudo service apache2 restart
    fi
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

    cat <<- EOF | sudo tee /etc/apache2/sites-available/wordpress$i.conf
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/wordpress$i
        ServerName wordpress$i
        <Directory /var/www/html/wordpress$i>
            AllowOverride All
        </Directory>
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    echo -e "\n# Added by Opti-Tool WordPres installation\nListen $port" >> /etc/apache2/ports.conf
    sudo a2ensite wordpress$i
    sudo service apache2 restart
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
configure_apache