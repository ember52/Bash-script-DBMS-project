#!/bin/bash

# Define color variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'
LINE='\033[1;37m---------------------------------------------------\033[0m'
source crud_operations.sh
source table-operations.sh

create_database() {
    if [ ! -d "Databases" ]; then
        echo -e "${YELLOW}Creating 'Databases' directory${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        mkdir -p Databases || { echo -e "${RED}Failed to create 'Databases' directory${NC}"; return 1; }
    fi

    while true; do
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        read -p "$(echo -e ${YELLOW}"Enter database name or type 'exit' to cancel: "${NC})" dbname

        if [ "$dbname" = "exit" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${YELLOW}Exiting without creating a database.${NC}"
            break
        fi
        
        if [ "$dbname" = "Databases" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Cannot create a database with the name 'Databases'. Please enter a different name.${NC}"
            continue
        fi

        validate_input "$dbname" "Database name"

        if [ $? -ne 0 ]; then
            continue
        fi

        if [ -d "Databases/$dbname" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Database '$dbname' already exists. Please enter a different name.${NC}"
            continue
        fi

        mkdir "Databases/$dbname" || { echo -e "${RED}Failed to create database '$dbname'${NC}"; return 1; }
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${GREEN}Database '$dbname' created successfully.${NC}"
        break
    done
}

list_databases() {
    if [ ! -d "Databases" ]; then
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${YELLOW}No databases found! ('Databases' directory does not exist)${NC}"
    else
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${BLUE}Listing databases:${NC}"
        if [ ! -r "Databases" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Permission denied. Cannot access 'Databases' directory.${NC}"
        else
            database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -perm /u+rx ! -name "Databases" | wc -l)
            if [ $database_count -eq 0 ]; then
                echo -e "${CYAN}========================================================================================================================================================${NC}"
                echo -e "${YELLOW}No databases found inside the directory 'Databases'.${NC}"
            else
                echo -e "${CYAN}========================================================================================================================================================${NC}"
                echo -e "${CYAN}$database_count databases found:${NC}"
                find Databases -mindepth 1 -maxdepth 1 -type d -perm /u+rx ! -name "Databases" -exec basename {} \;
            fi
        fi
    fi
}

connect_to_database() {
    if [ ! -d "Databases" ]; then
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${RED}No databases found. 'Databases' directory does not exist.${NC}"
        return
    fi

    database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -not -name "Databases" | wc -l)
    if [ "$database_count" -eq 0 ]; then
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${YELLOW}There are no databases available to connect to.${NC}"
        return
    fi

    list_databases

    while true; do
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        read -p "$(echo -e ${YELLOW}"Enter the name of the database to connect to or type 'exit' to cancel: "${NC})" dbname

        if [ "$dbname" = "exit" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${YELLOW}Exiting without connecting to a database.${NC}"
            break
        fi

        validate_input "$dbname" "Database name"

        if [ $? -ne 0 ]; then
            continue
        fi

        if [ ! -d "Databases/$dbname" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Database '$dbname' does not exist. Please enter a valid name or type 'exit' to cancel.${NC}"
            continue
        fi
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${GREEN}Connecting to database '$dbname'...${NC}"
        
        local second_menu="second-menu.sh"
        if [ -f "$second_menu" ]; then
            source "$second_menu" "$dbname"
        else
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Script '$second_menu' not found. (try putting the 'second-menu.sh' in the same path as this script)${NC}"
        fi
        break
    done
}

drop_database() {
    if [ ! -d "Databases" ]; then
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${RED}No databases found. 'Databases' directory does not exist.${NC}"
        return
    fi

    database_count=$(find Databases -mindepth 1 -maxdepth 1 -type d -not -name "Databases" | wc -l)

    if [ "$database_count" -eq 0 ]; then
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${YELLOW}There are no databases to drop.${NC}"
        return
    fi

    while true; do
        list_databases
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        read -p "$(echo -e ${YELLOW}"Enter database name to drop or type 'exit' to cancel: "${NC})" dbname

        if [ "$dbname" = "exit" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${YELLOW}Exiting without dropping a database.${NC}"
            break
        fi
        
        if [ "$dbname" = "Databases" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Cannot access a database with the name 'Databases'. Please enter a different name.${NC}"
            continue
        fi

        validate_input "$dbname" "Database name"

        if [ $? -ne 0 ]; then
            continue
        fi

        if [ ! -d "Databases/$dbname" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${RED}Database '$dbname' does not exist. Please enter a valid name or type 'exit' to cancel.${NC}"
            continue
        fi
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        read -p "Are you sure you want to drop database '$dbname'? (yes/no): " confirm
        while [[ "$confirm" != "yes" && "$confirm" != "no" ]]; do
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            read -p "Invalid input. Please type 'yes' to confirm or 'no' to cancel: " confirm
        done

        if [ "$confirm" != "yes" ]; then
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            echo -e "${YELLOW}Dropping database '$dbname' canceled.${NC}"
            return
        fi

        rm -rf "Databases/$dbname"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        echo -e "${GREEN}Database '$dbname' dropped successfully.${NC}"
        break
    done
}

main_menu() {
    while true; do
        PS3="$(echo -e ${BOLD}${YELLOW}"Please enter your choice (select a number from the above):"${NC})"
        
        echo -e "${BOLD}${CYAN}Welcome to Database Manager!${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"

        options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Quit")

        select opt in "${options[@]}"; do
            case $REPLY in
                1) create_database ;;
                2) list_databases ;;
                3) connect_to_database ;;
                4) drop_database ;;
                5) echo -e "${YELLOW}Exiting.${NC}"; exit ;;
                *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
            esac
            break
        done
    done
}

main_menu
