#!/bin/bash

edit_option=$(printf "Presets\nBlur-control\nTransparency-control") | rofi \
 -dmenu \
 -config '/home/a7med/Bookmarks/hypr/scripts/hypr-options/rofi/config-2.rasi' \
 -theme-str 'textbox#title { str: "Hypr Options"; }'



