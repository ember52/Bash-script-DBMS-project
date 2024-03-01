#!/bin/bash

create_database() {

    if [ ! -d "Databases" ]; 
    then
        echo "Creating 'Databases' directory"
        mkdir Databases
    fi
    cd Databases || exit

    read -p "Enter database name: " dbname

    if [ -d "$dbname" ]; 
    then
        echo "Database '$dbname' already exists."
    else
        mkdir "$dbname"
        echo "Database '$dbname' created successfully."
    fi
    cd ..
}


list_databases() {
    echo "Listing databases"
}


connect_to_database() {
    echo "Connecting to a database"
}


drop_database() {
    echo "Dropping a database"
}


main_menu() {
    while true; 
    do
        PS3="Please enter your choice: "
        options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Quit")

        select opt in "${options[@]}"; 
        do
            case $REPLY in
                1) create_database ;;
                2) list_databases ;;
                3) connect_to_database ;;
                4) drop_database ;;
                5) echo "Exiting."; exit ;;
                *) echo "Invalid option. Please try again." ;;
            esac
            break
        done
    done
}
echo "Welcome to my DBMS"

main_menu

