#!/bin/bash

validate_input() {
    local input="$1"
    local error_message="$2"

    if [ -z "$input" ]; then
        echo "$error_message cannot be empty. Please enter a valid input."
        return 1
    fi

    if [ ${#input} -gt 50 ]; then
        echo "$error_message name is too long. Please enter a shorter name."
        return 1
    fi

    if [[ "$input" =~ [[:space:]] ]]; then
        echo "$error_message cannot contain spaces. Please enter a valid input."
        return 1
    fi

    if [[ ! "$input" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "$error_message must start with a letter and can only contain letters, numbers, and underscores."
        return 1
    fi

    return 0
}

add_columns() {
    local table_name="$1"
    local database_path="$2"
    local meta_file="$database_path/${table_name}-meta.txt"
    local primary_key_selected=false

    while true; do
        read -p "Enter the number of columns for the table (max 20): " num_columns
        if ! [[ "$num_columns" =~ ^[1-9]$|^1[0-9]$|^20$ ]]; then
            echo "Invalid input. Please enter a number between 1 and 20."
            continue
        else
            break
        fi
    done

    for ((i = 1; i <= num_columns; i++)); do
        read -p "Enter name for column $i: " column_name
        validate_input "$column_name" "Column name"
        if [ $? -ne 0 ]; then
            ((i--))  # Decrement i to re-ask for the same column number
            continue
        fi

        read -p "Enter data type for column $column_name (string/integer): " data_type
        if [[ "$data_type" != "string" && "$data_type" != "integer" ]]; then
            echo "Invalid data type. Please enter 'string' or 'integer'."
            ((i--))  # Decrement i to re-ask for the same column number
            continue
        fi

        read -p "Allow null values for column $column_name? (yes/no): " allow_null
        if [[ "$allow_null" != "yes" && "$allow_null" != "no" ]]; then
            echo "Invalid input. Please enter 'yes' or 'no'."
            ((i--))  
            continue
        fi

        read -p "Allow unique values for column $column_name? (yes/no): " allow_unique
        if [[ "$allow_unique" != "yes" && "$allow_unique" != "no" ]]; then
            echo "Invalid input. Please enter 'yes' or 'no'."
            ((i--))  
            continue
        fi

        if [ "$primary_key_selected" = false ]; then
            read -p "Is column $column_name the primary key? (yes/no): " is_primary
            if [[ "$is_primary" != "yes" && "$is_primary" != "no" ]]; then
                echo "Invalid input. Please enter 'yes' or 'no'."
                ((i--))  
                continue
            fi

            if [ "$is_primary" = "yes" ]; then
                if [ "$allow_null" = "yes" ]; then
                    echo "Error: Primary key column '$column_name' cannot allow null values."
                    return 1
                fi
                if [ "$allow_unique" = "no" ]; then
                    echo "Error: Primary key column '$column_name' must have unique values."
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
        echo "Error: At least one column must be selected as the primary key."
        return 1
    fi

    echo "Columns added successfully."
}





