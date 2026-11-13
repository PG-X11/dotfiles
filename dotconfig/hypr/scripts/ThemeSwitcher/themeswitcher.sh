#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.local/share/colorschemes"
STATE_DIR="$HOME/.cache/colorschemes"
ACTIVE_THEME_FILE="$STATE_DIR/current_theme"

ROFI_CONF="$HOME/.config/rofi/style.rasi"

mkdir -p "$STATE_DIR"

THEME="$(
find -L "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    theme="$(basename "$dir")"
    preview="$dir/.preview.png"
    [ -f "$preview" ] || preview="$HOME/.local/share/fallback.png"
    echo -en "${theme}\0icon\x1f${preview}\n"
done | rofi -dmenu -config "$HOME/.config/hypr/scripts/ThemeSwitcher/themeswitcher.rasi" -i -p "Select Theme"
)"

[ -z "${THEME:-}" ] && exit 0

THEME_PATH="$THEME_DIR/$THEME"
[ -d "$THEME_PATH" ] || exit 1

echo "$THEME" > "$ACTIVE_THEME_FILE"

# 1. IMMEDIATE VISUAL UPDATES (Symlinks)
ln -sfn "$THEME_PATH/rofi/style.rasi" "$ROFI_CONF"

# 2. IMMEDIATE WALLPAPER & PYWAL BORDER UPDATE
WALL=""
WALL_LINK="$THEME_PATH/current_wallpaper"
if [ -L "$WALL_LINK" ] && [ -e "$WALL_LINK" ]; then
    WALL="$(readlink -f "$WALL_LINK")"

    # Run Pywal to regenerate ~/.cache/wal/colors-hyprland.lua, then reload Hyprland borders
    if command -v wal >/dev/null 2>&1; then
        (wal -n -i "$WALL" -q && hyprctl reload >/dev/null 2>&1) &
    fi

    # Trigger wallpaper switcher
    if command -v awww >/dev/null 2>&1; then
        awww img "$WALL" --transition-type grow --transition-duration 1.7 --transition-fps 120 &
    fi

    # Update noctalia wallpaper
    if command -v noctalia >/dev/null 2>&1; then
        noctalia msg wallpaper-set "$WALL" &
    fi
fi

# 3. BACKGROUND HEAVY FILE I/O & GTK/QT UPDATES
(
    GTK_SRC="$THEME_PATH/GTK/nwg-look/gsettings"
    GTK_DEST="$HOME/.local/share/nwg-look/gsettings"
    KV_SRC="$THEME_PATH/KV/kvantum.kvconfig"
    KV_DEST="$HOME/.config/Kvantum/kvantum.kvconfig"
    QTCT_SRC="$THEME_PATH/QTCT"
    QT5_DEST="$HOME/.config/qt5ct/qt5ct.conf"
    QT6_DEST="$HOME/.config/qt6ct/qt6ct.conf"

    if [ -f "$GTK_SRC" ]; then
        mkdir -p "$(dirname "$GTK_DEST")"
        cp "$GTK_SRC" "$GTK_DEST"
        if command -v nwg-look >/dev/null 2>&1; then
            nwg-look -a >/dev/null 2>&1 || true
        fi
    fi

    if [ -f "$KV_SRC" ]; then
        mkdir -p "$(dirname "$KV_DEST")"
        cp "$KV_SRC" "$KV_DEST"
    fi

    ICON_THEME="$(grep '^icon_theme=' "$QTCT_SRC/qt5ct.conf" 2>/dev/null | cut -d'=' -f2 || true)"
    if [ -n "$ICON_THEME" ]; then
        if ! grep -q '^\[Icons\]' ~/.config/kdeglobals 2>/dev/null; then
            echo -e "\n[Icons]\nTheme=$ICON_THEME" >> ~/.config/kdeglobals
        else
            sed -i "s/^Theme=.*/Theme=$ICON_THEME/" ~/.config/kdeglobals
        fi
    fi

    if [ -d "$QTCT_SRC" ]; then
        mkdir -p "$(dirname "$QT5_DEST")" "$(dirname "$QT6_DEST")"
        [ -f "$QTCT_SRC/qt5ct.conf" ] && cp "$QTCT_SRC/qt5ct.conf" "$QT5_DEST"
        [ -f "$QTCT_SRC/qt6ct.conf" ] && cp "$QTCT_SRC/qt6ct.conf" "$QT6_DEST"
    fi
) &

exit 0
