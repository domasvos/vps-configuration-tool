#!/bin/bash

# Function to check if a command is installed
check_installed() {
    if ! [ -x "$(command -v "$1")" ]; then
        sudo yum install -y "$1" > /dev/null 2>&1
        systemctl start "$1"
    else
        echo "$1 is already installed"
    fi
}

# Function to check which web server is running
check_webserver() {
    if [ -x "$(command -v nginx)" ]; then
        WEBSERVER='nginx'
    elif [ -x "$(command -v httpd)" ]; then
        WEBSERVER='httpd'
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
    sudo yum update -y
    sudo mkdir -p /srv/www/
    sudo chown apache: /srv/www/
    curl https://wordpress.org/latest.tar.gz | sudo -u apache tar zx -C /srv/www/ && sudo mv /srv/www/wordpress /srv/www/wordpress$i
    sudo ln -s /srv/www/wordpress$i /var/www/html/wordpress$i
    sudo chown -R apache:apache /var/www/html/wordpress$i
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
    read -p "Enter WordPress database username: " wpuser
    read -p "Enter WordPress database password: " wppass
    DBNAME="wordpress$i"
    sudo mysql -e "CREATE DATABASE $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    sudo mysql -e "GRANT ALL ON $DBNAME.* TO '$wpuser'@'localhost' IDENTIFIED BY '$wppass';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo -u apache cp -r "/var/www/html/wordpress$i/wp-config-sample.php" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/database_name_here/$DBNAME/" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/username_here/$wpuser/" "/var/www/html/wordpress$i/wp-config.php"
    sudo -u apache sed -i "s/password_here/$wppass/" "/var/www/html/wordpress$i/wp-config.php"
    generate_keys
}


# Function to configure WordPress for the chosen web server
configure_webserver() {
    if [ "$WEBSERVER" == "nginx" ]; then
        sudo systemctl restart nginx
    else
        sudo systemctl restart httpd
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

    cat <<- EOF | sudo tee /etc/httpd/conf.d/wordpress$i.conf
<VirtualHost *:$port>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/wordpress$i
        ServerName wordpress$i
        <Directory /var/www/html/wordpress$i>
            AllowOverride All
        </Directory>
        ErrorLog /var/log/httpd/error.log
        CustomLog /var/log/httpd/access.log combined
</VirtualHost>
EOF
    echo -e "\n# Added by Opti-Tool WordPres installation\nListen $port" >> /etc/httpd/conf/httpd.conf
    sudo systemctl restart httpd
}

# Check and install dependencies
deps=("ghostscript" "httpd" "php" "php-bcmath" "php-curl" "php-gd" "php-intl" "php-json" "php-mbstring" "php-mysqlnd" "php-xml" "php-zip" "mariadb-server" "openssl")
for dep in "${deps[@]}"
do
    check_installed "$dep"
done

check_webserver
install_wordpress
configure_database
configure_webserver
configure_apache
