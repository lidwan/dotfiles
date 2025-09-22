#!/bin/bash

# Function to check for updates
check_updates() {
    # --- Repo Updates ---
    repo_updates=$(checkupdates 2>/dev/null | wc -l)

    # --- AUR Updates ---
    aur_updates=$(yay -Qua 2>/dev/null | wc -l)
    
    # Combine repo and AUR counts
    total_repo_aur_updates=$((repo_updates + aur_updates))

    # --- Flatpak Updates ---
    flatpak update --appstream -y > /dev/null 2>&1
    flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)

    # Calculate total updates
    total_updates=$((total_repo_aur_updates + flatpak_updates))

    # Display update information based on different cases
    if [ "$total_repo_aur_updates" -gt 0 ] && [ "$flatpak_updates" -gt 0 ]; then
        # Both Repo/AUR and Flatpak updates
        echo "{\"text\": \"$total_updates Updates, $total_repo_aur_updates P, $flatpak_updates F\",\"tooltip\":false}"
    elif [ "$total_repo_aur_updates" -gt 0 ] && [ "$flatpak_updates" -eq 0 ]; then
        # Only Repo/AUR updates
        echo "{\"text\": \"$total_repo_aur_updates Update(s), Pacman/AUR\",\"tooltip\":false}"
    elif [ "$flatpak_updates" -gt 0 ] && [ "$total_repo_aur_updates" -eq 0 ]; then
        # Only Flatpak updates
        echo "{\"text\": \"$flatpak_updates Update(s), Flatpak\",\"tooltip\":false}"
    elif [ "$total_updates" -eq 0 ]; then
         # No updates, output empty string
         echo ""
    else
         # Fallback, output empty string
         echo ""
    fi
}

check_updates