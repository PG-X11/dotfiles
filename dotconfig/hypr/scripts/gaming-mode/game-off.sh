#!/bin/bash

pkexec sh -c '
powerprofilesctl set power-saver &&
nvidia-smi -pm 0 &&
echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo
' &

PID=$!

wait $PID

hyprctl keyword animations:enabled true &
hyprctl keyword decoration:blur:enabled true &
hyprctl reload &

notify-send "Gaming mode is OFF"
exit 0
