#!/usr/bin/env bash
#
# X11's Hyprland dotfiles installation script
# Target hardware: Dell Precision 7530 / 7730 and similar Intel + NVIDIA hybrid laptops
#

set -euo pipefail

# Resolve repository paths regardless of where the script is invoked from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/dotconfig" ]; then
    DOTFILES="$SCRIPT_DIR"
else
    DOTFILES="$(dirname "$SCRIPT_DIR")"
fi

PACKAGE_DIR="$DOTFILES/packages/needed"
OFFICIAL_DIR="$PACKAGE_DIR/official"
AUR_DIR="$PACKAGE_DIR/aur"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
PACMAN_CONF="${PACMAN_CONF:-/etc/pacman.conf}"
SYS_DRM_DIR="${SYS_DRM_DIR:-/sys/class/drm}"
UDEV_RULES_DIR="${UDEV_RULES_DIR:-/etc/udev/rules.d}"

# Basic terminal colors for readable output
C_RESET='\033[0m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'

msg()  { printf "${C_BLUE}::${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}==>${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}warning:${C_RESET} %s\n" "$*"; }
err()  { printf "${C_RED}error:${C_RESET} %s\n" "$*" >&2; exit 1; }

# Use single-quoted EOF so backslashes and backticks in the logo print literally
cat << 'EOF'
╔─────────────────────────────────────────────────────╗
│____  _______ ____/\                                 │
│\   \/  /_   /_   )/______                           │
│ \     / |   ||   |/  ___/                           │
│ /     \ |   ||   |\___ \                            │
│/___/\  \|___||___/____  >                           │
│      \_/              \/                            │
│________          __    _____.__.__                  │
│\______ \   _____/  |__/ ____\__|  |   ____   ______ │
│ |    |  \ /  _ \   __\   __\|  |  | _/ __ \ /  ___/ │
│ |    `   (  <_> )  |  |  |  |  |  |_\  ___/ \___ \  │
│/_______  /\____/|__|  |__|  |__|____/\___  >____  > │
│        \/                                \/     \/  │
╚─────────────────────────────────────────────────────╝
Installation script
EOF
echo ""

# Prevent running the script as root since makepkg and user symlinks require a normal user
if [ "$EUID" -eq 0 ]; then
    err "Do not run this script as root. Run it as your regular user; sudo will prompt when needed."
fi

# Verify that the script is inside the dotfiles repository
if [ ! -d "$DOTFILES/dotconfig" ] || [ ! -d "$DOTFILES/dotlocal" ]; then
    err "Dotfiles directories not found in $DOTFILES. Make sure the script is inside the repository."
fi

# Keep sudo alive while the script runs and clean up the background loop on exit
sudo -v
(while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# Enable [multilib] in /etc/pacman.conf if it is still commented out.
# Required by lib32-* packages in performance-official.txt and nvidia-aur.txt.
if [ -f "$PACMAN_CONF" ] && ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    msg "Enabling [multilib] repository in $PACMAN_CONF..."
    sudo sed -i '/^\s*#\s*\[multilib\]/,/^\s*#\s*Include/ s/^\s*#//' "$PACMAN_CONF"
    sudo pacman -Sy
fi

# Install base-devel and git first so we can build AUR packages
msg "Checking build dependencies..."
sudo pacman -S --needed --noconfirm base-devel git

# Install matching kernel headers for any installed kernels.
# Required for nvidia-580xx-dkms to compile kernel modules cleanly.
KERNEL_HEADERS=()
for kdir in /usr/lib/modules/*; do
    [ -d "$kdir" ] || continue
    pkgbase_file="$kdir/pkgbase"
    if [ -f "$pkgbase_file" ]; then
        kbase="$(cat "$pkgbase_file")"
        KERNEL_HEADERS+=("${kbase}-headers")
    fi
done
if [ "${#KERNEL_HEADERS[@]}" -gt 0 ]; then
    msg "Installing kernel headers for DKMS (${KERNEL_HEADERS[*]})..."
    sudo pacman -S --needed --noconfirm "${KERNEL_HEADERS[@]}" || warn "Could not install some kernel headers; check your kernel package."
fi

# Install paru if no AUR helper is installed yet
if ! command -v paru &>/dev/null; then
    msg "Installing paru (AUR helper)..."
    rm -rf /tmp/paru-bin
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
    (
        cd /tmp/paru-bin
        makepkg -si --noconfirm
    )
    rm -rf /tmp/paru-bin
fi

# Detect GPU hardware via sysfs or lspci so the script works on both NVIDIA hybrid laptops
# (like Dell Precision 7530/7730) and similar laptops using AMD or Intel-only graphics.
HAS_NVIDIA=0
if grep -qi "0x10de" /sys/bus/pci/devices/*/vendor 2>/dev/null || \
   grep -qi "0x10de" "$SYS_DRM_DIR"/card*/device/vendor 2>/dev/null || \
   { command -v lspci &>/dev/null && lspci | grep -qi "nvidia"; }; then
    HAS_NVIDIA=1
    msg "NVIDIA GPU detected."
else
    warn "No NVIDIA GPU detected; skipping nvidia-specific package lists."
fi

# Helper to read package list files while stripping comments and blank lines.
# Avoids pacman/paru failing on empty files like fonts-aur.txt.
install_pkg_file() {
    local manager="$1"
    local file="$2"
    local base
    base="$(basename "$file")"

    if [[ "$base" == nvidia-* ]] && [ "$HAS_NVIDIA" -eq 0 ]; then
        msg "Skipping $base (no NVIDIA GPU present)."
        return 0
    fi

    local pkgs=()
    mapfile -t pkgs < <(awk '{gsub(/#.*/, ""); for (i = 1; i <= NF; i++) print $i}' "$file")
    if [ "${#pkgs[@]}" -eq 0 ]; then
        msg "Skipping $base (empty package list)."
        return 0
    fi

    msg "Installing packages from $base..."
    if [ "$manager" = "pacman" ]; then
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    else
        paru -S --needed --noconfirm "${pkgs[@]}"
    fi
}

# Install official repository packages from packages/needed/official/*.txt
if [ -d "$OFFICIAL_DIR" ]; then
    for pkg_file in "$OFFICIAL_DIR"/*.txt; do
        [ -f "$pkg_file" ] || continue
        install_pkg_file pacman "$pkg_file"
    done
fi

# Install AUR packages from packages/needed/aur/*.txt
if [ -d "$AUR_DIR" ]; then
    for pkg_file in "$AUR_DIR"/*.txt; do
        [ -f "$pkg_file" ] || continue
        install_pkg_file paru "$pkg_file"
    done
fi

# Back up any existing real file or mismatched symlink before replacing it
link_item() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local current_target=""
        if [ -L "$dst" ]; then
            current_target="$(readlink "$dst")"
        fi
        if [ "$current_target" != "$src" ]; then
            local rel_path="${dst#"$HOME"/}"
            local backup_target="$BACKUP_DIR/$rel_path"
            mkdir -p "$(dirname "$backup_target")"
            mv "$dst" "$backup_target"
        fi
    fi

    ln -sfn "$src" "$dst"
}

# Prepare user directories required by Hyprland, Noctalia, and theme scripts.
# Note: ~/.local/bin and ~/.local/state are created as symlinks below, not empty directories here.
msg "Creating user configuration and cache directories..."
mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/share" \
    "$HOME/.cache/colorschemes" \
    "$HOME/.cache/wallpaper-previews"

# Replace hardcoded /home/a7med paths in regular files (skipping .git and symlinks so symlinks are not overwritten)
msg "Updating hardcoded paths in configs and scripts to match $HOME..."
while IFS= read -r -d '' file; do
    if grep -q "/home/a7med" "$file" 2>/dev/null; then
        sed -i \
            -e "s|/home/a7med/dotfiles|$DOTFILES|g" \
            -e "s|/home/a7med/Bookmarks/hypr|$DOTFILES/dotconfig/hypr|g" \
            -e "s|/home/a7med|$HOME|g" \
            "$file"
    fi
done < <(find "$DOTFILES/dotconfig" "$DOTFILES/dotlocal" "$DOTFILES/home" "$DOTFILES/scripts" -type f -print0 2>/dev/null)

# Rewrite any symlinks inside the repository that still point to /home/a7med/...
# Covers dotlocal/bin/*, dotconfig/hypr/colors/colors.conf, dotconfig/rofi/style.rasi, and current-preset.conf.
msg "Updating repository symlinks to match $DOTFILES and $HOME..."
while IFS= read -r -d '' link; do
    target="$(readlink "$link")"
    if [[ "$target" == /home/a7med* ]]; then
        new_target="$target"
        new_target="${new_target/#\/home\/a7med\/dotfiles/$DOTFILES}"
        new_target="${new_target/#\/home\/a7med/$HOME}"
        ln -sfn "$new_target" "$link"
    fi
done < <(find "$DOTFILES" -path "$DOTFILES/.git" -prune -o -type l -print0 2>/dev/null)

# Link everything inside dotconfig/ into ~/.config/
msg "Linking ~/.config files..."
shopt -s nullglob
for item in "$DOTFILES/dotconfig"/*; do
    link_item "$item" "$HOME/.config/$(basename "$item")"
done

# Link dotlocal subdirectories (bin, state, and contents of share)
msg "Linking ~/.local files and colorschemes..."
for item in "$DOTFILES/dotlocal"/*; do
    name="$(basename "$item")"
    if [ "$name" = "share" ]; then
        # Link items inside dotlocal/share (such as icons) without clobbering existing ~/.local/share data
        for share_item in "$DOTFILES/dotlocal/share"/*; do
            link_item "$share_item" "$HOME/.local/share/$(basename "$share_item")"
        done
    else
        link_item "$item" "$HOME/.local/$name"
    fi
done

# Link colorschemes/ into ~/.local/share/colorschemes (expected by themeswitcher.sh, wallchanger.sh, and Noctalia)
if [ -d "$DOTFILES/colorschemes" ]; then
    link_item "$DOTFILES/colorschemes" "$HOME/.local/share/colorschemes"
fi

# Link dotfiles inside home/ (enable dotglob so hidden files like .zshrc, .zprofile, .xinitrc, and .themes are included)
msg "Linking home directory dotfiles..."
shopt -s dotglob
for item in "$DOTFILES/home"/*; do
    base="$(basename "$item")"
    [ "$base" = "." ] || [ "$base" = ".." ] && continue
    link_item "$item" "$HOME/$base"
done
shopt -u dotglob nullglob

# Ensure all shell scripts and custom binaries have executable permissions
msg "Setting executable permissions on scripts and binaries..."
find "$DOTFILES/scripts" "$DOTFILES/dotconfig/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$DOTFILES/dotlocal/bin" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
[ -f "$DOTFILES/.githooks/pre-push" ] && chmod +x "$DOTFILES/.githooks/pre-push"

# Create the Noctalia setup marker so it does not launch the first-run wizard over the existing config
mkdir -p "$DOTFILES/dotlocal/state/noctalia"
touch "$DOTFILES/dotlocal/state/noctalia/.setup-complete"

# Seed a default theme state if none exists so themeswitcher/wallchanger work on first launch
if [ ! -f "$HOME/.cache/colorschemes/current_theme" ]; then
    echo "everforest" > "$HOME/.cache/colorschemes/current_theme"
fi

# Set up udev symlinks (/dev/dri/igpu and /dev/dri/dgpu) expected by dotconfig/hypr/env.conf
# (env = AQ_DRM_DEVICES,/dev/dri/dgpu:/dev/dri/igpu) on Intel + NVIDIA hybrid laptops.
setup_gpu_udev_rules() {
    local igpu_pci=""
    local dgpu_pci=""

    for card in "$SYS_DRM_DIR"/card[0-9]; do
        [ -e "$card/device/vendor" ] || continue
        local vendor
        vendor="$(cat "$card/device/vendor")"
        local pci_slot
        pci_slot="$(basename "$(readlink -f "$card/device")")"

        # 0x8086 = Intel, 0x10de = NVIDIA, 0x1002 = AMD
        if [ "$vendor" = "0x8086" ] && [ -z "$igpu_pci" ]; then
            igpu_pci="$pci_slot"
        elif [ "$vendor" = "0x10de" ] && [ -z "$dgpu_pci" ]; then
            dgpu_pci="$pci_slot"
        fi
    done

    if [ -n "$igpu_pci" ] && [ -n "$dgpu_pci" ]; then
        msg "Creating udev rules for /dev/dri/igpu ($igpu_pci) and /dev/dri/dgpu ($dgpu_pci)..."
        sudo mkdir -p "$UDEV_RULES_DIR"
        sudo tee "$UDEV_RULES_DIR/99-hypr-gpu.rules" >/dev/null <<EOF
KERNEL=="card*", KERNELS=="$igpu_pci", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/igpu"
KERNEL=="card*", KERNELS=="$dgpu_pci", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/dgpu"
EOF
        sudo udevadm control --reload
        sudo udevadm trigger --subsystem-match=drm
    elif [ -n "$igpu_pci" ] && [ -f "$DOTFILES/dotconfig/hypr/env.conf" ]; then
        warn "Only integrated GPU ($igpu_pci) found; commenting out AQ_DRM_DEVICES in env.conf so Hyprland starts cleanly."
        sed -i 's/^\s*env\s*=\s*AQ_DRM_DEVICES/# env = AQ_DRM_DEVICES/' "$DOTFILES/dotconfig/hypr/env.conf"
    fi
}
setup_gpu_udev_rules

# Add a fallback monitor rule to monitors.conf if not present so laptops with different display outputs
# (such as DP-1 or different panels) still get an active workspace on boot.
if [ -f "$DOTFILES/dotconfig/hypr/monitors.conf" ]; then
    if ! grep -q "^monitor=,preferred,auto,1" "$DOTFILES/dotconfig/hypr/monitors.conf"; then
        printf "\n# Fallback rule for unconfigured displays\nmonitor=,preferred,auto,1\n" >> "$DOTFILES/dotconfig/hypr/monitors.conf"
    fi
fi

# Configure repository git hooks if inside a git working tree
if [ -d "$DOTFILES/.git" ] && [ -d "$DOTFILES/.githooks" ]; then
    msg "Configuring repository git hooks..."
    git -C "$DOTFILES" config core.hooksPath .githooks
fi

# Enable essential system services for networking, bluetooth, and power management
msg "Enabling system services..."
for svc in NetworkManager bluetooth power-profiles-daemon; do
    if systemctl list-unit-files "${svc}.service" &>/dev/null; then
        sudo systemctl enable --now "${svc}.service" || true
    fi
done

if [ "$HAS_NVIDIA" -eq 1 ] && systemctl list-unit-files nvidia-powerd.service &>/dev/null; then
    sudo systemctl enable --now nvidia-powerd.service || true
fi

# Populate standard XDG user directories (Downloads, Documents, Pictures, etc.)
if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
fi

# Change default login shell to zsh if not already set
if command -v zsh &>/dev/null && [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    msg "Changing default shell to zsh..."
    chsh -s "$(command -v zsh)" "${USER:-$(id -un)}" || warn "Could not change shell automatically; run: chsh -s $(command -v zsh)"
fi

if [ -d "$BACKUP_DIR" ]; then
    warn "Existing files that conflicted with symlinks were backed up to: $BACKUP_DIR"
fi

ok "Installation complete. Log out or reboot to start your session."