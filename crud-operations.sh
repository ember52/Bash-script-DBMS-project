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


# Function for inserting into table
insert_into_table_data() {
    local table_name="$1"
    local meta_file="$database_path/${table_name}-meta.txt"
    # Get column names and constraints from meta file
    column_metadata=$(cat "$database_path/${table_name}-meta.txt")
    IFS=$'\n' read -rd '' -a columns <<< "$column_metadata"
    data=()
    # Prompt user to enter data for each column
    for column_info in "${columns[@]}"; do
        IFS=':' read -ra column <<< "$column_info"
        column_name="${column[0]}"
        data_type="${column[1]}"
        allow_null="${column[2]}"
        allow_unique="${column[3]}"
        is_primary="${column[4]}"
        
        while true; do
            read -p "$(echo -e ${CYAN}"Enter value for '$column_name' (data type: ($data_type) , allow nulls: ($allow_null) , allow unique values: ($allow_unique) ) or type 'exit' to cancel:"${NC}) " value
            # Check if user wants to exit
            if [ "$value" = "exit" ]; then
                echo -e "${YELLOW}Exiting without inserting data.${NC}"
                return 1
            fi

            # Check for empty value when not allowed
            if [ -z "$value" ]; then
                if [ "$allow_null" = "yes" ]; then
                    value="null"
                else
                    echo -e "${RED}Null value is not allowed for column '$column_name'.${NC}"
                    continue
                fi
            fi

            # Check if the value is 'null' and the column does not allow null
            if [ "$value" = "null" ] && [ "$allow_null" != "yes" ]; then
                echo -e "${RED}Null value is not allowed for column '$column_name'.${NC}"
                continue
            fi

            # Validate data type
            if [ "$data_type" = "integer" ]; then
                if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                    echo -e "${RED}Invalid data type for column '$column_name'. Please enter an integer value.${NC}"
                    continue
                fi
            elif [ "$data_type" = "string" ]; then
                # Check if string contains only alphanumeric characters (excluding spaces as the first character)
                if [[ ! "$value" =~ ^[a-zA-Z0-9._%+-@]+$ ]]; then
                    echo -e "${RED}Invalid string format for column '$column_name' strings can only have letters a-z, numbers 0-9 and symbols like(._%+-@) .${NC}"
                    continue
                fi
            fi

            if [ "$allow_unique" = "yes" ] && [ "$value" != "null" ]; then
                # Extract column values from data file
                column_index=$(awk -F ':' -v col="$column_name" '$1 == col { print NR; exit }' "$meta_file")
                column_values=$(awk -F ':' -v idx="$column_index" '{print $idx}' "$database_path/$table_name.txt")
                # Check if value already exists in the column
                unique=true
                for existing_value in $column_values; do
                    if [ "$existing_value" = "$value" ]; then
                        echo -e "${RED}Value '$value' already exists in column '$column_name'.${NC}"
                        unique=false
                        break
                    fi
                done
                if ! $unique; then
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
        echo -e "${RED}Error writing data to table file '$table_name.txt'.${NC}"
        return 1
    }

    echo -e "${GREEN}Data inserted into table '$table_name' successfully.${NC}"
}


# Function for displaying from table

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
    echo -e "${MAGENTA}========================================================================================================================================================${NC}"
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
    echo -e "${MAGENTA}========================================================================================================================================================${NC}"

}


# Function for deleting from table

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
        echo -e "${RED}Error: Filter column '$filter_column' not found.${NC}"
        return 1
    fi

    # Delete rows that match filter criteria
    awk -F ':' -v col="$filter_column_index" -v val="$filter_value" '$col != val' "$data_file" > "$temp_file"
    
    # Compare the original data file with the modified one
    if cmp -s "$data_file" "$temp_file"; then
        echo -e "${YELLOW}No rows were deleted.${NC}"
    else
        mv "$temp_file" "$data_file"
        echo -e "${GREEN}Rows deleted successfully.${NC}"
    fi
}


