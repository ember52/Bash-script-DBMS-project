#! /bin/bash
# Define color variables
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'
BOLD='\033[1m'
LINE='\033[1;37m========================================================================================\033[0m'
# Update table function
update_from_table() {
    echo -e "${YELLOW}Update from table:${NC}"

    # List available tables
    list_tables
    if [ $? -ne 0 ]; then
        echo -e "${CYAN}Failed to list tables. Exiting update operation.${NC}"
        return 1
    fi

    # Prompt user to select a table
    local table_name
    read -p "$(echo -e ${CYAN}"Enter the name of the table to update or type 'exit' to cancel: "${NC}) " table_name

    if [ "$table_name" = "exit" ]; then
        echo -e "${CYAN}Exiting update operation.${NC}"
        return 0
    fi

    # Validate table name
    validate_input "$table_name" "Table name"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Please enter a valid table name or type 'exit' to cancel.${NC}"
        return 1
    fi

    # Check if the table exists
    validate_table_existence "$table_name" "$database_path"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Table doesn't exist.${NC}"
        return 1
    fi

    select_filter_column "$table_name" "$database_path" 
}

#Functions for updating table:

select_filter_column () {
    local table_name="$1"
    local database_path="$2"
    local meta_file="$database_path/${table_name}-meta.txt"
    # Get column names from metadata file
    local columns=$(awk -F ':' '{print $1}' "$database_path/${table_name}-meta.txt")
    local i=1
    echo -e "${YELLOW}Column Names:${NC}"
    for col_name in $columns; do
        echo -e "${CYAN} $i. $col_name${NC}"

        ((i++))
    done

    # Prompt user to select a column to match
    local filter_column
    local filter_column_index
    
    # Validate the entered column against available columns
    while true; do
        read -p "$(echo -e ${CYAN}"Enter the name of the filter column or type 'exit' to cancel: "${NC}) " filter_column

        if [ "$filter_column" = "exit" ]; then
            echo -e "${CYAN}Exiting update operation.${NC}"
            return 0
        fi

        validate_input "$filter_column" "Filter column"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid filter column name. Please enter a valid column name.${NC}"
            continue
        fi
        local valid_column=false
        for col in $columns; do
            if [ "$filter_column" = "$col" ]; then
                valid_column=true
                break
            fi
        done
        if [ "$valid_column" = false ]; then
            echo -e "${RED}Invalid filter column name. Please enter a valid column name.${NC}"

            continue
        fi
        break
    done

    local j=1
    for col in $columns; do
         if [ "$filter_column" = "$col" ]; then
            filter_column_index=$j
            break
        fi
        ((j++))
    done

    # Prompt user for the value to match in the selected column
    

    # Get the values of the selected column
    local column_values=$(awk -F ':' -v idx="$filter_column_index" '{print $idx}' "$database_path/${table_name}.txt")
    select_update_column "$table_name" "$database_path" "$columns" "$filter_column" "$filter_column_index" "$column_values"
}

