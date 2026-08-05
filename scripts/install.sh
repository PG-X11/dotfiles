```bash
#!/bin/bash

## X11's dotfiles installation tool built in 3pm in some random afternoon

set -e

# directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES="$(dirname "$SCRIPT_DIR")"

# check if script is in the right place
[ -d "$DOTFILES/dotconfig" ] || {
    echo "Error: dotfiles repository not found, the installation script NEEDS TO BE in the right directory!"
    exit 1
}

PACKAGE_DIR="$DOTFILES/packages/needed"
OFFICIAL_DIR="$PACKAGE_DIR/official"
AUR_DIR="$PACKAGE_DIR/aur"

# install dependencies needed for AUR helper
sudo pacman -S --needed base-devel

# install aur helper (paru) if missing
if ! command -v paru &>/dev/null; then
    echo "Installing paru..."

    rm -rf /tmp/paru-bin
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin

    cd /tmp/paru-bin
    makepkg -si --noconfirm

    cd "$DOTFILES"
fi

# install official packages
for PACKAGE_FILE in "$OFFICIAL_DIR"/*.txt; do
    [ -f "$PACKAGE_FILE" ] || continue

    echo "Installing official packages from $(basename "$PACKAGE_FILE")..."
    sudo pacman -S --needed - < "$PACKAGE_FILE"
done

# install AUR packages
for PACKAGE_FILE in "$AUR_DIR"/*.txt; do
    [ -f "$PACKAGE_FILE" ] || continue

    echo "Installing AUR packages from $(basename "$PACKAGE_FILE")..."
    paru -S --needed - < "$PACKAGE_FILE"
done

# create required directories
mkdir -p ~/.config ~/.local

# link dotfiles
ln -sfn "$DOTFILES/dotconfig"/* ~/.config/
ln -sfn "$DOTFILES/dotlocal"/* ~/.local/
ln -sfn "$DOTFILES/home"/* ~/

echo "Installation complete!"
```
