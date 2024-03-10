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
LINE='\033[1;37m========================================================================================\033[0m'
echo -e "${BOLD}${CYAN}Welcome to Database Manager!${NC}"
echo -e "${LINE}"
# Accepting the database name as a parameter


database_name="$1"
database_path="Databases/$database_name"

# Function to create a new table
create_table() {
    echo -e "${BOLD}${CYAN}Create a New Table${NC}"
    echo -e "${LINE}"
    while true; do
        read -p "$(echo -e ${YELLOW}"Enter table name or type 'exit' to cancel: "${NC})" table_name

        if [ "$table_name" = "exit" ]; then
            echo -e "${RED}Exiting without creating a table.${NC}"
            return
        fi

        validate_input "$table_name" "Table name"

        if [ $? -ne 0 ]; then
            continue
        fi

        if [ -f "$database_path/$table_name.txt" ] || [ -f "$database_path/${table_name}-meta.txt" ]; then
            echo -e "${RED}Table '$table_name' already exists. Please choose a different name.${NC}"
            continue
        fi

        touch "$database_path/$table_name.txt" || { echo -e "${RED}Failed to create data file for table '$table_name'.${NC}"; return; }
        touch "$database_path/${table_name}-meta.txt" || { echo -e "${RED}Failed to create metadata file for table '$table_name'.${NC}"; return; }
        echo -e "${GREEN}Table '$table_name' created successfully.${NC}"

        # Call function to add columns to the table
        add_columns "$table_name" "$database_path"

        if [ $? -ne 0 ]; then
            # Delete table files if no primary key was selected
            rm "$database_path/$table_name.txt" || { echo -e "${RED}Failed to delete data file for table '$table_name'.${NC}"; return; }
            rm "$database_path/${table_name}-meta.txt" || { echo -e "${RED}Failed to delete metadata file for table '$table_name'.${NC}"; return; }
            echo -e "${RED}Table creation canceled due to the absence of a primary key.${NC}"
            continue
        fi
        break
    done
}

# Function to list tables in the database
list_tables() {
    echo -e "${GREEN}Tables in the database:${NC}"
    echo -e "${LINE}"
    local table_count=$(find "$database_path" -maxdepth 1 -type f -name "*.txt" | grep -c '\-meta\.txt$')

    if [ "$table_count" -eq 0 ]; then
        echo -e "${RED}No tables found in the database.${NC}"
        return 1
    else
        echo -e "${BLUE}Total tables: $table_count${NC}"
        find "$database_path" -maxdepth 1 -type f -name "*.txt" | grep -v '\-meta\.txt$' | sed 's|.*/\(.*\)\.txt|\1|'
        return 0
    fi
}

drop_table() {
    while true; do
        echo -e "${YELLOW}Dropping a table...${NC}"
        echo -e "${LINE}"
        # List existing tables
        list_tables
        # Check if there are no tables
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to list tables(no tables exist). ${NC}"
            return 1
        fi

        # Take input for the table name to drop
        read -p "$(echo -e ${YELLOW}"Enter the name of the table to drop or type 'exit' to cancel: "${NC})" table_name

        # Check if user wants to exit
        if [ "$table_name" = "exit" ]; then
            echo -e "${RED}Exiting without dropping a table.${NC}"
            return 1
        fi

        # Validate input
        validate_input "$table_name" "Table name"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid table name. Please enter a valid table name.${NC}"
            continue
        fi

        # Check if the table file exists
        validate_table_existence "$table_name" "$database_path"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid table name. Table doesn't exist.${NC}"
            continue
        fi

        # Confirm deletion
        read -p "$(echo -e ${YELLOW}"Are you sure you want to drop table '$table_name'? (type yes to confirm / type anything to cancel): "${NC})" confirm
        while [[ "$confirm" != "yes" && "$confirm" != "no" ]]; do
            read -p "$(echo -e ${YELLOW}"Invalid input. Please type 'yes' to confirm or 'no' to cancel: "${NC})" confirm
        done

        if [ "$confirm" != "yes" ]; then
            echo -e "${RED}Dropping table '$table_name' canceled.${NC}"
            return 1
        fi


        # Delete table file and its metadata
        rm "$database_path/$table_name.txt" || { echo -e "${RED}Failed to delete data file for table '$table_name'.${NC}"; return 1; }
        rm "$database_path/${table_name}-meta.txt" || { echo -e "${RED}Failed to delete metadata file for table '$table_name'.${NC}"; return 1; }
        echo -e "${GREEN}Table '$table_name' dropped successfully.${NC}"

        break
    done
}

