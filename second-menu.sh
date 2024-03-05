#!/bin/bash
source table-operations.sh
# Accepting the database name as a parameter
database_name="$1"

create_table() {
    local database_path="Databases/$database_name"

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
        break
    done
}

list_tables() {
    echo "Function for listing tables goes here"
}

drop_table() {
    echo "Function for dropping a table goes here"
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

second_menu

