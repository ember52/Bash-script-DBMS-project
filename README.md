# Implementing DBMS using BASH Scripting

# About the Project
### - A simple DBMS (database management system) which uses the directories as databases and tables resemble files that store the data
### - The program has many features similar to a real DBMS like (creating a database, dropping a database,listing existing databases, connecting to a database)
### - The program aslo lets you manipulate the databases by (creating, dropping,listing) tables inside each database
### - Every table has 4 basic operations to be done (insering data, deleting data, reading data, updating data)

# Description
### The project aims to simulate a DBMS using the directories as databases that store files as tables, Each database has naming constraints (there can't be a database named 'Databases' ) because all the directories are stored in a database with that name.
### Every table name or database name has specific constraints to match while creating them  (it must start with alpha numeric characters and must not have spaces in between ).
### All of the scripts must be in the same path when running the program
### The project scripts must be in the same path as the main directory 'Databases' to locate the data or it will create a new main directory

### The project consists of 5 main scripts which are:

> Main menu
> second menu
> table operations
> crud operations
> update from table

### The program is started using the main menu script and it will call the other scripts as source to use the same shell.
### And each script handles specific tasks 
## Starting with the main menu:
### It shows the user the main menu with the following options:
- Create Database
- List Databases
- Connect To Database
- Drop Database
- Quit
 
![WhatsApp Image 2024-03-10 at 21 21 53_ee204241](https://github.com/ember52/Bash-script-DBMS-project/assets/117265490/f21e3729-4a24-4c6c-98d0-af1969211672)

### - The Create database option checks for the existence directory 'Databases' (and creates it if it doesn't exist) then allows the user create a directory with the name he inputs (except any directory named 'Databases') (after being validated) which will store the tables as files.
### - The list database option allows the user to view the directories (except any directory named 'Databases') in the directory 'Databases'.
### - The Connect to database option allows the user to connect to one of the databases present in the directory 'Databases' which will show the second menu for table related operations.
### - The Drop database option allows the user to remove a database directory (except any directory named 'Databases') which acts as dropping the database with all of its tables and data.
### - Lastly the user can quit the program using the 4th option to finish using the script.

## After connecting to the database:
### It shows the user the second menu with the following options:

- Create Table
- List Tables
- Drop Table
- Insert into Table
- Select From Table
- Delete From Table
- Update table
- Return to Main Menu

![WhatsApp Image 2024-03-10 at 21 21 57_5b0fbe94](https://github.com/ember52/Bash-script-DBMS-project/assets/117265490/b156c762-7e3a-42a2-b448-7b03fa4a491d)

### - The Create table option allows the user to create a new table which will take the table name from the user and create 2 files (tablename.txt and tablename-meta.txt), The user will then enter the number of columns in that tables and enter the constraints for each column (name, data type, allows null, unique, primary key), it will keep asking for every column if it will be the primary key or not and won't ask again once a primary key is assigned, all the metadata of the taable will be stored in the 'tablename-meta.txt'
### - The List tables option will show the user all the table names present in the current directory that have both data file and meta file (it won't show the table name if one of the files is not existing).
### - The Drop table option will allow the user to delete a table from the database (it deletes both files).
### - The Insert into table option will allow the user to enter values into a table, it will show the user the column name and it's constraints and will validate his input then successfully input the data into the data file.
### - The select from table option allows the user to select a table to view its data, ask the user to enter the columns he wants to view (the columns will be numbered and the input should be numbers separated by commas), then it will ask the user if he wants to filter the data by a specific column name and will ask for the value to match in that column, then it will show the column names he selected and the values matched in a table view.
### - The Delete from table option allows the user to delete rows from the database by selecting the table he wants to delete from then specifying the column to filter the data by and finally giving the value to locate the fields which will get their rows deleted.
### - The Update table option allows the user to to update multiple fields in the table he selects by firstly inputting the column name to filter by and its value to locate the rows which will be updated, Then it will keep asking the user for the fields that will be updated untill he inputs 'done' then it will take the new value for each field and validate them according to the constraints of each column.
### - The last option is for returning to the main menu to do Database operations or switch to another table.

## File system:
### - The data of each table is stored in a (.txt) file which stores the data rows in every line and every field is separated by a colon ':' for filtering.
### - The metadata of each table is stored in a (-meta.txt) file which stores the names and constraints of each folder in a row and every field is separated by a colon ':' which separates every constraint from each other for easier filtering (every row is a column).
