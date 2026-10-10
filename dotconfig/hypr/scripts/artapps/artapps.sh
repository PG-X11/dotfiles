#!/bin/bash

# Get mouse position from Hyprland
pos=$(hyprctl cursorpos)
x=${pos%,*}
y=${pos#*,}

options=$(printf "blender\nkrita\ndarktable\naseprite\nopentabletdriver" | rofi \
    -dmenu -p '' \
    -config '/home/a7med/.config/hypr/scripts/artapps/rofi/config.rasi'
)
# note : if you change the location of any of the appimages or executables then you have (ofc) change them here too, but its fine just test if it works and fix it later
case "$options" in
    "blender")
        /home/a7med/.local/bin/blender
        ;;

    "krita")
        env QT_QPA_PLATFORM=xcb /home/a7med/Desktop/Apps/Art-apps/krita-5.3.1-x86_64.AppImage
        ;;

    "darktable")
        /home/a7med/Desktop/Apps/Art-apps/Darktable-5.4.1-x86_64.AppImage
        ;;

    "aseprite")
        aseprite
        ;;
            "opentabletdriver")
        otd-daemon & disown && otd-gui
        ;;
esac
