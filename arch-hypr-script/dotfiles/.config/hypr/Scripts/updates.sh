#!/bin/bash

# Log file path
LOGFILE="$HOME/.config/hypr/Scripts/updates.log"

# Function to print colored text
print_colored() {
    color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

# Function to prompt the user for their choice
prompt_user() {
    print_colored "34" "================================"
    print_colored "34" "       Update and Backup"
    print_colored "34" "================================"
    print_colored "32" "Choose an option:"
    print_colored "32" "Note that the script will make a timeshift backup either way"
    echo -e "\e[33m1)\e[0m Update everything (including --devel)"
    echo -e "\e[33m2)\e[0m Update AUR and official repos only"
    echo -n -e "\e[36mEnter your choice [1 or 2, default is 1]: \e[0m"
    read -r choice
    
    # Default to option 1 if the user just presses enter
    if [ -z "$choice" ]; then
        choice=1
    fi
}

# Function to create a Timeshift backup
create_backup() {
    print_colored "34" "Creating Timeshift backup..."
    { time sudo timeshift --create --comments "AUTO BY SCRIPT"; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Backup failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Backup completed."
    clear #clears if update is completed without errors.
}

# Function to run the update
run_update() {
    command=$1
    print_colored "34" "Running: $command"

    { time $command; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Update failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Update process complete."
}

# Main script
clear

# Start logging
echo "Script started at $(date)" | tee -a "$LOGFILE"

prompt_user

# Validate the user's choice and run the appropriate commands, 69 choice is for testing purpuses.
if [ "$choice" == "1" ]; then
    create_backup
    run_update "yay -Syyu --devel"
elif [ "$choice" == "2" ]; then
    create_backup
    run_update "yay -Syyu"
elif [ "$choice" == "69" ]; then
    print_colored "32" "...NICE!, THIS IS A TEST CASE, SYSTEM WAS NOT UPDATED OR BACKED UP"
else
    print_colored "31" "Invalid choice. Exiting."
    exit 1
fi

print_colored "32" "All tasks completed successfully!"
echo "Script completed at $(date)" | tee -a "$LOGFILE"

# Wait for the user to press Enter before exiting
print_colored "34" "Press Enter to exit..."
read -r
exit
