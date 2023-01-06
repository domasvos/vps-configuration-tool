#!/bin/bash

selectcms() {

    echo "Select which Content Management System you wish to install [1-6]: "
    echo "1. WordPress"
    echo "2. Joomla"
    echo "3. OpenCart"
    echo "4. Magento"
    echo "5. PrestaShop"
    echo "6. exit"
    read -p "Enter the number of the CMS you wish to install: " choice

    case $choice in
        1)
            echo "You chose WordPress"
            ;;
        2)
            echo "You chose Joomla"
            ;;
        6)
            run=false
            ;;
        *)
            echo "Wrong choice, try again"
    esac
}

run=true
while $run; do
selectcms
done