#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.local/share/colorschemes"
STATE_DIR="$HOME/.cache/colorschemes"
ACTIVE_THEME_FILE="$STATE_DIR/current_theme"

[ -f "$ACTIVE_THEME_FILE" ] || exit 1

THEME="$(cat "$ACTIVE_THEME_FILE")"
THEME_PATH="$THEME_DIR/$THEME"

WALL_DIR="$THEME_PATH/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-previews/$THEME"

mkdir -p "$CACHE_DIR"

[ -d "$WALL_DIR" ] || exit 1

# -------------------------
# thumbnail generator
# -------------------------
generate_preview() {
    local img="$1"
    local name
    name="$(basename "$img")"
    local out="$CACHE_DIR/$name.png"

    # skip regen if exists
    if [ ! -f "$out" ]; then
        if command -v convert >/dev/null 2>&1; then
            convert "$img" -thumbnail 300x300^ -gravity center -extent 300x300 "$out"
        else
            cp "$img" "$out"
        fi
    fi

    echo "$out"
}

# -------------------------
# WALLPAPER MENU WITH PREVIEW
# -------------------------
PICKED="$(
find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
| while read -r img; do

    preview="$(generate_preview "$img")"
    name="$(basename "$img")"

    echo -en "${name}\0icon\x1f${preview}\n"
done | rofi -dmenu -config "/home/a7med/Bookmarks/hypr/scripts/ThemeSwitcher/wallchanger.rasi" -i -p "Pick Wallpaper"
)"

[ -z "${PICKED:-}" ] && exit 0

FULL_PATH="$WALL_DIR/$PICKED"
[ -f "$FULL_PATH" ] || exit 1

# -------------------------
# SYMLINK SYSTEM (IMPORTANT)
# -------------------------
ln -sfn "$FULL_PATH" "$THEME_PATH/current_wallpaper"

# update theme preview (for theme switcher UI)
ln -sfn "$FULL_PATH" "$THEME_PATH/.preview.png"
# -------------------------
# PYWAL INTEGRATION
# -------------------------
if command -v wal >/dev/null 2>&1; then
    wal -i "$FULL_PATH" -q

    # optional: update symlinked theme colors
    THEME_FILE="$THEME_PATH/hypr/colors.conf"

    # reload hyprland colors after pywal
    # hyprctl reload
fi
# relolad quick shell and apply the wal theme
bash /home/a7med/.config/quickshell/reload-quickshell.sh
# For zed editor run the zed wal theme  extension reloader
bash /home/a7med/dotfiles/scripts/zed-theme-wal/zed-theme-wal-reload.sh
# -------------------------
# APPLY WALLPAPER
# -------------------------
if command -v awww >/dev/null 2>&1; then
    awww img "$FULL_PATH" \
        --transition-type wipe \
        --transition-duration 1.6
fi

exit
