#!/bin/bash

function check_domain_exists {
  for file in /etc/apache2/sites-available/*.conf; do
    if grep -q "ServerName $1" "$file"; then
      return 0
    fi
  done
  return 1
}

# Ask the user for a domain name
while true; do
  read -p "Enter the domain name: " domain

  if check_domain_exists "$domain"; then
    echo "The domain $domain is already attached to another website."
    echo "Please remove the domain manually or enter a new one."
  else
    break
  fi
done

# List all .conf files in the apache/sites-available directory
echo "Available websites' files:"
ls /etc/apache2/sites-available/*.conf | sed 's/\.conf$//'

# Ask the user which .conf file they want to modify
read -p "Enter the name of the .conf file you want to modify: " conf_file

# Check that the specified .conf file exists
if [ ! -f "/etc/apache2/sites-available/$conf_file.conf" ]; then
  echo "Error: $conf_file.conf does not exist in /etc/apache2/sites-available"
  exit 1
fi

# Add the ServerName directive to the .conf file
sudo sed -i "s/ServerName .*/ServerName $domain/" "/etc/apache2/sites-available/$conf_file.conf"

# Change the port to 80 in the .conf file
sudo sed -i "s/<VirtualHost \*:.*>/<VirtualHost *:80>/" "/etc/apache2/sites-available/$conf_file.conf"

# Restart the Apache web server
sudo systemctl restart apache2

echo "Done!"