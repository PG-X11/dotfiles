#!/bin/bash

set -e

mkdir -p packages

echo "Updating package lists..."

# Official repository packages
pacman -Qqn  | sort > packages/official-all.txt
pacman -Qqen | sort > packages/official-manual.txt

# AUR / foreign packages
pacman -Qqm  | sort > packages/aur-all.txt
pacman -Qqem | sort > packages/aur-manual.txt

echo "Package lists updated."

## AI GEN