insert_into_table() {
    echo -e "${BOLD}${CYAN}Insert Into Table${NC}"
    echo -e "${LINE}"
    # List available tables
    list_tables
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to list tables. Exiting insert operation.${NC}"
        return 1
    fi
    # Ask user to select a table
    local table_name
    while true; do
        read -p "$(echo -e ${YELLOW}"Enter the name of the table to insert into or type 'exit' to cancel: "${NC})" table_name
        if [ "$table_name" = "exit" ]; then
            echo -e "${RED}Exiting insert operation.${NC}"
            return 1
        fi

        validate_input "$table_name" "Table name"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid table name. Please enter a valid table name or type 'exit' to cancel.${NC}"
            continue
        fi

        # Check if the table file exists
        validate_table_existence "$table_name" "$database_path"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid table name. Table doesn't exist.${NC}"
            continue
        fi
        break
    done

    insert_into_table_data "$table_name"
}


# Select from table function 
select_from_table() {
    echo -e "${BOLD}${CYAN}Select From Table${NC}"
    echo -e "${LINE}"
    # List available tables
    list_tables
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to list tables. Exiting select operation.${NC}"
        return 1
    fi

    # Prompt user to select a table
    local table_name
    read -p "$(echo -e ${YELLOW}"Enter the name of the table to select from or type 'exit' to cancel: "${NC})" table_name
    if [ "$table_name" = "exit" ]; then
        echo -e "${RED}Exiting select operation.${NC}"
        return 1
    fi

    # Validate table name
    validate_input "$table_name" "Table name"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Please enter a valid table name or type 'exit' to cancel.${NC}"
        return 1
    fi

    
    # Check if the table file exists
    validate_table_existence "$table_name" "$database_path"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Table doesn't exist.${NC}"
        return 1
    fi

    #Get file paths
    local data_file="$database_path/${table_name}.txt"
    local meta_file="$database_path/${table_name}-meta.txt"
    # Get column names from metadata file and number them
    local columns=$(awk -F ':' '{print $1}' "$database_path/${table_name}-meta.txt")
    local column_count=$(echo "$columns" | wc -w)
    local i=1
    echo -e "${GREEN}Column Names:${NC}"
    for col_name in $columns; do
        echo -e "${CYAN}$i. $col_name  ${NC}"
        ((i++))
    done

    # Show numbered column names
    # Prompt user to select columns
    read -p "$(echo -e ${YELLOW}"Enter the numbers of the columns you want to select (separated by commas) or type 'all' to select all columns: "${NC})" selected_columns
    if [ "$selected_columns" = "all" ]; then
        selected_columns=$(seq -s, 1 $column_count)
    fi

    if [ -z "$selected_columns" ]; then
        echo -e "${RED}Invalid column number '$col_num'. Please enter valid column numbers.${NC}"
        return 1 
    fi

    # Validate selected column numbers
    IFS=',' read -r -a column_numbers <<< "$selected_columns"
    for col_num in "${column_numbers[@]}"; do
        if ! [[ "$col_num" =~ ^[1-$column_count]$ ]]; then
            echo -e "${RED}Invalid column number '$col_num'. Please enter valid column numbers.${NC}"
            return 1
        fi
    done

    # Prompt user for filter column and value
    local filter_column
    local filter_value
    read -p "$(echo -e ${YELLOW}"Enter the name of the filter column or leave blank for no filter: "${NC})" filter_column
    if [ -n "$filter_column" ]; then
        validate_input "$filter_column" "Filter column"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Invalid filter column name. Please enter a valid column name or leave blank for no filter.${NC}"
            return 1
        fi
        read -p "$(echo -e ${YELLOW}"Enter the value to filter by: "${NC})" filter_value
    fi

    # Display selected data
    display_selected_data "$table_name" "$selected_columns" "$columns" "$filter_column" "$filter_value"
}


