#!/usr/bin/env bash

# mainTerm

if ! hyprctl clients | grep -q "class: mainTerm"; then
    kitty --app-id mainTerm &
fi

# pipesTerm

if ! hyprctl clients | grep -q "class: pipesTerm"; then
    kitty --app-id pipesTerm -e pipes.sh -t 3 -f 100 -r 300 &
fi
