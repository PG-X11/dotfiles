#!/usr/bin/env bash

# browser

if ! hyprctl clients | grep -q "class: firefox"; then
    firefox &
fi
