#!/bin/bash

# Open a Rofi menu and save the user's choice into a variable
options=$(printf "Gamemode on\nGamemode off" | rofi -dmenu -p "choose power mode")

# Check what the user selected
case "$options" in
    "Gamemode on")
        # Run the game-on script using absolute paths
        bash /home/a7med/.config/hypr/gaming-mode/game-on.sh
        ;;
    "Gamemode off")
        # Run the game-off script using absolute paths
        bash /home/a7med/.config/hypr/gaming-mode/game-off.sh
        ;;
    *)
        # If the user presses Escape or closes Rofi, exit quietly
        exit 0
        ;;
esac
