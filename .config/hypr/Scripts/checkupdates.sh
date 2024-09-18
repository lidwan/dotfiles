#!/bin/bash

# Function to check for updates
check_updates() {
    # Get the number of AUR and repo updates from yay
    yay_updates=$(yay -Qu | wc -l)

    # Get the number of Flatpak updates
    flatpak_updates=$(flatpak update --appstream -y > /dev/null && flatpak remote-ls --updates | wc -l)

    # Calculate total updates
    total_updates=$((yay_updates + flatpak_updates))

    # Display update information based on different cases
    if [ "$yay_updates" -gt 0 ] && [ "$flatpak_updates" -gt 0 ]; then
        # Both AUR and Flatpak updates
        echo "{\"text\": \"$total_updates Update(s), $yay_updates AUR + $flatpak_updates Flatpak\",\"tooltip\":false}"
    elif [ "$yay_updates" -gt 0 ] && [ "$flatpak_updates" -eq 0 ]; then
        # Only AUR updates
        echo "{\"text\": \"$yay_updates Update(s), AUR\",\"tooltip\":false}"
    elif [ "$flatpak_updates" -gt 0 ] && [ "$yay_updates" -eq 0 ]; then
        # Only Flatpak updates
        echo "{\"text\": \"$flatpak_updates Update(s), Flatpak\",\"tooltip\":false}"
    else
        # No updates
        echo ""
    fi
}

check_updates

