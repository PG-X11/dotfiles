#!/usr/bin/env bash

# mainTerm

if ! hyprctl clients | grep -q "class: mainTerm"; then
    kitty --app-id mainTerm &
fi

# pipesTerm

if ! hyprctl clients | grep -q "class: pipesTerm"; then
    kitty --app-id pipesTerm -e pipes.sh &
fi
