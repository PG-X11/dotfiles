#!/bin/bash
# note from thex11 : this was made by AI aka vibe coded
# do not trust this to work all the time since i did not bother polishing it, I mean its easier just to log out and login
#!/bin/bash

# Function to detect session type cleanly via reliable tool state queries
detect_session_type() {
    if uwsm check is-active &>/dev/null; then
        echo "uwsm"
    elif [ "${XDG_BACKEND:-}" = "wayland" ] || [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ]; then
        echo "normal"
    else
        echo "x11-or-tty"
    fi
}

SESSION_TYPE=$(detect_session_type)

options=$(printf "Openbox\nHyprland UWSM\nHyprland Normal\nPlasma" | rofi \
    -dmenu -p "" \
    -config '/home/a7med/dotfiles/scripts/envswitcher/config.rasi'
)

[ -z "$options" ] && exit 0

# Track the structural identity of the active window manager
CURRENT_DESKTOP="Unknown"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    CURRENT_DESKTOP="Hyprland"
elif [ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ]; then
    CURRENT_DESKTOP="Plasma"
fi

# Define execution arguments target maps
case "$options" in
    "Openbox")         CMD="xinit" ;;
    "Hyprland UWSM")   CMD="uwsm start hyprland-uwsm.desktop" ;;
    "Hyprland Normal") CMD="Hyprland" ;;
    "Plasma")          CMD="startplasma-wayland" ;;
esac

# Guard Clauses: Handle notification rules exactly as specified
if [ "$options" = "Hyprland Normal" ] && [ "$SESSION_TYPE" = "normal" ] && [ "$CURRENT_DESKTOP" = "Hyprland" ]; then
    notify-send "Session Info" "You are already inside a normal Hyprland environment."
    exit 0
fi

if [ "$options" = "Hyprland UWSM" ] && [ "$SESSION_TYPE" = "uwsm" ] && [ "$CURRENT_DESKTOP" = "Hyprland" ]; then
    notify-send "Session Info" "You are already running inside a UWSM Hyprland environment."
    exit 0
fi

if [ "$options" = "Plasma" ] && [ "$SESSION_TYPE" = "normal" ] && [ "$CURRENT_DESKTOP" = "Plasma" ]; then
    notify-send "Session Info" "You are already inside a normal Plasma environment."
    exit 0
fi

# Hand off the target process as a detached service unit so it survives uwsm stop
systemd-run --user --description="EnvSwitcher-Target" bash -c "$CMD"

# Execute direct, instant destruction of the active session context
if [ "$SESSION_TYPE" = "uwsm" ]; then
    uwsm stop
elif [ "$SESSION_TYPE" = "normal" ]; then
    if [ "$CURRENT_DESKTOP" = "Hyprland" ]; then
        hyprctl dispatch exit 0
    elif [ "$CURRENT_DESKTOP" = "Plasma" ]; then
        qdbus org.kde.Shutdown /Shutdown logout
    fi
fi
