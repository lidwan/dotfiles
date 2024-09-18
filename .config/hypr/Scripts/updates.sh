#!/bin/bash

# Log file path
LOGFILE="$HOME/.config/hypr/Scripts/updates.log"

# Function to print colored text
print_colored() {
    color=$1
    shift
    echo -e "\e[${color}m$@\e[0m"
}

# Function to print the header
print_header() {
    print_colored "34" "================================"
    print_colored "34" "       Update and Backup"
    print_colored "34" "================================"
}

# Function to prompt the user for backup
prompt_backup() {
    echo -n -e "\e[36mDo you want to create a Timeshift backup? [y/N, default is yes]: \e[0m"
    read -r backup_choice

    # Default to yes (backup) if the user just presses enter
    if [ -z "$backup_choice" ] || [[ "$backup_choice" =~ ^[Yy]$ ]]; then
        create_backup
    else
        print_colored "33" "Skipping Timeshift backup."
    fi
}

# Function to ask the user if they want to refresh mirrors
prompt_refresh_mirrors() {
    echo -n -e "\e[36mDo you want to refresh Arch mirrors? [y/N, default is no]: \e[0m"
    read -r refresh_choice

    # Default to no if the user just presses enter or provides no input
    if [[ "$refresh_choice" =~ ^[Yy]$ ]]; then
        refresh_mirrors
        return 0  # Indicates that mirrors were refreshed
    else
        print_colored "33" "Skipping mirror refresh."
        return 1  # Indicates that mirrors were not refreshed
    fi
}

# Function to prompt the user for their choice of update
prompt_user() {
    print_colored "32" "Choose an option:"
    echo -e "\e[33m1)\e[0m Update everything (including --devel)"
    echo -e "\e[33m2)\e[0m Update AUR and official repos only"
    echo -e "\e[33m3)\e[0m Update everything (including Flatpaks)"
    echo -n -e "\e[36mEnter your choice [1, 2, or 3, default is 3]: \e[0m"
    read -r choice

    # Default to option 3 if the user just presses enter
    if [ -z "$choice" ]; then
        choice=3
    fi
}

# Function to refresh mirrors
refresh_mirrors() {
    print_colored "34" "Refreshing Arch mirrors..."
    { time sudo reflector --country Germany,France --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Mirror refresh failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Mirror refresh completed."
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
    clear # Clears if update is completed without errors.
}

# Function to run the update with color output
run_update() {
    command=$1
    print_colored "34" "Running: $command"

    # Ensure color output is preserved
    { time $command --color=always; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Update failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Update process complete."
}

# Function to update Flatpaks
update_flatpaks() {
    print_colored "34" "Updating Flatpaks..."
    { time flatpak update -y; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Flatpak update failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Flatpaks updated successfully."
}

# Main script
clear

# Print header first
print_header

# Start logging
echo "Script started at $(date)" | tee -a "$LOGFILE"

# Prompt user about backup first
prompt_backup

# Prompt user if they want to refresh mirrors
prompt_refresh_mirrors
mirrors_refreshed=$?

# Prompt user for the type of update
prompt_user

# Validate the user's choice and run the appropriate commands
if [ "$choice" == "1" ]; then
    if [ $mirrors_refreshed -eq 0 ]; then
        run_update "yay -Syyuu --devel"
    else
        run_update "yay -Syu --devel"
    fi
elif [ "$choice" == "2" ]; then
    if [ $mirrors_refreshed -eq 0 ]; then
        run_update "yay -Syyuu"
    else
        run_update "yay -Syu"
    fi
elif [ "$choice" == "3" ]; then
    if [ $mirrors_refreshed -eq 0 ]; then
        run_update "yay -Syyuu --devel"
    else
        run_update "yay -Syu --devel"
    fi
    update_flatpaks
elif [ "$choice" == "69" ]; then
    print_colored "32" "...NICE!, THIS IS A TEST CASE, SYSTEM WAS NOT UPDATED OR BACKED UP."
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
