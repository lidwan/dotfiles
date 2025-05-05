#!/bin/bash

# To be called on screenshot to save and copy png to clipboard.
# hypr Bind: "bind = , Print, exec, ~/.config/hypr/scripts/screenshot_copy_save.sh"

# Directory to save screenshots
SAVE_DIR="${HOME}/Pictures"

# Create a temporary file for the screenshot
TMP_FILE=$(mktemp "/tmp/screenshot_XXXXXX.png")

# Capture the selected region into the temporary file
# Use grim's ability to save directly to a file path
grim -g "$(slurp -d)" "$TMP_FILE"

# Check if the screenshot was successfully created
if [ -f "$TMP_FILE" ] && [ -s "$TMP_FILE" ]; then
    # Define the final filename
    SAVE_FILE="$SAVE_DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

    # Copy the temp file to the final save location
    cp "$TMP_FILE" "$SAVE_FILE"

    # Copy the contents of the temp file to the clipboard
    wl-copy -t image/png < "$TMP_FILE"

    # Optional: Notify user
    notify-send "Screenshot" "Saved to $SAVE_FILE and copied to clipboard."

else
    # Optional: Notify on failure
    notify-send "Screenshot Failed" "Could not capture or file is empty."
fi

# Clean up the temporary file
rm "$TMP_FILE"

exit 0
