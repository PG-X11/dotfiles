#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# DIRECTORIES & LINKS
# -------------------------
# These variables hold the exact paths to your folders and files[cite: 1].
THEME_DIR="$HOME/.local/share/colorschemes"
STATE_DIR="$HOME/.cache/colorschemes"
ACTIVE_THEME_FILE="$STATE_DIR/current_theme"

HYPR_CONF="$HOME/.config/hypr/colors/colors.conf"
ROFI_CONF="$HOME/.config/rofi/style.rasi"

# This creates the state folder just in case it does not exist yet[cite: 1].
mkdir -p "$STATE_DIR"

# -------------------------
# THEME MENU WITH PREVIEW
# -------------------------
# This section searches your themes, finds their pictures, and shows a visual menu[cite: 1].
# Modified section using -L to follow symlinks
THEME="$(
find -L "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    theme="$(basename "$dir")"
    preview="$dir/.preview.png"

    # If the picture is missing, it uses a backup picture so the menu does not break.
    [ -f "$preview" ] || preview="$HOME/.local/share/fallback.png"

    echo -en "${theme}\0icon\x1f${preview}\n"
done | rofi -dmenu -config "/home/a7med/dotfiles/dotconfig/hypr/scripts/ThemeSwitcher/themeswitcher.rasi" -i -p "Select Theme"
)"
# If you cancel the menu, the script stops immediately without errors[cite: 1].
[ -z "${THEME:-}" ] && exit 0

THEME_PATH="$THEME_DIR/$THEME"
[ -d "$THEME_PATH" ] || exit 1

# This writes the name of your chosen theme to a tiny text file to remember it[cite: 1].
echo "$THEME" > "$ACTIVE_THEME_FILE"

# -------------------------
# APPLY CORE CONFIGS
# -------------------------
# This builds direct digital bridges (shortcuts) from your theme folder to your real config folders[cite: 1].
ln -sfn "$THEME_PATH/hypr/colors.conf" "$HYPR_CONF"
ln -sfn "$THEME_PATH/rofi/style.rasi" "$ROFI_CONF"

# -------------------------
# APPLY GTK, KVANTUM, & QTCT
# -------------------------
# These are the original file paths you provided[cite: 1].
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



# --- Kvantum ---
# If the Kvantum file exists, copy it over[cite: 1].
if [ -f "$KV_SRC" ]; then
    mkdir -p "$(dirname "$KV_DEST")"
    cp "$KV_SRC" "$KV_DEST"
fi
# --- icon theme ---
ICON_THEME="$(grep '^icon_theme=' "$QTCT_SRC/qt5ct.conf" 2>/dev/null | cut -d'=' -f2)"
if [ -n "$ICON_THEME" ]; then
    if ! grep -q '^\[Icons\]' ~/.config/kdeglobals; then
        echo -e "\n[Icons]\nTheme=$ICON_THEME" >> ~/.config/kdeglobals
    else
        sed -i "s/^Theme=.*/Theme=$ICON_THEME/" ~/.config/kdeglobals
    fi
fi
# code to apply config file for qt
if [ -d "$QTCT_SRC" ]; then
    mkdir -p "$(dirname "$QT5_DEST")" "$(dirname "$QT6_DEST")"

    # qt5ct
    if [ -f "$QTCT_SRC/qt5ct.conf" ]; then
        cp "$QTCT_SRC/qt5ct.conf" "$QT5_DEST"
    fi

    # qt6ct
    if [ -f "$QTCT_SRC/qt6ct.conf" ]; then
        cp "$QTCT_SRC/qt6ct.conf" "$QT6_DEST"
    fi
fi


# -------------------------
# APPLY PYWAL FROM THEME WALLPAPER
# -------------------------
WALL_LINK="$THEME_PATH/current_wallpaper"

# If the wallpaper shortcut exists, update the terminal colors[cite: 1].
if [ -L "$WALL_LINK" ] && [ -e "$WALL_LINK" ]; then
    WALL="$(readlink -f "$WALL_LINK")"

    if command -v wal >/dev/null 2>&1; then
        wal -n -i "$WALL" -q
    fi
fi
# For zed editor run the zed wal theme  extension reloader
# bash /home/a7med/dotfiles/scripts/zed-theme-wal/zed-theme-wal-reload.sh
# -------------------------
# RELOAD SHELL
# -------------------------
# human interception, switched to noctalia LOL
noctalia msg wallpaper-set $WALL
# -------------------------
# APPLY LAST WALLPAPER
# -------------------------
# This smoothly changes your background picture using a fade effect[cite: 1].
if [ -L "$WALL_LINK" ] && [ -e "$WALL_LINK" ]; then
    WALL="$(readlink -f "$WALL_LINK")"

    if command -v awww >/dev/null 2>&1; then
        awww img "$WALL" \
            --transition-type grow \
            --transition-duration 1.7 \
            --transition-fps 120
    fi
fi

exit 0
