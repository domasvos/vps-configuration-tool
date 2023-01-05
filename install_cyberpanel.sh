#!/bin/bash

# Install CyberPanel
sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)

# Check if the Linux distro is Ubuntu
if grep -q 'Ubuntu' /etc/issue; then
    # Stop the firewalld service and disable it
    systemctl stop firewalld && systemctl disable firewalld

    # Reboot the system
    reboot
fi
