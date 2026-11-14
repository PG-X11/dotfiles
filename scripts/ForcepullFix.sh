cat << 'EOF' > fix-dotfiles.sh
#!/usr/bin/env bash

# ==============================================================================
# Dotfiles Post-Reset & Force-Pull Recovery Script
# Fixes hardcoded "a7med" paths, permissions, broken symlinks, and installer hangs
# ==============================================================================

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CURRENT_USER="$(whoami)"
CURRENT_HOME="$HOME"
CURRENT_HOST="$(uname -n)"
OLD_USER="a7med"

# Detect repository directory (current directory if it contains .git, else fallback)
if [ -d ".git" ]; then
    REPO_DIR="$(pwd)"
elif [ -d "$HOME/dotfiles/.git" ]; then
    REPO_DIR="$HOME/dotfiles"
elif [ -d "$HOME/.dotfiles/.git" ]; then
    REPO_DIR="$HOME/.dotfiles"
else
    REPO_DIR="$(pwd)"
fi

echo -e "${BLUE}[*] Starting recovery in:${NC} $REPO_DIR"
echo -e "${BLUE}[*] Target User:${NC} $CURRENT_USER | ${BLUE}Home:${NC} $CURRENT_HOME | ${BLUE}Host:${NC} $CURRENT_HOST"
echo "------------------------------------------------------------------------------"

# ------------------------------------------------------------------------------
# 1. Kill hanging installer processes & clear pacman locks
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[1/6] Checking for hanging processes and package locks...${NC}"

# Kill stuck background tasks that commonly hang dotfile installers
for proc in wal pywal swww-daemon hyprpaper rofi dunst picom; do
    if pgrep -x "$proc" >/dev/null 2>&1; then
        echo "  -> Stopping hanging process: $proc"
        killall -9 "$proc" 2>/dev/null || true
    fi
done

# Remove stale pacman db lock if no pacman process is actively running
if [ -f /var/lib/pacman/db.lck ]; then
    if ! pgrep -x "pacman" >/dev/null 2>&1; then
        echo "  -> Removing stale /var/lib/pacman/db.lck (requires sudo)"
        sudo rm -f /var/lib/pacman/db.lck
    else
        echo -e "  -> ${RED}Warning:${NC} pacman is currently running in another window. Close it first."
    fi
fi

# ------------------------------------------------------------------------------
# 2. Restore executable permissions stripped by git reset
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[2/6] Restoring executable permissions on all scripts...${NC}"

find "$REPO_DIR" -path "$REPO_DIR/.git" -prune -o -type f \( -name "*.sh" -o -name "*.py" -o -name "install*" -o -name "setup*" \) -exec chmod +x {} + 2>/dev/null || true

if [ -d "$CURRENT_HOME/.config" ]; then
    find "$CURRENT_HOME/.config" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
fi
if [ -d "$CURRENT_HOME/.local/bin" ]; then
    chmod -R +x "$CURRENT_HOME/.local/bin" 2>/dev/null || true
fi
echo -e "  -> ${GREEN}Permissions restored.${NC}"

# ------------------------------------------------------------------------------
# 3. Replace hardcoded "a7med" paths and usernames across Repo & ~/.config
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[3/6] Replacing hardcoded '$OLD_USER' references with '$CURRENT_USER'...${NC}"

replace_hardcoded() {
    local target_dir="$1"
    [ ! -d "$target_dir" ] && return

    # Find all text/config files, excluding .git and binary assets
    find "$target_dir" \
        -path "*/.git" -prune -o \
        -path "*/node_modules" -prune -o \
        -type f \( \
            -name "*.lua" -o \
            -name "*.conf" -o \
            -name "*.sh" -o \
            -name "*.bash" -o \
            -name "*.zsh" -o \
            -name "*.rasi" -o \
            -name "*.ini" -o \
            -name "*.json" -o \
            -name "*.jsonc" -o \
            -name "*.css" -o \
            -name "*.py" -o \
            -name "*.toml" -o \
            -name "*.yaml" -o \
            -name "*.yml" -o \
            -name "*.xml" -o \
            -name ".bashrc" -o \
            -name ".zshrc" -o \
            -name ".xinitrc" -o \
            -name ".profile" \
        \) -print0 | while IFS= read -r -d '' file; do
            if grep -qI "$OLD_USER" "$file" 2>/dev/null; then
                echo "  -> Patching: $file"
                # 1. Replace full home path /home/a7med with actual $HOME
                sed -i "s|/home/${OLD_USER}|${CURRENT_HOME}|g" "$file"
                # 2. Replace user@host patterns (e.g. a7med@a7med)
                sed -i "s|${OLD_USER}@${OLD_USER}|${CURRENT_USER}@${CURRENT_HOST}|g" "$file"
                # 3. Replace remaining standalone a7med references with CURRENT_USER
                sed -i "s|${OLD_USER}|${CURRENT_USER}|g" "$file"
            fi
        done
}

