#!/usr/bin/env bash
scrdr="$HOME/Pictures/Screenshots"
mkdir -p "$scrdr"

# Generate a unique timestamped filename
filename="$scrdr/screenshot-$(date +%Y%m%d-%H%M%S).png"

## Screen shot function
grim -g "$(slurp)" -t ppm - | satty --filename - --fullscreen --output-filename "$filename" --early-exit

# Handle the clipboard seamlessly with your background cliphist daemon
if [ -f "$filename" ]; then
    (
        sleep 0.1
        cliphist store < "$filename"
        wl-copy -t image/png < "$filename"
    ) &
fi
