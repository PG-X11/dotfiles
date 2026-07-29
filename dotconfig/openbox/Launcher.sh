#!/bin/bash

# --- 1. INSTANT CLEANUP ---
pkill -9 steam 2>/dev/null
pkill -9 steamwebhelper 2>/dev/null

# --- 2. HARDWARE OVERCLOCK & LATENCY REDUCTION ---
export vblank_mode=0
export __GL_MaxFramesAllowed=1

# NVIDIA Graphics Card variables
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Force NVIDIA Maximum Performance Mode
nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" >/dev/null 2>&1 &

# Disable screen blanking and mouse acceleration
xset -dpms s off s noblank
xset m 0 0
xset b off

# --- 3. CPU PERFORMANCE GOVERNOR ---
if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance
fi

# --- 4. DISPLAY CONFIGURATION ---
PRIMARY="eDP-1"

# Give X a moment to detect displays
sleep 0.5

# Enable the internal display
xrandr --output "$PRIMARY" --auto

# Mirror every connected monitor to the laptop display
while read -r OUTPUT; do
    [ "$OUTPUT" = "$PRIMARY" ] && continue

    # Highest refresh rate supported by this monitor
    HZ=$(
        xrandr |
        awk -v out="$OUTPUT" '
            $1==out {found=1; next}
            found && /^[A-Za-z0-9-]+ connected/ {exit}
            found && /^[ ]+[0-9]+x[0-9]+/ {
                for(i=2;i<=NF;i++){
                    gsub(/[+*]/,"",$i)
                    if($i+0>max) max=$i
                }
            }
            END{print max}
        '
    )

    if [ -n "$HZ" ]; then
        xrandr \
            --output "$OUTPUT" --auto --rate "$HZ" \
            --same-as "$PRIMARY"
    else
        xrandr \
            --output "$OUTPUT" --auto \
            --same-as "$PRIMARY"
    fi

done < <(xrandr | awk '/ connected/{print $1}')
feh --bg-fill "/home/a7med/dotfiles/dotconfig/openbox/Wallpaper.jpg"
# --- 5. START OPENBOX ---
exec openbox --config-file /home/a7med/Desktop/Apps/Games/X11-game-launcher/openbox-config/rc.xml
