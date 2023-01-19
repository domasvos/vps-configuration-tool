#!/bin/bash

selectDB() {

    echo "Select which Content Management System you wish to install."
    echo "1. MariaDB"
    echo "2. MySQL"
    echo "3. PostgreSQL"
    echo "6. exit"
    read -p "Enter the number of the database engine you wish to install [1-6]: " choice

    case $choice in
        1)
            echo "You chose MariaDB"
            ;;
        2)
            echo "You chose MySQL"
            ;;
        3)
            echo "You chose PostgreSQL"
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