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
done | rofi -dmenu -i -p "Select Theme"
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
GTK_SRC="$THEME_PATH/GTK/settings.ini"
GTK_DEST="$HOME/.config/gtk-3.0/settings.ini"

KV_SRC="$THEME_PATH/KV/kvantum.kvconfig"
KV_DEST="$HOME/.config/Kvantum/kvantum.kvconfig"

QTCT_SRC="$THEME_PATH/QTCT"
QT5_DEST="$HOME/.config/qt5ct/qt5ct.conf"
QT6_DEST="$HOME/.config/qt6ct/qt6ct.conf"

# --- GTK ---
# If the GTK file exists in your theme, copy it over[cite: 1].
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

# --- Qt5 / Qt6 CT (Original Restored Method) ---
# This is your original code to copy the Qt configuration files and force them to apply[cite: 1].
if [ -d "$QTCT_SRC" ]; then
    mkdir -p "$(dirname "$QT5_DEST")" "$(dirname "$QT6_DEST")"

    # Copy qt5ct.conf if it exists inside the theme folder[cite: 1].
    if [ -f "$QTCT_SRC/qt5ct.conf" ]; then
        cp "$QTCT_SRC/qt5ct.conf" "$QT5_DEST"
    fi

    # Copy qt6ct.conf if it exists inside the theme folder[cite: 1].
    if [ -f "$QTCT_SRC/qt6ct.conf" ]; then
        cp "$QTCT_SRC/qt6ct.conf" "$QT6_DEST"
    fi
fi

# This runs the programs quietly in the background to apply the settings, then turns them off[cite: 1].
qt5ct --reply >/dev/null 2>&1 &
qt6ct --reply >/dev/null 2>&1 &
sleep 0.2
killall qt5ct qt6ct

# -------------------------
# APPLY PYWAL FROM THEME WALLPAPER
# -------------------------
WALL_LINK="$THEME_PATH/current_wallpaper"

# If the wallpaper shortcut exists, update the terminal colors[cite: 1].
if [ -L "$WALL_LINK" ] && [ -e "$WALL_LINK" ]; then
    WALL="$(readlink -f "$WALL_LINK")"

    if command -v wal >/dev/null 2>&1; then
        wal -i "$WALL" -q
    fi
fi
# For zed editor run the zed wal theme  extension reloader
bash /home/a7med/dotfiles/scripts/zed-theme-wal/zed-theme-wal-reload.sh
# -------------------------
# RELOAD SHELL
# -------------------------
# This reloads your quickshell immediately[cite: 1].
bash /home/a7med/.config/quickshell/reload-quickshell.sh

# -------------------------
# APPLY LAST WALLPAPER
# -------------------------
# This smoothly changes your background picture using a fade effect[cite: 1].
if [ -L "$WALL_LINK" ] && [ -e "$WALL_LINK" ]; then
    WALL="$(readlink -f "$WALL_LINK")"

    if command -v awww >/dev/null 2>&1; then
        awww img "$WALL" \
            --transition-type grow \
            --transition-duration 2
    fi
fi

exit 0
