#!/bin/bash

# Function to check for updates
check_updates() {
    updates=$(yay -Qu | wc -l)
    if [ "$updates" -gt 0 ]; then
        echo "{\"text\": \"$updates\", \"class\": \"updates-available\"}"
    else
        echo "{\"text\": \"0\", \"class\": \"no-updates\"}"
    fi
}

# Run the check
# yay -Sy
check_updates
