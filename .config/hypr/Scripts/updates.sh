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

# Function to fetch and display Arch Linux news
fetch_arch_news() {
    print_colored "34" "Fetching latest Arch Linux news..."
    # Fetch, parse, and display the last 5 news titles.
    local news
    news=$(curl -s "https://archlinux.org/feeds/news/" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' | tail -n +2 | head -n 5)

    if [ -n "$news" ]; then
        print_colored "32" "Recent News Headlines:"
        echo -e "\e[33m"
        echo "$news" | while IFS= read -r line; do echo "  • $line"; done
        echo -e "\e[0m" # Reset color
        echo -n -e "\e[36mHave you read the news? Continue? [Y/n, default is yes]: \e[0m"
        read -r news_confirm
        if [[ "$news_confirm" =~ ^[Nn]$ ]]; then
            print_colored "31" "Cancelled by user. Exiting."
            exit 0
        fi
        print_colored "32" "Proceeding..."
        echo ""
    else
        print_colored "33" "Could not fetch Arch Linux news. Check your internet connection. Continuing..."
    fi
}

# Function to preview available updates
preview_updates() {
    print_colored "34" "--- Checking for available updates ---"
    local repo_updates
    repo_updates=$(checkupdates)
    local aur_updates
    aur_updates=$(yay -Qua)

    if [ -z "$repo_updates" ] && [ -z "$aur_updates" ]; then
        print_colored "32" "System is already up to date."
        # Ask to exit if there are no updates
        echo -n -e "\e[36mExit script? [Y/n, default is yes]: \e[0m"
        read -r exit_choice
        if [[ -z "$exit_choice" || "$exit_choice" =~ ^[Yy]$ ]]; then
            exit 0
        fi
        return # Continue if user wants to do something else (e.g. backup)
    fi

    if [ -n "$repo_updates" ]; then
        print_colored "32" "Official Repositories:"
        echo -e "\e[33m$repo_updates\e[0m"
    fi

    if [ -n "$aur_updates" ]; then
        print_colored "32" "AUR Packages:"
        echo -e "\e[33m$aur_updates\e[0m"
    fi

    echo ""
    echo -n -e "\e[36mDo you want to proceed with the backup and update process? [Y/n, default is yes]: \e[0m"
    read -r preview_confirm
    if [[ "$preview_confirm" =~ ^[Nn]$ ]]; then
        print_colored "31" "Update cancelled by user. Exiting."
        exit 0
    fi
}

# Function to prompt the user for backup
prompt_backup() {
    echo -n -e "\e[36mDo you want to create a Timeshift backup? [y/N, default is no]: \e[0m"
    read -r backup_choice

    # Default to no (skip backup) if the user just presses enter
    if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
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

# Function to update and clean up Flatpaks
update_flatpaks() {
    print_colored "34" "Updating Flatpaks..."
    { time flatpak update -y; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Flatpak update failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Flatpaks updated successfully."
    
    print_colored "34" "Cleaning up unused Flatpak runtimes..."
    { time flatpak uninstall --unused -y; } 2>&1 | tee -a "$LOGFILE"
    if [ $? -ne 0 ]; then
        print_colored "31" "Flatpak cleanup failed. Check the log for details."
        exit 1
    fi
    print_colored "32" "Flatpak cleanup completed."
}

# Main script
clear

# Print header first
print_header

# Fetch and display Arch news before proceeding
fetch_arch_news

# Preview available updates and ask to continue
preview_updates

# Start logging
echo "Script started at $(date)" | tee -a "$LOGFILE"

# Prompt user about backup first
prompt_backup

# Prompt user if they want to refresh mirrors
prompt_refresh_mirrors
mirrors_refreshed=$?

# Perform the update
print_colored "34" "Starting the system update (Official Repos, AUR, Flatpaks)..."
if [ $mirrors_refreshed -eq 0 ]; then
    run_update "yay -Syyuu --devel"
else
    run_update "yay -Syu --devel"
fi
update_flatpaks

print_colored "32" "All tasks completed successfully!"
echo "Script completed at $(date)" | tee -a "$LOGFILE"
# Wait for the user to press Enter before exiting
print_colored "34" "Press Enter to exit..."
read -r
exit
