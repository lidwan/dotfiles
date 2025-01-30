#!/bin/bash
BATTERY_PATH="/org/freedesktop/UPower/devices/battery_BAT1"

upower --monitor-detail "$BATTERY_PATH" | while read -r line; do
  if [[ "$line" =~ "percentage" ]] || [[ "$line" =~ "state" ]]; then
    PERCENT=$(upower -i "$BATTERY_PATH" | grep "percentage" | awk '{print $2}' | tr -d '%')
    STATE=$(upower -i "$BATTERY_PATH" | grep "state" | awk '{print $2}')

    if [[ "$STATE" == "discharging" ]]; then
      if (( PERCENT <= 10 )); then
        notify-send -u critical "🔋 Battery Low" "${PERCENT}% remaining!"
      fi
    fi
  fi
done
