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
        read -p "Enter name for column $i or type 'exit' to cancel: " column_name
        validate_input "$column_name" "Column name"
        if [ $? -ne 0 ]; then
            ((i--))  # Decrement i to re-ask for the same column number
            continue
        fi

        if [ "$column_name" = "exit" ]; then
            echo "Exiting without creating a table."
            return 1
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

insert_into_table_data() {
    local table_name="$1"

    # Get column names and constraints from meta file
    column_metadata=$(cat "$database_path/${table_name}-meta.txt")
    IFS=$'\n' read -rd '' -a columns <<< "$column_metadata"

    # Prompt user to enter data for each column
    data=()
    for column_info in "${columns[@]}"; do
        IFS=':' read -ra column <<< "$column_info"
        column_name="${column[0]}"
        data_type="${column[1]}"
        allow_null="${column[2]}"
        allow_unique="${column[3]}"
        is_primary="${column[4]}"

        while true; do
            read -p "Enter value for $column_name (type exit to cancel): " value

            # Check if user wants to exit
            if [ "$value" = "exit" ]; then
                echo "Exiting without inserting data."
                return 1
            fi

            # Check for empty value when not allowed
            if [ -z "$value" ]; then
                if [ "$allow_null" = "yes" ]; then
                    value="null"
                else
                    echo "Null value is not allowed for column '$column_name'."
                    continue
                fi
            fi

            # Check if the value is 'null' and the column does not allow null
            if [ "$value" = "null" ] && [ "$allow_null" != "yes" ]; then
                echo "Null value is not allowed for column '$column_name'."
                continue
            fi

            # Validate data type
            if [ "$data_type" = "integer" ]; then
                if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                    echo "Invalid data type for column '$column_name'. Please enter an integer value."
                    continue
                fi
            elif [ "$data_type" = "string" ]; then
                # Check if string contains only alphanumeric characters (excluding spaces as the first character)
                if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-@]+$ ]]; then
                    echo "Invalid string format for column '$column_name'."
                    continue
                fi
            fi

            # Check for unique constraint
            if [ "$allow_unique" = "yes" ] && [ "$value" != "null" ]; then
                if grep -q "^$value:" "$database_path/$table_name.txt"; then
                    echo "Value '$value' already exists in column '$column_name'."
                    continue
                fi
            fi

            # Check for primary key constraint
            if [ "$is_primary" = "yes" ]; then
                if grep -q "^$value:" "$database_path/$table_name.txt"; then
                    echo "Primary key value '$value' already exists in column '$column_name'."
                    continue
                fi
            fi

            # Add value to data array
            data+=("$value")
            break
        done
    done

    # Write data to table file
    echo "${data[*]}" | tr ' ' ':' >> "$database_path/$table_name.txt" || {
        echo "Error writing data to table file '$table_name.txt'."
        return 1
    }

    echo "Data inserted into table '$table_name' successfully."
}


display_selected_data() {
    local table_name="$1"
    local selected_columns="$2"
    local columns="$3"
    local filter_column="$4"
    local filter_value="$5"
    local data_file="$database_path/${table_name}.txt"
    local meta_file="$database_path/${table_name}-meta.txt"

    # Read column names and their indices from metadata file
    local column_indices=$(awk -F ':' '{print NR-1 ":" $1}' "$meta_file")
    
    # Map selected column numbers to actual column indices
    local selected_indices=""
    IFS=',' read -r -a column_numbers <<< "$selected_columns"
    for col_num in "${column_numbers[@]}"; do
        local index=$((col_num - 1))
        selected_indices+="$index "
    done

    # Display selected column names aligned with data
    local col_names_array=($columns)
    for index in $selected_indices; do
        local col_name=$(awk -v index1="$index" -F ':' '$1 == index1 {print $2}' <<< "$column_indices")
        printf "%-15s" "$col_name"
    done
    echo ""

    # Read and display selected data
    while IFS=':' read -r -a row_data; do
        if [ -n "$filter_column" ]; then
            # Check if row matches filter criteria
            local filter_column_index=$(awk -F ':' -v col="$filter_column" '$1 == col {print NR-1}' "$meta_file")
            local filter_value_found="${row_data[$filter_column_index]}"
            if [ "$filter_value_found" != "$filter_value" ]; then
                continue
            fi
        fi

        for index in $selected_indices; do
            printf "%-15s" "${row_data[$index]}"
        done
        echo ""
    done < "$data_file"
}

delete_rows() {
    local table_name="$1"
    local filter_column="$2"
    local filter_value="$3"
    local data_file="$database_path/${table_name}.txt"
    local meta_file="$database_path/${table_name}-meta.txt"
    local temp_file="/tmp/delete_temp.txt"  

    # Find the filter column index
    local filter_column_index=$(awk -F ':' -v col="$filter_column" '$1 == col { print NR; exit }' "$meta_file")

    # Check if filter column exists
    if [ -z "$filter_column_index" ]; then
        echo "Error: Filter column '$filter_column' not found."
        return 1
    fi

    # Delete rows that match filter criteria
    awk -F ':' -v col="$filter_column_index" -v val="$filter_value" '$col != val' "$data_file" > "$temp_file"
    
    # Compare the original data file with the modified one
    if cmp -s "$data_file" "$temp_file"; then
        echo "No rows were deleted."
    else
        mv "$temp_file" "$data_file"
        echo "Rows deleted successfully."
    fi
}