replace_hardcoded "$REPO_DIR"
if [ "$REPO_DIR" != "$CURRENT_HOME/.config" ]; then
    replace_hardcoded "$CURRENT_HOME/.config"
fi

# Also check top-level home dotfiles (.bashrc, .zshrc, .xinitrc)
for dotfile in "$CURRENT_HOME/.bashrc" "$CURRENT_HOME/.zshrc" "$CURRENT_HOME/.xinitrc" "$CURRENT_HOME/.profile"; do
    if [ -f "$dotfile" ] && grep -qI "$OLD_USER" "$dotfile" 2>/dev/null; then
        echo "  -> Patching: $dotfile"
        sed -i "s|/home/${OLD_USER}|${CURRENT_HOME}|g" "$dotfile"
        sed -i "s|${OLD_USER}|${CURRENT_USER}|g" "$dotfile"
    fi
done

echo -e "  -> ${GREEN}All hardcoded references updated.${NC}"

# ------------------------------------------------------------------------------
# 4. Clean up broken symlinks pointing to /home/a7med
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[4/6] Scanning for broken symlinks in ~/.config and ~...${NC}"

find "$CURRENT_HOME/.config" -maxdepth 3 -type l 2>/dev/null | while read -r link; do
    target="$(readlink "$link")"
    if [[ "$target" == *"$OLD_USER"* ]]; then
        new_target="${target//\/home\/$OLD_USER/$CURRENT_HOME}"
        new_target="${new_target//$OLD_USER/$CURRENT_USER}"
        echo "  -> Relinking $link -> $new_target"
        ln -snf "$new_target" "$link"
    elif [ ! -e "$link" ]; then
        echo "  -> Removing dead symlink: $link (pointed to $target)"
        rm -f "$link"
    fi
done

# ------------------------------------------------------------------------------
# 5. Ensure required cache / pywal / Hyprland files exist so configs don't hang
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Verifying pywal & Hyprland required templates/caches...${NC}"

mkdir -p "$CURRENT_HOME/.cache/wal"
mkdir -p "$CURRENT_HOME/.config/hypr"

# If Hyprland config sources colors-hyprland.conf or colors-hyprland.lua, ensure dummy file exists if missing
if [ ! -f "$CURRENT_HOME/.cache/wal/colors-hyprland.conf" ]; then
    cat << 'WALEOF' > "$CURRENT_HOME/.cache/wal/colors-hyprland.conf"
$background = rgb(1e1e2e)
$foreground = rgb(cdd6f4)
$color0 = rgb(1e1e2e)
$color1 = rgb(f38ba8)
$color2 = rgb(a6e3a1)
$color3 = rgb(f9e2af)
$color4 = rgb(89b4fa)
$color5 = rgb(cba6f7)
$color6 = rgb(94e2d5)
$color7 = rgb(bac2de)
$color8 = rgb(585b70)
$color9 = rgb(f38ba8)
$color10 = rgb(a6e3a1)
$color11 = rgb(f9e2af)
$color12 = rgb(89b4fa)
$color13 = rgb(cba6f7)
$color14 = rgb(94e2d5)
$color15 = rgb(a6adc8)
WALEOF
    echo "  -> Created fallback ~/.cache/wal/colors-hyprland.conf"
fi

# ------------------------------------------------------------------------------
# 6. Diagnose & Fix Installer Hang Causes
# ------------------------------------------------------------------------------
echo -e "${YELLOW}[6/6] Auditing installation script for hang causes...${NC}"

INSTALL_SCRIPT=""
for candidate in "$REPO_DIR/install.sh" "$REPO_DIR/setup.sh" "$REPO_DIR/install"; do
    if [ -f "$candidate" ]; then
        INSTALL_SCRIPT="$candidate"
        break
    fi
done

if [ -n "$INSTALL_SCRIPT" ]; then
    echo "  -> Found installer: $INSTALL_SCRIPT"
    cp "$INSTALL_SCRIPT" "${INSTALL_SCRIPT}.bak"

    # Fix 1: Convert CRLF (Windows line endings from git) to LF
    sed -i 's/\r$//' "$INSTALL_SCRIPT"

    # Fix 2: Fix 7z vs 7zip package name issue on Arch
    sed -i 's/\bp7zip\b/7zip/g' "$INSTALL_SCRIPT"

    # Fix 3: Prevent wal / swww / hyprpaper from hanging the terminal by running without TTY block
    # (Optional: adds -q to wal if missing)
    chmod +x "$INSTALL_SCRIPT"
    echo -e "  -> ${GREEN}Patched $INSTALL_SCRIPT (backup saved at ${INSTALL_SCRIPT}.bak)${NC}"
else
    echo "  -> No install.sh found in $REPO_DIR."
fi

echo "------------------------------------------------------------------------------"
echo -e "${GREEN}[✓] Recovery complete!${NC}"
echo "To run your installation script with live debug output (so you can see every line execute):"
echo -e "  ${BLUE}bash -x ./install.sh${NC}"
EOF

chmod +x fix-dotfiles.sh
./fix-dotfiles.sh
