#!/bin/bash

# Set the text color to gold
echo -e "\033[33m"

# Display the Linux distro name
cat /etc/os-release | grep '^NAME=' | sed 's/NAME=//g' | tr -d '"'

# Set the text color to red
echo -e "\033[31m"

# Display the disk usage with green and blinking text for used and total amount
df -h | awk 'NR==2{print "Disk Usage: " "\033[32m" "\033[5m" $3 "/" "\033[32m" $2 "\033[0m"}'

# Set the text color to red
echo -e "\033[31m"

# Display the RAM memory usage with green and blinking text for used and total amount
free -h | awk 'NR==2{print "RAM Memory usage: " "\033[32m" "\033[5m" $3 "/" "\033[32m" $2 "\033[0m"}'

# Set the text color to red
echo -e "\033[31m"

# Display the CPU usage with green and blinking text for used and total amount
grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "CPU usage: " "\033[32m" "\033[5m" "%.1f%%/100%%\033[32m\033[5m\n", usage}'

# Set the text color back to the default
echo -e "\033[0m"