select_update_column() {
    local table_name="$1"
    local database_path="$2"
    local columns="$3"
    local filter_column="$4"
    local filter_column_index="$5"
    local column_values="$6"

    local data_file="$database_path/${table_name}.txt"
    local meta_file="$database_path/${table_name}-meta.txt"
    while true; do
    local filter_value
    read -p "$(echo -e ${CYAN}"Enter the value to match in the column '$filter_column': "${NC}) " filter_value

        if echo "$column_values" | grep -qw "$filter_value"; then
            # Prompt user to select columns to update
            local update_columns=""
            local update_column_indices=""
            local update_values=""

            echo -e "${YELLOW}Available Columns:${NC}"
            for col_name in $columns; do
                echo -e "${CYAN}$col_name ${NC}"
            done

            while true; do
                read -p "$(echo -e "${CYAN}Enter the name of the update column or 'exit' to cancel (or 'done' to finish): ${NC}")" update_column

                if [ "$update_column" = "exit" ]; then
                echo -e "${YELLOW}Exiting update operation.${NC}"
                return 0
                fi

                if [ "$update_column" = "done" ]; then
                    break
                fi
                validate_input "$update_column" "Update column"
                if [ $? -ne 0 ]; then
                    echo -e "${RED}Invalid update column name. Please enter a valid column name.${NC}"
                    continue
                fi

                if ! [[ $columns =~ $update_column ]]; then
                    echo -e "${RED}Invalid column name. Please enter a valid column name.${NC}"
                    continue
                fi

                update_columns+="$update_column,"
            done
            
            update_columns=$(echo "$update_columns" | sed 's/,$//')

            if [ -z "$update_columns" ]; then
                echo -e "${RED}No columns selected for update. Exiting...${NC}"

                return 0
            fi

            # Get indices of update columns
            for col in $(echo "$update_columns" | tr ',' '\n'); do
                local idx=1
                for col_name in $columns; do
                    if [ "$col" = "$col_name" ]; then
                        update_column_indices+="$idx,"
                        break
                    fi
                    ((idx++))
                done
            done

            
            local data_types=$(awk -F ':' '{print $2}' "$meta_file")
            local allow_nulls=$(awk -F ':' '{print $3}' "$meta_file")
            local allow_uniques=$(awk -F ':' '{print $4}' "$meta_file")
            
            update_column_indices=$(echo "$update_column_indices" | sed 's/,$//')


            i=0
            # Convert update_column_indices string to an array
            IFS=',' read -ra update_column_indices_array <<< "$update_column_indices"

            # Loop over the elements of update_columns array
            for col in $(echo "$update_columns" | tr ',' '\n'); do
                # Get the index of the current column
                index=${update_column_indices_array[$i]}

                local new_value
                read -p "$(echo -e "${CYAN}Enter the new value for column '$col': ${NC}")" new_value

                local update_column_type=$(echo "$data_types" | cut -d $'\n' -f "$index")
                local allow_null=$(echo "$allow_nulls" | cut -d $'\n' -f "$index")
                local allow_unique=$(echo "$allow_uniques" | cut -d $'\n' -f "$index")

                if [ -z "$new_value" ]; then
                    if [ "$allow_null" = "yes" ]; then
                        new_value="null"
                    else
                        echo -e "${RED}Null value is not allowed for column '$col'.${NC}"
                        return 0
                    fi
                fi
                
                # Check if the value is 'null' and the column does not allow null
                if [ "$new_value" = "null" ] && [ "$allow_null" != "yes" ]; then
                    echo -e "${RED}Null value is not allowed for column '$col'.${NC}"
                    return 0
                fi

                if [ "$update_column_type" = "integer" ]; then
                    if ! [[ "$new_value" =~ ^[0-9]+$ ]]; then
                        echo -e "${RED}Invalid value. Column '$col' requires an integer value.${NC}"
                        return 0
                    fi
                elif [ "$update_column_type" = "string" ]; then
                    if [[ ! "$new_value" =~ ^[a-zA-Z0-9._%+-@]+$ ]]; then
                        echo -e "${RED}Invalid value. Column '$col' requires a string value.${NC}"

                        return 0
                    fi
                fi

                if [ "$allow_unique" = "yes" ]; then
                    # Extract column values from data file
                    column_values=$(awk -F ':' -v idx="${update_column_indices_array[$i]}" '{print $idx}' "$database_path/$table_name.txt")
                    # Check if value already exists in the column
                    unique=true
                    for existing_value in $column_values; do
                        # Skip null values
                        if [ "$existing_value" = "null" ]; then
                            continue
                        fi
                        
                        if [ "$existing_value" = "$new_value" ]; then
                            echo -e "${RED}Value '$new_value' already exists in column '$col'.${NC}"
                            unique=false
                            break
                        fi
                    done
                    if ! $unique; then
                        return 1
                    fi
                fi

                update_values+="$new_value,"

                ((i++))
            done


            update_values=$(echo "$update_values" | sed 's/,$//')

            awk -F':' -v filter_column_index="$filter_column_index" -v filter_value="$filter_value" -v update_column_indices="$update_column_indices" -v update_values="$update_values" '
                BEGIN {
                    OFS=":";
                    split(update_column_indices, update_cols, ",");
                    split(update_values, values, ",");
                }
                {
                    if ($filter_column_index == filter_value) {
                        for (i in update_cols) {
                            $(update_cols[i]) = values[i];
                        }
                    }
                    print $0;
                }' "$data_file" > temp_file && mv temp_file "$data_file"
            
            echo -e "${YELLOW}Table '$table_name' updated successfully.${NC}"
            return 0

        else
            echo -e "${YELLOW}Value '$filter_value' not found in the column '$filter_column'.${NC}"
            continue
        fi
    done
}

