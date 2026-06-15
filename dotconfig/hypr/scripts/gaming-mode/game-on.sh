#!/bin/bash

pkexec sh -c '
powerprofilesctl set performance &&
nvidia-smi -pm 1 &&
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
' &

PID=$!

wait $PID

hyprctl keyword animations:enabled false &
hyprctl keyword decoration:blur:enabled false &

notify-send "Game mode is ON!"
exit 0
