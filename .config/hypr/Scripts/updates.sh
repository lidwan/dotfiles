#!/bin/bash

# Redirect ALL output to both terminal and log
exec > >(tee -a "$HOME/.config/hypr/Scripts/updates.log") 2>&1

# --- Color Definitions ---
C_RESET='\e[0m'
C_BOLD='\e[1m'
C_BLUE='\e[34m'
C_GREEN='\e[32m'
C_YELLOW='\e[33m'
C_RED='\e[31m'
C_CYAN='\e[36m'
C_WHITE='\e[37m'

# --- Emojis for Status ---
TICK="✅"
CROSS="❌"
INFO="ℹ️"
WARN="⚠️"

# --- Helper Functions for Output ---
print_info() {
    echo -e "${C_BOLD}${C_BLUE}${INFO} $@${C_RESET}"
}

print_success() {
    echo -e "${C_BOLD}${C_GREEN}${TICK} $@${C_RESET}"
}

print_warn() {
    echo -e "${C_BOLD}${C_YELLOW}${WARN} $@${C_RESET}"
}

print_error() {
    echo -e "${C_BOLD}${C_RED}${CROSS} $@${C_RESET}"
}

print_prompt() {
    echo -n -e "${C_BOLD}${C_CYAN}? $@${C_RESET}"
}

print_header() {
    echo -e "${C_BOLD}${C_BLUE}=======================================================${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}                Arch Linux Update Helper               ${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}=======================================================${C_RESET}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${C_BOLD}${C_WHITE}--- $@ ---${C_RESET}"
}

# --- Core Script Functions ---

