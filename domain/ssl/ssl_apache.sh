#!/bin/bash

clear
function check_package_installed() {
  if command -v apt-get &> /dev/null; then
    dpkg -s "$1" &> /dev/null
  elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
    rpm -q "$1" &> /dev/null
  else
    echo "Unsupported package manager. Please install Certbot manually."
    return 1
  fi
}

function install_certbot() {
  if command -v apt-get &> /dev/null; then
    sudo apt-get install -y certbot python3-certbot-apache
  elif command -v dnf &> /dev/null; then
    sudo dnf install -y certbot python3-certbot-apache
  elif command -v yum &> /dev/null; then
    sudo yum install -y certbot python3-certbot-apache
  else
    echo "Unsupported package manager. Please install Certbot manually."
    return 1
  fi
}

function list_domain_names() {
  if [ -d "/etc/apache2/sites-available" ]; then
    for file in /etc/apache2/sites-available/*.conf; do
      grep -oP "ServerName\s+\K[^ \n]+" "$file"
    done
  elif [ -d "/etc/httpd/conf.d" ]; then
    for file in /etc/httpd/conf.d/*.conf; do
      grep -oP "ServerName\s+\K[^ \n]+" "$file"
    done
  else
    echo "No supported web server found."
    return 1
  fi
}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "SSL" "Installation Completed"
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Website URL" "https://$domain" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
}

# Install Certbot if it's not already installed
if ! check_package_installed "certbot"; then
  install_certbot
fi

# List available domain names
echo "Available domains:"
list_domain_names

# Ask the user for the domain they want to install the SSL certificate for
read -p "Enter the domain you want to install SSL certificate for: " domain

# Install the SSL certificate for the specified domain
sudo certbot --apache -d "$domain"

# Restart the Apache web server
if command -v apache2 &> /dev/null; then
  sudo systemctl restart apache2 && finalizing
elif command -v httpd &> /dev/null; then
  sudo systemctl restart httpd && finalizing
else
  echo "No supported web server found."
  return 1
fi
