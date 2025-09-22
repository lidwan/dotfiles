#!/bin/bash

# Log file path
LOGFILE="$HOME/.config/hypr/Scripts/updates.log"

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
ROCKET="🚀"
NEWS="📰"
EYES="👀"
SAVE="💾"
WORLD="🌍"
BOX="📦"

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
    print_step "${NEWS} Step 1: Checking Arch News"
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
    print_step "${EYES} Step 2: Previewing Updates"
    print_info "Checking for pending package updates (Repo, AUR, Flatpak)..."
    local repo_updates
    repo_updates=$(checkupdates)
    local aur_updates
    aur_updates=$(yay -Qua)
    local flatpak_updates
    flatpak_updates=$(flatpak remote-ls --updates)

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
        echo -e "${C_CYAN}Official Repositories:${C_RESET}"
        echo "$repo_updates"
    fi
    if [ -n "$aur_updates" ]; then
        echo -e "${C_YELLOW}AUR Packages:${C_RESET}"
        echo "$aur_updates"
    fi
    
    if [ -n "$flatpak_updates" ]; then
        echo -e "${C_BOLD}${C_WHITE}${BOX} Flatpak Packages:${C_RESET}"
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
    print_step "${SAVE} Step 3: System Backup"
    print_info "Creating a system snapshot with Timeshift is highly recommended before updating."
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
    { time sudo timeshift --create --comments "AUTO BY SCRIPT"; } 2>&1 | tee -a "$LOGFILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Backup failed. Check the log for details."
        exit 1
    fi
    print_success "Timeshift backup completed successfully."
    clear
}

prompt_refresh_mirrors() {
    print_step "${WORLD} Step 4: Pacman Mirrors"
    print_info "Refreshing your mirror list can increase download speeds."
    print_prompt "Refresh Arch mirrors? [y/N]: "
    read -r refresh_choice
    if [[ "$refresh_choice" =~ ^[Yy]$ ]]; then
        print_info "Finding the fastest mirrors in Germany and France..."
        { time sudo reflector --country Germany,France --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist; } 2>&1 | tee -a "$LOGFILE"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Mirror refresh failed. Check the log for details."
            exit 1
        fi
        print_success "Mirror list updated."
        return 0
    else
        print_warn "Skipping mirror refresh."
        return 1
    fi
}

run_update() {
    command=$1
    echo -e "${C_BOLD}${C_WHITE}Running command: ${C_CYAN}$command${C_RESET}"
    { time $command --color=always; } 2>&1 | tee -a "$LOGFILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Update failed. Check the log for details."
        exit 1
    fi
}

update_flatpaks() {
    print_info "Updating Flatpaks..."
    { time flatpak update -y; } 2>&1 | tee -a "$LOGFILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Flatpak update failed. Check the log for details."
        exit 1
    fi
    print_success "Flatpaks updated successfully."
    
    print_info "Cleaning up unused Flatpak runtimes..."
    { time flatpak uninstall --unused -y; } 2>&1 | tee -a "$LOGFILE"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Flatpak cleanup failed. Check the log for details."
        exit 1
    fi
    print_success "Flatpak cleanup completed."
}

# --- Main Script Execution ---
clear
print_header

# --- Pre-Update Steps ---
fetch_arch_news
preview_updates

# Start logging for the main actions
echo "Script started at $(date)" | tee -a "$LOGFILE"

prompt_backup
prompt_refresh_mirrors
mirrors_refreshed=$?

# --- Update Execution ---
print_step "${ROCKET} Step 5: Performing System Upgrade"
print_info "This is the final step. The system will now be fully updated."

if [ $mirrors_refreshed -eq 0 ]; then
    run_update "yay -Syyuu --devel"
else
    run_update "yay -Syu --devel"
fi

update_flatpaks

# --- Finalization ---
echo ""
print_success "All tasks completed! Your system is now fully up to date."
echo "Script completed at $(date)" | tee -a "$LOGFILE"
echo ""
print_info "Press Enter to exit..."
read -r
exit
