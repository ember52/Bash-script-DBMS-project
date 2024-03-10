#!/bin/bash

# Define color variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BLACK='\033[1;30m'
NC='\033[0m' # No Color

validate_input() {
    local input="$1"
    local error_message="$2"

    if [ -z "$input" ]; then
        echo -e "${RED}${error_message} cannot be empty. Please enter a valid input.${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        return 1
    fi

    if [ ${#input} -gt 50 ]; then
        echo -e "${RED}${error_message} name is too long. Please enter a shorter name.${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        return 1
    fi

    if [[ "$input" =~ [[:space:]] ]]; then
        echo -e "${RED}${error_message} cannot contain spaces. Please enter a valid input.${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        return 1
    fi

    if [[ ! "$input" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo -e "${RED}${error_message} must start with a letter and can only contain letters, numbers, and underscores.${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        return 1
    fi

    return 0
}

# Function to validate table name
validate_table_existence() {
    local table_name="$1"
    local database_path="$2"
    local data_file="${database_path}/${table_name}.txt"
    local meta_file="${database_path}/${table_name}-meta.txt"
    if [ ! -f "$data_file" ]; then
        return 1
    fi

    if [ ! -f "$meta_file" ]; then
        return 1
    fi
}


add_columns() {
    local table_name="$1"
    local database_path="$2"
    local meta_file="$database_path/${table_name}-meta.txt"
    local primary_key_selected=false
    local column_names=()
    while true; do
        read -p "$(echo -e ${CYAN}"Enter the number of columns for the table (max 20): "${NC}) " num_columns
        if ! [[ "$num_columns" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
            echo -e "${RED}Invalid input. Please enter a number between 1 and 20.${NC}"
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            continue
        else
            break
        fi
    done

    for ((i = 1; i <= num_columns; i++)); do
        while true; do
            read -p "$(echo -e ${CYAN}"Enter name for column $i or type 'exit' to cancel: "${NC}) " column_name
            validate_input "$column_name" "Column name"
            if [ $? -ne 0 ]; then
                continue
            fi

            if [ "$column_name" = "exit" ]; then
                echo -e "${YELLOW}Exiting without creating a table.${NC}"
                return 1
            fi

            if [[ "${column_names[*]}" =~ "$column_name" ]]; then
                echo -e "${RED}Column name '$column_name' already exists. Please enter a unique column name.${NC}"
                echo -e "${CYAN}========================================================================================================================================================${NC}"
                continue
            fi

            column_names+=("$column_name")
            break
        done

        read -p "$(echo -e ${CYAN}"Enter data type for column $column_name (string/integer): "${NC}) " data_type
        if [[ "$data_type" != "string" && "$data_type" != "integer" ]]; then
            echo -e "${RED}Invalid data type. Please enter 'string' or 'integer'.${NC}"
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            ((i--))  # Decrement i to re-ask for the same column number
            continue
        fi

        read -p "$(echo -e ${CYAN}"Allow null values for column $column_name? (yes/no): "${NC}) " allow_null
        if [[ "$allow_null" != "yes" && "$allow_null" != "no" ]]; then
            echo -e "${RED}Invalid input. Please enter 'yes' or 'no'.${NC}"
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            ((i--))  
            continue
        fi

        read -p "$(echo -e ${CYAN}"Allow unique values for column $column_name? (yes/no): "${NC}) " allow_unique
        if [[ "$allow_unique" != "yes" && "$allow_unique" != "no" ]]; then
            echo -e "${RED}Invalid input. Please enter 'yes' or 'no'.${NC}"
            echo -e "${CYAN}========================================================================================================================================================${NC}"
            ((i--))  
            continue
        fi

        if [ "$primary_key_selected" = false ]; then
            read -p "$(echo -e ${CYAN}"Is column $column_name the primary key? (yes/no): "${NC}) " is_primary
            if [[ "$is_primary" != "yes" && "$is_primary" != "no" ]]; then
                echo -e "${RED}Invalid input. Please enter 'yes' or 'no'.${NC}"
                echo -e "${CYAN}========================================================================================================================================================${NC}"
                ((i--))  
                continue
            fi

            if [ "$is_primary" = "yes" ]; then
                if [ "$allow_null" = "yes" ]; then
                    echo -e "${RED}Error: Primary key column '$column_name' cannot allow null values.${NC}"
                    echo -e "${CYAN}========================================================================================================================================================${NC}"
                    return 1
                fi
                if [ "$allow_unique" = "no" ]; then
                    echo -e "${RED}Error: Primary key column '$column_name' must have unique values.${NC}"
                    echo -e "${CYAN}========================================================================================================================================================${NC}"
                    return 1
                fi
                primary_key_selected=true
            fi
        else
            is_primary="no"
        fi

        # Append column metadata to the meta file
        echo "$column_name:$data_type:$allow_null:$allow_unique:$is_primary" >> "$meta_file"
    done

    if [ "$primary_key_selected" = false ]; then
        echo -e "${RED}Error: At least one column must be selected as the primary key.${NC}"
        echo -e "${CYAN}========================================================================================================================================================${NC}"
        return 1
    fi

    echo -e "${GREEN}Columns added successfully.${NC}"
}

