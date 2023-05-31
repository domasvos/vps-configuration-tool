#!/bin/bash

function check_domain_exists {
  for file in /etc/nginx/conf.d/*; do
    if grep -q "server_name $1" "$file"; then
      return 0
    fi
  done
  return 1
}

finalizing() {
    # Set the text color to gold
    clear
    echo -e "\033[33m"

    # Print table header
    printf "+-------------------+------------------------------------+\n"
    printf "| %-17s | %-34s |\n" "Domain" "Configuration completed"
    printf "+-------------------+------------------------------------+\n"

    # Print table rows with blinking values
    printf "| \033[31m%-17s\033[33m | \033[5m%-34s\033[0m\033[33m |\n" "Website URL" "http://$domain" && sleep 0.1

    # Print table footer
    printf "+-------------------+------------------------------------+\n"
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

# Get the IP address associated with the domain
domain_ip=$(dig +short $domain @8.8.8.8)

# Check if the domain points to the host IP
if [ "$ip_address" != "$domain_ip" ]; then
    echo -e "\e[31mWarning: The domain $domain does not seem to be pointed to this server's IP address ($ip_address).\e[0m"

    while true; do
        read -p "Do you want to continue? [y/n]: " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) return;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# List all configuration files in the nginx/conf.d directory
echo "Available websites' files:"
ls /etc/nginx/conf.d/*.conf | sed -e 's/\.conf$//' -e 's|/etc/nginx/conf.d/||'

# Ask the user which configuration file they want to modify
read -p "Enter the name of the configuration file you want to modify: " conf_file

# Check that the specified configuration file exists
if [ ! -f "/etc/nginx/conf.d/$conf_file.conf" ]; then
  echo "Error: $conf_file.conf does not exist in /etc/nginx/conf.d"
  return 1
fi

# Check if the server_name directive exists in the configuration file
if grep -q "server_name " "/etc/nginx/conf.d/$conf_file.conf"; then
  # Replace the server_name directive with the chosen domain name
  sudo sed -i "s/server_name .*/server_name $domain;/" "/etc/nginx/conf.d/$conf_file.conf"
  # Replace the listen directive with port 80
  sudo sed -i "s/listen .*/listen 80;/" "/etc/nginx/conf.d/$conf_file.conf"

else
  # Insert a new server_name directive with the chosen domain name after the listen directive
  sudo sed -i "/listen .*/a server_name $domain;" "/etc/nginx/conf.d/$conf_file.conf"
fi

# Restart the Nginx web server
sudo systemctl restart nginx && finalizing