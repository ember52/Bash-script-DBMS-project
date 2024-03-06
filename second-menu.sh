#!/bin/bash

# Accepting the database name as a parameter
database_name="$1"
database_path="Databases/$database_name"

# Function to create a new table
create_table() {
    while true; do
        read -p "Enter table name or type 'exit' to cancel: " table_name

        if [ "$table_name" = "exit" ]; then
            echo "Exiting without creating a table."
            return
        fi

        validate_input "$table_name" "Table name"

        if [ $? -ne 0 ]; then
            continue
        fi

        if [ -f "$database_path/$table_name.txt" ] || [ -f "$database_path/${table_name}-meta.txt" ]; then
            echo "Table '$table_name' already exists. Please choose a different name."
            continue
        fi

        touch "$database_path/$table_name.txt" || { echo "Failed to create data file for table '$table_name'."; return; }
        touch "$database_path/${table_name}-meta.txt" || { echo "Failed to create metadata file for table '$table_name'."; return; }
        echo "Table '$table_name' created successfully."

        # Call function to add columns to the table
        add_columns "$table_name" "$database_path"

        if [ $? -ne 0 ]; then
            # Delete table files if no primary key was selected
            rm "$database_path/$table_name.txt" || { echo "Failed to delete data file for table '$table_name'."; return; }
            rm "$database_path/${table_name}-meta.txt" || { echo "Failed to delete metadata file for table '$table_name'."; return; }
            echo "Table creation canceled due to the absence of a primary key."
            continue
        fi
        break
    done
}

# Function to list tables in the database
list_tables() {
    echo "Tables in the database:"
    local table_count=$(find "$database_path" -maxdepth 1 -type f -name "*.txt" | grep -c '\-meta\.txt$')

    if [ "$table_count" -eq 0 ]; then
        echo "No tables found in the database."
    else
        echo "Total tables: $table_count"
        find "$database_path" -maxdepth 1 -type f -name "*.txt" | grep -v '\-meta\.txt$' | sed 's|.*/\(.*\)\.txt|\1|'
    fi
}




drop_table() {
    while true; do
        echo "Dropping a table..."

        # List existing tables
        list_tables

        # Check if there are no tables
        if [ ! -n "$(ls -A $database_path/*.txt 2>/dev/null)" ]; then
            echo "No tables found in the database."
            return 1
        fi

        # Take input for the table name to drop
        read -p "Enter the name of the table to drop or type 'exit' to cancel: " table_name

        # Check if user wants to exit
        if [ "$table_name" = "exit" ]; then
            echo "Exiting without dropping a table."
            return 1
        fi

        # Validate input
        validate_input "$table_name" "Table name"
        if [ $? -ne 0 ]; then
            echo "Invalid table name. Please enter a valid table name."
            continue
        fi

        # Check if the table file exists
        if [ ! -f "$database_path/$table_name.txt" ]; then
            echo "Table '$table_name' does not exist."
            continue
        fi

        # Confirm deletion
        read -p "Are you sure you want to drop table '$table_name'? (type yes to confirm / type anything to cancel): " confirm
        while [[ "$confirm" != "yes" && "$confirm" != "no" ]]; do
            read -p "Invalid input. Please type 'yes' to confirm or 'no' to cancel: " confirm
        done

        if [ "$confirm" != "yes" ]; then
            echo "Dropping table '$table_name' canceled."
            return 1
        fi


        # Delete table file and its metadata
        rm "$database_path/$table_name.txt" || { echo "Failed to delete data file for table '$table_name'."; return 1; }
        rm "$database_path/${table_name}-meta.txt" || { echo "Failed to delete metadata file for table '$table_name'."; return 1; }
        echo "Table '$table_name' dropped successfully."

        break
    done
}



insert_into_table() {
    echo "Function for inserting into a table goes here"
}

select_from_table() {
    echo "Function for selecting from a table goes here"
}

delete_from_table() {
    echo "Function for deleting from a table goes here"
}

update_from_table() {
    echo "Function for updating from a table goes here"
}

# Main function for the second menu
second_menu() {
    echo "Welcome to the Second Menu for Database: $database_name"

    while true; do
        PS3="Please select an option (select a number from the above): "
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
                8) echo "Returning to main menu."; return ;;
                *) echo "Invalid option. Please try again." ;;
            esac
            break
        done
    done
}

# Call the second menu function to start the application
second_menu
