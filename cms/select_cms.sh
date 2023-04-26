#!/bin/bash
clear
selectCms() {
    echo -e "\033[33mSelect which Content Management System you wish to install (1-4): \033[0m" && sleep 0.3
    echo -e "1. \033[94mWordPress\033[0m" && sleep 0.1
    echo -e "2. \033[34mPresta\033[35mShop\033[0m" && sleep 0.1
    echo -e "3. \033[38;5;39mOpenCart\033[0m" && sleep 0.1
    echo -e "4. \033[31mExit X\033[0m"
    
    read -p "Enter the number of the CMS you wish to install: " choice

    case $choice in
        1)
            echo "You chose WordPress"
            echo "|-----------------|"
            source "$main_pwd/cms/wordpress/wordpress_${distro_base}.sh"
            ;;
        2)
            echo "You chose PrestaShop"
            source "$main_pwd/cms/prestashop/prestashop_${distro_base}.sh"
            ;;
        3)
            echo "You chose OpenCart"
            source "$main_pwd/cms/opencart/opencart_${distro_base}.sh"
            ;;
        4)
            run=false
            ;;
        *)
            echo -e "\033[31mInvalid input. Please enter a number between 1 and 4.\033[0m"
    esac
}

run=true
while $run; do
selectCms
done
