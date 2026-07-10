#!/usr/bin/env bash

# clock
#
if ! hyprctl clients | grep -q "class: clock"; then
    kitty --app-id clock -o font_size=20 tty-clock -t -b -c
fi
# custom made clock :
# if ! hyprctl clients | grep -q "class: clock"; then
#     kitty --app-id clock -o python ~/.local/bin/clockV2
# fi
