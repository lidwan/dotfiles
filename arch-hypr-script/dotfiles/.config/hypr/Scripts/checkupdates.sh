#!/bin/bash

# Function to check for updates
check_updates() {
    updates=$(yay -Qu | wc -l)
    if [ "$updates" -gt 0 ]; then
        echo "{\"text\": \"$updates\",\"tooltip\":false}"
    else
        echo ""
    fi
}
check_updates
