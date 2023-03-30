#!/bin/bash

function check_domain_exists {
  for file in /etc/nginx/sites-available/*; do
    if grep -q "server_name $1" "$file"; then
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

# List all configuration files in the nginx/sites-available directory
echo "Available websites' files:"
ls /etc/nginx/sites-available/

# Ask the user which configuration file they want to modify
read -p "Enter the name of the configuration file you want to modify: " conf_file

# Check that the specified configuration file exists
if [ ! -f "/etc/nginx/sites-available/$conf_file" ]; then
  echo "Error: $conf_file does not exist in /etc/nginx/sites-available"
  exit 1
fi

# Add the server_name directive to the configuration file
sudo sed -i "s/server_name .*/server_name $domain;/" "/etc/nginx/sites-available/$conf_file"

# Restart the Nginx web server
sudo systemctl restart nginx

echo "Done!"
