#!/bin/bash

killall openbox

sleep 1

if [ "$1" = "uwsm" ]; then
    exec uwsm start hyprland.desktop
else
    exec start-hyprland
fi
