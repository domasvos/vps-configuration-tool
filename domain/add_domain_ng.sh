#!/bin/bash

function check_domain_exists {
  for file in /etc/nginx/conf.d/*; do
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

# List all configuration files in the nginx/conf.d directory
echo "Available websites' files:"
ls /etc/nginx/conf.d/

# Ask the user which configuration file they want to modify
read -p "Enter the name of the configuration file you want to modify: " conf_file

# Check that the specified configuration file exists
if [ ! -f "/etc/nginx/conf.d/$conf_file" ]; then
  echo "Error: $conf_file does not exist in /etc/nginx/conf.d"
  exit 1
fi

# Check if the server_name directive exists in the configuration file
if grep -q "server_name " "/etc/nginx/conf.d/$conf_file"; then
  # Replace the server_name directive with the chosen domain name
  sudo sed -i "s/server_name .*/server_name $domain;/" "/etc/nginx/conf.d/$conf_file"
else
  # Insert a new server_name directive with the chosen domain name after the listen directive
  sudo sed -i "/listen .*/a server_name $domain;" "/etc/nginx/conf.d/$conf_file"
fi

# Restart the Nginx web server
sudo systemctl restart nginx

echo "Done!"
