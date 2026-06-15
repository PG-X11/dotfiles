#!/bin/bash

# --- 1. INSTANT CLEANUP ---
# Instantly terminate any existing Steam processes to avoid launch bugs
pkill -9 steam 2>/dev/null
pkill -9 steamwebhelper 2>/dev/null

# --- 2. HARDWARE OVERCLOCK & LATENCY REDUCTION ---
# Disable vertical synchronization (V-Sync) at the driver level for zero lag
export vblank_mode=0
export __GL_MaxFramesAllowed=1

# NVIDIA Graphics Card variables
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Force the NVIDIA GPU into Maximum Performance Mode
nvidia-settings -a "[gpu:0]/GPUPowerMizerMode=1" &

# Disable screen blanking, sleep modes, and absolute raw mouse input
xset -dpms s off s noblank
xset m 0 0
xset b off # Disables system beeps to prevent minute CPU disruptions

# --- 3. CPU PERFORMANCE GOVERNOR ---
# Force all processor cores to stay at their absolute highest speeds
if command -v cpupower &> /dev/null; then
    sudo cpupower frequency-set -g performance
fi

# --- 4. START OPENBOX ---
# Replaces the shell script process with Openbox directly to save RAM/CPU
exec openbox --config-file /home/a7med/Desktop/Apps/Games/X11-game-launcher/openbox-config/rc.xml