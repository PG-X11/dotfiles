#!/bin/bash
clear
# Color definitions using only the first letter of each color
r='\033[0;31m' # Red
g='\033[0;32m' # Green
y='\033[0;33m' # Yellow
b='\033[0;34m' # Blue
m='\033[0;35m' # Magenta
c='\033[0;36m' # Cyan
w='\033[0m'    # White / Reset to normal text

# We use 'CAT' with single quotes 'EOF' so Bash leaves the backslashes alone
echo -e "${c}"
cat << 'EOF'
 ___       __   _______   ___       ________  ________  _____ ______   _______
|\  \     |\  \|\  ___ \ |\  \     |\   ____\|\   __  \|\   _ \  _   \|\  ___ \
\ \  \    \ \  \ \  __/|\ \  \    \ \  \___|\ \  \|\  \ \  \\\__\ \  \ \  __/|
 \ \  \  __\ \  \ \  \_|/_\ \  \    \ \  \    \ \  \\\  \ \  \\|__| \  \ \  \_|/__  ___
  \ \  \|\__\_\  \ \  \_|\ \ \  \____\ \  \____\ \  \\\  \ \  \     \ \  \ \  \_|\ \|\  \
   \ \____________\ \_______\ \_______\ \_______\ \_______\ \__\     \ \__\ \_______\ \  \
    \|____________|\|_______|\|_______|\|_______|\|_______|\|__|      \|__|\|________\/  /|
                                                                                          |\___/ /
                                                                                          \|___|/

 ___    ___  _____   _____         ___
|\  \  /  /|/ __  \ / __  \       |\  \
\ \  \/  / |\/_|\  \|\/_|\  \       \ \  \
 \ \    / /\|/ \ \  \|/ \ \  \       \ \  \
  /     \/      \ \  \   \ \  \       \ \__\
 /  /\   \       \ \__\   \ \__\       \|__|
/__/ /\ __\       \|__|    \|__|           ___
|__|/ \|__|                               |\__\
                                           \|__|
EOF
echo -e "${w}"


# 1. Print the menu choices on the screen
echo -e " ${g}1)${w} launch hyprland (Normal)"
echo -e " ${g}2)${w} launch hyprland (UWSM)"
echo -e " ${g}3)${w} launch openbox (X11)"
echo -e " ${g}4)${w} Exit"
echo -e " ${r}x)${w} poweroff"

echo
echo

# 2. Ask the user to type a number and save it in a variable named 'choice'
read -rp "Enter your choice: " choice

# 3. Check what number they typed and do the action
case "$choice" in
    "1")
        clear && exec start-hyprland
        ;;
    "2")
        clear && exec uwsm start hyprland.desktop #sadly moved to uwsm but if the team behind xdg-desktop-portal fixes thiese issues, remove uwsm and edit this and thats all
        ;;
    "3")
        clear && xinit &
        ;;
    "4")
        exit 0
        ;;
    "x")
        echo -e "${r}Powering off in 3 seconds...${w}"
        sleep 3
        poweroff
        ;;
    *)
        echo -e "${r}Invalid option master X11.. ${w}"
        ;;
esac
