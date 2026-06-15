#!/usr/bin/env bash

# --autocopy: Automatically sends the picked color to wl-copy
# --format=hex: Outputs color in pure clean #RRGGBB format
COLOR=$(hyprpicker --autocopy --format=hex)

# Notify the user with the code
if [ -n "$COLOR" ]; then
    notify-send "Color Picker" "Copied $COLOR to clipboard"
fi
