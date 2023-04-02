#!/bin/bash

selectCms() {

    echo "Select which Content Management System you wish to install [enter the number of the choice]: "
    echo $(pwd)
    echo "1. WordPress"
    echo "2. PrestaShop"
    echo "3. OpenCart"
    echo "6. exit"
    read -p "Enter the number of the CMS you wish to install: " choice

    case $choice in
        1)
            echo "You chose WordPress"
            echo "|-----------------|"
            bash "$(pwd)/cms/wordpress/wordpress_debian.sh"
            ;;
        2)
            echo "You chose PrestaShop"
            bash "$(pwd)/cms/prestashop/prestashop_debian.sh"
            ;;
        3)
            echo "You chose OpenCart"
            bash "$(pwd)/cms/opencart/opencart_debian.sh"
            ;;
        6)
            run=false
            ;;
        *)
            echo "This choice does not exist, try again"
    esac
}

run=true
while $run; do
selectCms
done