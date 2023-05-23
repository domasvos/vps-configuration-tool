#!/bin/bash

function check_domain_exists {
  local domain_dir
  if command -v apache2 &> /dev/null; then
    domain_dir="/etc/apache2/sites-available"
  elif command -v httpd &> /dev/null; then
    domain_dir="/etc/httpd/conf.d"
  else
    echo "No supported web server found."
    return 1
  fi

  for file in "$domain_dir"/*.conf; do
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

if command -v apache2 &> /dev/null; then
  config_dir="/etc/apache2/sites-available"
elif command -v httpd &> /dev/null; then
  config_dir="/etc/httpd/conf.d"
else
  echo "No supported web server found."
  return 1
fi

# List all .conf files in the configuration directory
echo "Available websites' files:"
ls "$config_dir"/*.conf | sed -e 's/\.conf$//' -e "s|$config_dir/||"

# Ask the user which .conf file they want to modify
read -p "Enter the name of the .conf file you want to modify: " conf_file

# Check that the specified .conf file exists
if [ ! -f "$config_dir/$conf_file.conf" ]; then
  echo "Error: $conf_file.conf does not exist in $config_dir"
  return 1
fi

# Add the ServerName directive to the .conf file
sudo sed -i "s/ServerName .*/ServerName $domain/" "$config_dir/$conf_file.conf"

# Change the port to 80 in the .conf file
sudo sed -i "s/<VirtualHost \*:.*>/<VirtualHost *:80>/" "$config_dir/$conf_file.conf"

# Restart the Apache web server
if command -v apache2 &> /dev/null; then 
  sudo systemctl restart apache2 && echo "Done!"
elif command -v httpd &> /dev/null; then
  sudo systemctl restart httpd && echo "Done!"
else
  echo "No supported web server found."
  return 1
fi

## Check if domain is pointed
# Get the IP address of the current host
#host_ip=$(curl -s https://ipinfo.io/ip)

# Get the IP address associated with the domain
#domain_ip=$(dig +short $domain @8.8.8.8)

# Check if the domain points to the host IP
#if [ "$host_ip" != "$domain_ip" ]; then
#    echo "Warning: The domain $domain does not seem to be pointed to this server's IP address ($host_ip)."
#
#    while true; do
#        read -p "Do you want to continue? [y/n]: " yn
#        case $yn in
#            [Yy]* ) break;;
#            [Nn]* ) exit;;
#            * ) echo "Please answer yes or no.";;
#        esac
#    done
#fi
