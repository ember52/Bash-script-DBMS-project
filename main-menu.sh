#!/bin/bash

create_database() {
    if [ ! -d "Databases" ]; then
        echo "Creating 'Databases' directory"
        mkdir Databases
    fi

    cd Databases || exit

    while true; do
        read -p "Enter database name: " dbname

        if [ -z "$dbname" ]; then
            echo "Database name cannot be empty. Please enter a valid name."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z] ]]; then
            echo "Database name must start with a letter. Please enter a valid name."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Database name can only contain letters, numbers, and underscores. Please enter a valid name."
            continue
        fi

        if [[ "$dbname" =~ [[:space:]] ]]; then
            echo "Database name cannot contain spaces. Please enter a valid name."
            continue
        fi

        if [ -d "$dbname" ]; then
            echo "Database '$dbname' already exists. Please enter a different name."
            continue
        fi

        mkdir "$dbname"
        echo "Database '$dbname' created successfully."
        break
    done

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

