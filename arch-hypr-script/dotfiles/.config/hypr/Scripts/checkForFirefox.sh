#!/bin/bash

# Function to check if a browser is running
check_browser() {
    pgrep -f "firefox|chromium|google-chrome" > /dev/null
    return $?
}

# Function to check if audio is playing
check_audio() {
    pacmd list-sink-inputs | grep -q "state: RUNNING"
    return $?
}

# Main loop
while true; do
    if ! check_browser && ! check_audio; then
        echo "No browser or audio activity detected. Initiating sleep..."
        systemctl suspend
        break
    else
        echo "Browser or audio still active. Waiting..."
    fi
    sleep 60  # Wait for 60 seconds before checking again
done
