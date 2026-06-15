#!/usr/bin/env bash

# QMPlay2

if ! hyprctl clients | grep -q "class: QMPlay2"; then
    QMPlay2 &
fi

# cavaTerm

if ! hyprctl clients | grep -q "class: cavaTerm"; then
    kitty --app-id cavaTerm -e cava &
fi

# rangerTerm

if ! hyprctl clients | grep -q "class: rangerTerm"; then
    kitty --app-id rangerTerm -e ranger /home/a7med/Music &
fi
