#!/usr/bin/env bash

# browser

if ! hyprctl clients | grep -q "class: librewolf"; then
    librewolf &
fi
