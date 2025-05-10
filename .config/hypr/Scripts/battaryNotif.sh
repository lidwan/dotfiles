#!/bin/bash
BATTERY_PATH="/org/freedesktop/UPower/devices/battery_BAT1"

upower --monitor-detail "$BATTERY_PATH" | \
grep --line-buffered -E 'percentage|state' | \
while read -r line; do
  CURRENT_PERCENT=$(upower -i "$BATTERY_PATH" | grep "percentage" | awk '{print $2}' | tr -d '%')
  CURRENT_STATE=$(upower -i "$BATTERY_PATH" | grep "state" | awk '{print $2}')

  if [[ "$CURRENT_STATE" == "discharging" ]]; then
    if (( CURRENT_PERCENT <= 10 )); then
      notify-send -u critical "🔋 Battery Low" "${CURRENT_PERCENT}% remaining!"
    fi
  fi
done