# Delete from table function 
delete_from_table() {
    echo -e "${BOLD}${CYAN}Delete From Table${NC}"
    echo -e "${LINE}"
    # List available tables
    list_tables
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to list tables. Exiting delete operation.${NC}"
        return 1
    fi

    # Prompt user to select a table
    local table_name
    read -p "$(echo -e ${YELLOW}"Enter the name of the table to delete from or type 'exit' to cancel: "${NC})" table_name
    if [ "$table_name" = "exit" ]; then
        echo -e "${RED}Exiting delete operation.${NC}"
        return 1
    fi

    # Validate table name
    validate_input "$table_name" "Table name"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Please enter a valid table name or type 'exit' to cancel.${NC}"
        return 1
    fi

    validate_table_existence "$table_name" "$database_path"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid table name. Table doesn't exist.${NC}"
        return 1
    fi

    # Get column names from metadata file and number them
    local columns=$(awk -F ':' '{print $1}' "$database_path/${table_name}-meta.txt")
    local i=1
    echo -e "${GREEN}Column Names:${NC}"
    for col_name in $columns; do
        echo -e "${CYAN}$i. $col_name  ${NC}"
        ((i++))
    done

    # Prompt user for filter column and value
    local filter_column
    local filter_value
    while true; do
        read -p "$(echo -e ${YELLOW}"Enter the name of the filter column: "${NC})" filter_column
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

    read -p "$(echo -e ${YELLOW}"Enter the value to filter by: "${NC})" filter_value

    # Delete rows based on filter criteria
    delete_rows "$table_name" "$filter_column" "$filter_value"
}

# Update table function
update_from_table() {
    echo "Update from table:"

    # List available tables
    list_tables
    if [ $? -ne 0 ]; then
        echo "Failed to list tables. Exiting update operation."
        return 1
    fi

    # Prompt user to select a table
    local table_name
    read -p "$(echo -e ${CYAN}"Enter the name of the table to update or type 'exit' to cancel: "${NC}) " table_name

    if [ "$table_name" = "exit" ]; then
        echo "Exiting update operation."
        return 0
    fi

    # Validate table name
    validate_input "$table_name" "Table name"
    if [ $? -ne 0 ]; then
        echo "Invalid table name. Please enter a valid table name or type 'exit' to cancel."
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


# Main function for the second menu
second_menu() {
    echo -e "${BOLD}${CYAN}Welcome to the Second Menu for Database: $database_name${NC}"
    echo -e "${LINE}"

    while true; do
        PS3="$(echo -e ${YELLOW}"Database (${database_name}) >> Please select an option: "${NC})"
        options=("Create Table" "List Tables" "Drop Table" "Insert Into Table" "Select From Table" "Delete From Table" "Update Table" "Return to Main Menu")

        select opt in "${options[@]}"; do
            case $REPLY in
                1) create_table ;;
                2) list_tables ;;
                3) drop_table ;;
                4) insert_into_table ;;
                5) select_from_table ;;
                6) delete_from_table ;;
                7) update_from_table ;;
                8) echo -e "${GREEN}Returning to main menu.${NC}"; return ;;
                *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
            esac
            break
        done
    done
}

# Call the second menu function to start the application
second_menu