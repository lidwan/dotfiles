#!/bin/bash

# Get battery capacity from command line argument
CAPACITY=$1

# Only proceed if we have a capacity value
[[ -z "$CAPACITY" ]] && exit 0

# Define threshold levels
LOW_THRESHOLD=30
MID_THRESHOLD=20
CRITICAL_THRESHOLD=10

# File to store the last notified capacity
STATE_FILE="/tmp/battery_notify_state"

# Only check battery state if we're at or below the LOW_THRESHOLD
# This avoids running upower command unnecessarily
if [[ "$CAPACITY" -le "$LOW_THRESHOLD" ]]; then
    STATE=$(upower -i "$(upower -e | grep BAT)" | grep --color=never state | awk '{print $2}')
    
    # Exit if charging or can't get state
    [[ -z "$STATE" || "$STATE" == "charging" ]] && {
        [[ -f "$STATE_FILE" ]] && echo -1 > "$STATE_FILE"
        exit 0
    }
    
    # Read last notify state only when needed
    LAST_NOTIFY=$([[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "-1")
    
    # Validate state file contents
    [[ ! "$LAST_NOTIFY" =~ ^-?[0-9]+$ ]] && LAST_NOTIFY=-1
    
    # Send notifications based on thresholds
    if [[ "$CAPACITY" -le "$LOW_THRESHOLD" && "$CAPACITY" -gt "$MID_THRESHOLD" && "$LAST_NOTIFY" -ne "$LOW_THRESHOLD" ]]; then
        notify-send -u normal "Battery Low" "Consider charging soon. ($CAPACITY%)"
        echo "$LOW_THRESHOLD" > "$STATE_FILE"
    elif [[ "$CAPACITY" -le "$MID_THRESHOLD" && "$CAPACITY" -gt "$CRITICAL_THRESHOLD" && "$LAST_NOTIFY" -ne "$MID_THRESHOLD" ]]; then
        notify-send -u normal "Battery Very Low" "Charge soon! ($CAPACITY%)"
        echo "$MID_THRESHOLD" > "$STATE_FILE"
    elif [[ "$CAPACITY" -le "$CRITICAL_THRESHOLD" && "$LAST_NOTIFY" -ne "$CAPACITY" ]]; then
        notify-send -u critical "Battery Critical!" "Charge immediately! ($CAPACITY%)"
        echo "$CAPACITY" > "$STATE_FILE"
    fi
fi