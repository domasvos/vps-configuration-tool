#!/bin/bash

# Check if the Linux distro is Ubuntu
if grep -q 'Ubuntu' /etc/issue; then
    # Display a warning message
    echo -e "\033[31m\033[5m[WARNING] ONCE PROMPTED - REFUSE VPS RESTART AFTER CYBERPANEL INSTALLATION. YOUR VPS WILL REBOOT AUTOMATICALLY ONCE EVERYTHING IS DONE.\033[0m"

    echo "Installation will start in ->"
    # Display the countdown
    for ((i=10; i>0; i--)); do
        echo -n "$i "
        sleep 1
    done
    echo

    # Install CyberPanel
    sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)

    # Stop the firewalld service and disable it
    systemctl stop firewalld && systemctl disable firewalld

    # Reboot the system
    reboot
fi
