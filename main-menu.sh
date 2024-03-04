#!/bin/bash

create_database() {
    if [ ! -d "Databases" ]; 
    then
        echo "Creating 'Databases' directory"
        mkdir -p Databases || { echo "Failed to create 'Databases' directory"; exit 1; }
    fi

    cd Databases || { echo "Failed to access 'Databases' directory (check the permissions of the 'Databases' directory then retry)"; exit 1; }

    while true; 
    do
        read -p "Enter database name or type 'exit' to cancel: " dbname

        if [ "$dbname" = "exit" ]; 
        then
            echo "Exiting without creating a database."
            break
        fi
        
        if [ "$dbname" = "Databases" ]; then
            echo "Cannot create a database with the name 'Databases'. Please enter a different name."
            continue
        fi

        if [ -z "$dbname" ]; 
        then
            echo "Database name cannot be empty. Please enter a valid name."
            continue
        fi
        if [ ${#dbname} -gt 50 ]; then
            echo "Database name is too long. Please enter a shorter name."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z] ]]; 
        then
            echo "Database name must start with a letter. Please enter a valid name."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z0-9_]+$ ]]; 
        then
            echo "Database name can only contain letters, numbers, and underscores. Please enter a valid name."
            continue
        fi

        if [[ "$dbname" =~ [[:space:]] ]]; 
        then
            echo "Database name cannot contain spaces. Please enter a valid name."
            continue
        fi

        if [ -d "$dbname" ]; 
        then
            echo "Database '$dbname' already exists. Please enter a different name."
            continue
        fi

        mkdir "$dbname" || { echo "Failed to create database '$dbname'"; exit 1; }
        echo "Database '$dbname' created successfully."
        break
    done
    cd .. || { echo "Failed to return to the main directory."; exit 1; }
}

list_databases() {
    if [ ! -d "Databases" ]; then
        echo "no databases found! ( there is no 'Databases' directory, try creating a new database or move the script to the path where this directory exists)."
    else
        echo "Listing databases:"
        if [ ! -r "Databases" ]; then
            echo "Permission denied. Cannot access 'Databases' directory (check the permissions of the 'Databases' directory then retry)."
        else

            database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -perm /u+rx ! -name "Databases" | wc -l)
            if [ $database_count -eq 0 ]; then
                echo "No databases found inside the directory 'Databases'."
            else
                echo "$database_count databases found:"
                find Databases -mindepth 1 -maxdepth 1 -type d -perm /u+rx ! -name "Databases" -exec basename {} \;
            fi
        fi
    fi
}

connect_to_database() {
    if [ ! -d "Databases" ]; then
        echo "No databases found. 'Databases' directory does not exist."
        return
    fi

    database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -not -name "Databases" | wc -l)
    if [ "$database_count" -eq 0 ]; then
        echo "There are no databases available to connect to."
        return
    fi

    list_databases

    while true; do
        read -p "Enter the name of the database to connect to or type 'exit' to cancel: " dbname

        if [ "$dbname" = "exit" ]; then
            echo "Exiting without connecting to a database."
            break
        fi

        if [ -z "$dbname" ]; then
            echo "Database name cannot be empty. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z] ]]; then
            echo "Database name must start with a letter. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Database name can only contain letters, numbers, and underscores. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ "$dbname" =~ [[:space:]] ]]; then
            echo "Database name cannot contain spaces. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [ ! -d "Databases/$dbname" ]; then
            echo "Database '$dbname' does not exist. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        echo "Connecting to database '$dbname'..."
        
        local second_menu="second-menu.sh"
        if [ -f "$second_menu" ]; then
            source "$second_menu" "$dbname"
        else
            echo "Script '$second_menu' not found. (try putting the 'second-menu.sh' in the same path as this script)"
        fi
        break
    done
}


drop_database() {
    if [ ! -d "Databases" ]; then
        echo "No databases found. 'Databases' directory does not exist."
        return
    fi

    database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -not -name "Databases" | wc -l)

    if [ "$database_count" -eq 0 ]; then
        echo "There are no databases to drop."
        return
    fi

    cd Databases || { echo "Failed to access 'Databases' directory."; exit 1; }

    while true; do
        read -p "Enter database name or type 'exit' to cancel: " dbname

        if [ "$dbname" = "exit" ]; then
            echo "Exiting without dropping a database."
            break
        fi
        
        if [ "$dbname" = "Databases" ]; then
            echo "Cannot access a database with the name 'Databases'. Please enter a different name."
            continue
        fi

        if [ -z "$dbname" ]; then
            echo "Database name cannot be empty. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z] ]]; then
            echo "Database name must start with a letter. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ ! "$dbname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            echo "Database name can only contain letters, numbers, and underscores. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [[ "$dbname" =~ [[:space:]] ]]; then
            echo "Database name cannot contain spaces. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        if [ ! -d "$dbname" ]; then
            echo "Database '$dbname' does not exist. Please enter a valid name or type 'exit' to cancel."
            continue
        fi

        rm -rf "$dbname"
        echo "Database '$dbname' dropped successfully."
        break
    done

    cd .. || { echo "Failed to return to the main directory."; exit 1; }
}



main_menu() {
    while true; 
    do
        PS3="Please enter your choice (select a number from the above): "
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

