#!/bin/bash

# Import variables from vars file
source vars

# Determine the package manager
get_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    else
        echo "Unsupported package manager"
        return 1
    fi
}

# Run command with the right package manager
run_cmd() {
    local PACKAGE_MANAGER
    PACKAGE_MANAGER=$(get_package_manager)
    case "$PACKAGE_MANAGER" in
        apt)
            apt-get "$@"
            ;;
        dnf)
            dnf "$@"
            ;;
        yum)
            yum "$@"
            ;;
        *)
            echo "Unsupported package manager"
            return 1
            ;;
    esac
}

# Install web server
install_webserver() {
    echo -e "\033[1m\033[36mPlease choose a web server to install:\033[0m"
    echo -e "\033[32m1. Nginx"
    echo -e "2. Apache\033[0m"
    read -p "Enter the number of your choice (1-2): " choice
    run_cmd update -y

    case "$choice" in
        1)
            run_cmd install -y nginx
            ;;
        2)
            if [ "$distro_base" == "debian" ]; then
                run_cmd install -y apache2 && finalizing
            else
                run_cmd install -y httpd && finalizing
            fi
            ;;
        *)
            # Invalid input
            echo -e "\033[31mInvalid input. Please enter a number between 1 and 2.\033[0m"
            ;;
    esac
}

finalizing() {

    clear
    echo -e "\n+--------------------------+"
    echo -e "| \033[32mINSTALLATION COMPLETED\033[0m |"
    echo -e "+--------------------------+\n"
    
    read -p "Press any key to return to the main menu..."
    return 0

}

# Install the web server and return to start.sh
install_webserver
