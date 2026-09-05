#!/usr/bin/env bash
set -euo pipefail

# Enable fast, case-insensitive memory search for files
shopt -s nullglob nocaseglob

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
# INSTANT WALLPAPER MENU
# -------------------------
# Replaced 'find' with fast native bash globbing.
# Missing thumbnails generate in the background so the menu never freezes.
PICKED="$(
for img in "$WALL_DIR"/*.{gif,png,jpg,jpeg,webp}; do
    name="$(basename "$img")"
    out="$CACHE_DIR/$name.png"
    preview="$out"

    # Check if thumbnail exists
    if [ ! -f "$out" ]; then
        # Use fallback instantly so Rofi does not wait
        preview="$HOME/.local/share/fallback.png"

        # Generate the real thumbnail in the background for next time
        if command -v convert >/dev/null 2>&1; then
            case "$img" in
                *.gif)
                    convert "${img}[0]" -thumbnail 300x300^ -gravity center -extent 300x300 "$out" &
                    ;;
                *)
                    convert "$img" -thumbnail 300x300^ -gravity center -extent 300x300 "$out" &
                    ;;
            esac
        else
            cp "$img" "$out" &
        fi
    fi

    echo -en "${name}\0icon\x1f${preview}\n"
done | rofi -dmenu -config "/home/a7med/Bookmarks/hypr/scripts/ThemeSwitcher/wallchanger.rasi" -i -p "Pick Wallpaper"
)"

[ -z "${PICKED:-}" ] && exit 0

FULL_PATH="$WALL_DIR/$PICKED"
[ -f "$FULL_PATH" ] || exit 1

# -------------------------
# SYMLINK SYSTEM
# -------------------------
ln -sfn "$FULL_PATH" "$THEME_PATH/current_wallpaper"
ln -sfn "$FULL_PATH" "$THEME_PATH/.preview.png"

# -------------------------
# ASYNCHRONOUS PROCESSING
# -------------------------
# Send heavy tasks to the background so the script exits instantly
if command -v wal >/dev/null 2>&1; then
    wal -n -i "$FULL_PATH" -q &
fi

if command -v noctalia >/dev/null 2>&1; then
    noctalia msg wallpaper-set "$FULL_PATH" &
fi

if command -v awww >/dev/null 2>&1; then
    awww img "$FULL_PATH" \
        --transition-type wipe \
        --transition-duration 1.4 \
        --transition-fps 120 &
fi

# Removed zed since its useless
# Finally update noctalia
if command -v noctalia >/dev/null 2>&1; then
    noctalia msg wallpaper-set "$FULL_PATH" &
    # noctalia msg color-scheme-set custom colors-noctalia
fi
exit 0