fetch_arch_news() {
    print_step "Checking Arch News"
    print_info "Checking for important announcements from the Arch Linux team..."
    local news
    news=$(curl -s "https://archlinux.org/feeds/news/" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p' | tail -n +2 | head -n 5)

    if [ -n "$news" ]; then
        echo -e "${C_YELLOW}Recent Headlines:${C_RESET}"
        echo "$news" | while IFS= read -r line; do echo "  ◆ $line"; done
        echo ""
        print_prompt "Have you read the news and feel ready to continue? [Y/n]: "
        read -r news_confirm
        if [[ "$news_confirm" =~ ^[Nn]$ ]]; then
            print_error "Cancelled by user. Exiting."
            exit 0
        fi
    else
        print_warn "Could not fetch Arch Linux news. Check your internet connection."
    fi
}

preview_updates() {
    print_step "Previewing Updates"
    print_info "Checking for pending package updates (Offical Arch, AUR, Flatpak)..."

    if [ -z "$repo_updates" ] && [ -z "$aur_updates" ] && [ -z "$flatpak_updates" ]; then
        print_success "Your system is already up to date! No action needed."
        print_prompt "Exit script? [Y/n]: "
        read -r exit_choice
        if [[ -z "$exit_choice" || "$exit_choice" =~ ^[Yy]$ ]]; then
            exit 0
        fi
        return
    fi

    if [ -n "$repo_updates" ]; then
        echo -e "${C_YELLOW}Official Repositories:${C_RESET}"
        echo "$repo_updates"
    fi
    if [ -n "$aur_updates" ]; then
        echo ""
        echo -e "${C_YELLOW}AUR Packages:${C_RESET}"
        echo "$aur_updates"
    fi
    
    if [ -n "$flatpak_updates" ]; then
        echo ""
        echo -e "${C_YELLOW}Flatpak Packages:${C_RESET}"
        echo "$flatpak_updates"
    fi

    echo ""
    print_prompt "Do you want to proceed with installing these updates? [Y/n]: "
    read -r preview_confirm
    if [[ "$preview_confirm" =~ ^[Nn]$ ]]; then
        print_error "Update cancelled by user. Exiting."
        exit 0
    fi
}

prompt_backup() {
    print_step "System Backup"
    print_prompt "Create a Timeshift backup? [y/N]: "
    read -r backup_choice
    if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
        create_backup
    else
        print_warn "Skipping Timeshift backup."
    fi
}

create_backup() {
    print_info "Creating Timeshift backup... (this might take a moment)"
    time sudo timeshift --create --comments "AUTO BY UPDATE SCRIPT"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Backup failed. Check the log for details."
        exit 1
    fi
    print_success "Timeshift backup completed successfully."
    clear
}

prompt_refresh_mirrors() {
    print_step "Pacman Mirrors"
    print_prompt "Refresh Arch mirrors? [y/N]: "
    read -r refresh_choice
    if [[ "$refresh_choice" =~ ^[Yy]$ ]]; then
        print_info "Finding the fastest mirrors in Germany and France..."
        time sudo reflector --country Germany,France --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Mirror refresh failed. Check the log for details."
            exit 1
        fi
        print_success "Mirror list updated."
        update_command="-Syyuu"
        return 0
    else
        print_warn "Skipping mirror refresh."
        return 1
    fi
}

run_update() {
    command=$1
    echo -e "${C_BOLD}${C_WHITE}Running command: ${C_CYAN}$command${C_RESET}"
    time $command --color=always
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Update failed. Check the log for details."
        exit 1
    fi
}

update_with_pacman() {
    run_update "sudo pacman $update_command"
}

# for each AUR pkg show diffs in pkgbuild and ask for user approval before updating.
# I would've used "yay -Syu --answerdiff All" without the loop
# but when the user answers no and skips an update after viewing the diff yay just exits
# instead of skipping update and updating the rest of the pkgs. 
update_with_yay() {  
    print_info "For each AUR pkg press enter to view diff then either agree to update or not."  
    for pkg in $aur_updates; do
        print_prompt "Showing diff for pkg: $pkg "
        read -r
        echo -e "${C_BOLD}${C_WHITE}Running command: ${C_CYAN} yay -S --answerclean None --answerdiff All $pkg{C_RESET}"
        yay -S --answerclean None --answerdiff All $pkg || print_warn "Update failed or skipped for $pkg, continuing..."
        clear
    done
}

update_flatpaks() {
    print_info "Updating Flatpaks..."
    time flatpak update -y
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Flatpak update failed. Check the log for details."
        exit 1
    fi
    print_success "Flatpaks updated successfully."
    
    print_info "Cleaning up unused Flatpak runtimes..."
    time flatpak uninstall --unused -y
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Flatpak cleanup failed. Check the log for details."
        exit 1
    fi
    print_success "Flatpak cleanup completed."
}


# --- Main Script Execution ---
clear

# Start logging
echo "Script started at $(date)"

print_header

# --- Pre-Update Steps ---
update_command="-Syu"

prompt_refresh_mirrors

prompt_backup

fetch_arch_news

# --- Get updates ---
aur_updates=$(yay -Qua | awk '{print $1}')

repo_updates=$(checkupdates)

flatpak_updates=$(flatpak remote-ls --updates)

preview_updates

clear

# --- Update Execution ---
print_step "Performing System Upgrade"

if [ -z "$repo_updates" ] && [ -z "$aur_updates" ]; then
    print_info "No Repo or AUR updates, Skipping..."
elif [ -n "$repo_updates" ] && [ -z "$aur_updates" ]; then
    print_info "No AUR updates found, updating with pacman"
    update_with_pacman
elif [ -z "$repo_updates" ] && [ -n "$aur_updates" ]; then
    print_info "Only AUR updates found, updating with yay"
    update_with_yay
else
    print_info "Both Repo and AUR updates found, updating..."
    print_info "Repo: "
    update_with_pacman
    print_info "AUR: "
    update_with_yay
fi
clear

update_flatpaks

clear

# --- Finalization ---
echo ""
print_success "All tasks completed! Your system is now fully up to date."
echo "Script completed at $(date)"
echo ""
print_info "Press Enter to exit..."
read -r
exit