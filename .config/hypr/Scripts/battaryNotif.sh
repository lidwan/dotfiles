#!/bin/bash

# Get battery capacity from command line argument
CAPACITY=$1

# Check if capacity argument is provided
if [[ -z "$CAPACITY" ]]; then
    echo "Error: Battery capacity argument required"
    exit 1
fi

# Get battery state using upower
STATE=$(upower -i "$(upower -e | grep BAT)" | grep --color=never state | awk '{print $2}')

# Check if battery state command succeeded
if [[ -z "$STATE" ]]; then
    echo "Error: Could not get battery state"
    exit 1
fi

# Define threshold levels
LOW_THRESHOLD=30
MID_THRESHOLD=20
CRITICAL_THRESHOLD=10

# File to store the last notified capacity
STATE_FILE="/tmp/battery_notify_state"

# Read the last notified capacity, or initialize it to an invalid value
if [[ -f "$STATE_FILE" ]]; then
    LAST_NOTIFY=$(<"$STATE_FILE")
    # Validate contents of state file
    if ! [[ "$LAST_NOTIFY" =~ ^-?[0-9]+$ ]]; then
        LAST_NOTIFY=-1
    fi
else
    LAST_NOTIFY=-1
fi

# Handle charging state
if [[ "$STATE" == "charging" ]]; then
    # Reset state file to avoid duplicate notifications when discharging resumes
    echo -1 > "$STATE_FILE"
    exit 0
fi

# Debug output
echo "Current capacity: $CAPACITY%"
echo "Current state: $STATE"
echo "Last notification: $LAST_NOTIFY%"

# Notify at 30% or 20%, ensuring no skipped percentages are missed
if [[ "$CAPACITY" -le "$LOW_THRESHOLD" && "$CAPACITY" -gt "$MID_THRESHOLD" && "$LAST_NOTIFY" -lt "$LOW_THRESHOLD" ]]; then
    notify-send -u normal "Battery Low" "Consider charging soon. ($CAPACITY%)"
    echo "$LOW_THRESHOLD" > "$STATE_FILE"
elif [[ "$CAPACITY" -le "$MID_THRESHOLD" && "$CAPACITY" -gt "$CRITICAL_THRESHOLD" && "$LAST_NOTIFY" -lt "$MID_THRESHOLD" ]]; then
    notify-send -u normal "Battery Very Low" "Charge soon! ($CAPACITY%)"
    echo "$MID_THRESHOLD" > "$STATE_FILE"
# Notify continuously below or at 10% whenever the percentage changes
elif [[ "$CAPACITY" -le "$CRITICAL_THRESHOLD" && "$LAST_NOTIFY" -ne "$CAPACITY" ]]; then
    notify-send -u critical "Battery Critical!" "Charge immediately! ($CAPACITY%)"
    echo "$CAPACITY" > "$STATE_FILE"
fi