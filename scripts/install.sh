#!/usr/bin/env bash
#
# X11's Hyprland dotfiles installation & recovery script
# Target hardware: Dell Precision 7530 / 7730 and similar Intel + NVIDIA hybrid laptops
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Path Resolution & Environment Defaults
# -----------------------------------------------------------------------------
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
INSTALL_LOG="${INSTALL_LOG:-/tmp/dotfiles-install.log}"
PACMAN_CONF="${PACMAN_CONF:-/etc/pacman.conf}"
SYS_DRM_DIR="${SYS_DRM_DIR:-/sys/class/drm}"
UDEV_RULES_DIR="${UDEV_RULES_DIR:-/etc/udev/rules.d}"
LEGACY_USER="a7med"
LEGACY_HOME="/home/${LEGACY_USER}"

# -----------------------------------------------------------------------------
# Upgraded ANSI Color Palette
# -----------------------------------------------------------------------------
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_CYAN='\033[1;36m'
C_BLUE='\033[1;34m'
C_GREEN='\033[1;32m'
C_AMBER='\033[1;33m'
C_MAGENTA='\033[1;35m'
C_RED='\033[1;31m'
C_GRAY='\033[0;90m'

# Logging helpers with structured badges
step_header() {
    local step_num="$1"
    local total_steps="$2"
    local title="$3"
    echo ""
    if [ "${OPT_VERBOSE:-0}" -eq 1 ]; then
        printf "${C_CYAN}┌──────────────────────────────────────────────────────────────────────┐${C_RESET}\n"
        printf "${C_CYAN}│${C_RESET} ${C_BLUE}[%s/%s]${C_RESET} ${C_BOLD}%-62s${C_RESET} ${C_CYAN}│${C_RESET}\n" "$step_num" "$total_steps" "$title"
        printf "${C_CYAN}└──────────────────────────────────────────────────────────────────────┘${C_RESET}\n"
    else
        printf "${C_CYAN}[%s/%s]${C_RESET} ${C_BLUE}%s${C_RESET}\n" "$step_num" "$total_steps" "$title"
    fi
}

msg()        { printf "  ${C_BLUE}::${C_RESET} %s\n" "$*"; }
ok()         { printf "  ${C_GREEN}[OK]${C_RESET} %s\n" "$*"; }
linked_msg() { printf "  ${C_GREEN}[LINKED]${C_RESET} ${C_MAGENTA}%s${C_RESET} ${C_GRAY}-> %s${C_RESET}\n" "$1" "$2"; }
skip_msg()   { printf "  ${C_AMBER}[SKIP]${C_RESET} %s\n" "$*"; }
warn()       { printf "  ${C_AMBER}[WARN]${C_RESET} %s\n" "$*"; }
err()        { printf "  ${C_RED}[ERROR]${C_RESET} %s\n" "$*" >&2; exit 1; }

# Print the X11's Dotfiles ASCII banner literally (single-quoted EOF preserves backslashes and backticks)
print_logo() {
    printf "${C_CYAN}"
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
    printf "${C_RESET}\n"
}

# -----------------------------------------------------------------------------
# Terminal State & Sudo Keep-Alive Cleanup Trap
# -----------------------------------------------------------------------------
IN_ALT_SCREEN=0
SUDO_KEEPALIVE_PID=""

cleanup() {
    if [ "$IN_ALT_SCREEN" -eq 1 ]; then
        printf "\033[?25h\033[?1049l"
        IN_ALT_SCREEN=0
    else
        printf "\033[?25h"
    fi
    if [ -n "$SUDO_KEEPALIVE_PID" ]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM

# -----------------------------------------------------------------------------
# Hardware Detection & Interactive Menu State
# -----------------------------------------------------------------------------
HAS_NVIDIA=0
GPU_SUMMARY="Intel Integrated Graphics only (no NVIDIA dGPU detected)"
if grep -qi "0x10de" /sys/bus/pci/devices/*/vendor 2>/dev/null || \
   grep -qi "0x10de" "$SYS_DRM_DIR"/card*/device/vendor 2>/dev/null || \
   { command -v lspci &>/dev/null && lspci | grep -qi "nvidia"; }; then
    HAS_NVIDIA=1
    GPU_SUMMARY="Hybrid Intel iGPU + NVIDIA dGPU detected"
fi

OPT_NVIDIA="$HAS_NVIDIA"
OPT_BASE_UTILS=1
OPT_REPAIR=0
OPT_VERBOSE=0
SUBMENU_VISITED=0

# Arch Base Utilities sub-menu groups, descriptions, and package lists
UTIL_NAMES=(
    "Network Management"
    "Wireless & Wi-Fi"
    "Bluetooth"
    "Audio (PipeWire)"
    "Power & Brightness"
    "Archives & Filesystems"
)

UTIL_NOTES=(
    "enables NetworkManager.service"
    "iwd, wireless_tools, wpa_supplicant"
    "enables bluetooth.service"
    "pipewire, wireplumber, pavucontrol"
    "power-profiles-daemon, brightnessctl, acpi"
    "7zip, unzip, zip, ntfs-3g, gvfs"
)

UTIL_PKGS=(
    "networkmanager nm-connection-editor"
    "iwd wireless_tools wpa_supplicant"
    "bluez bluez-utils blueman"
    "pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol"
    "power-profiles-daemon brightnessctl acpi"
    "7zip unzip zip ntfs-3g gvfs"
)

# All base utility categories are checked by default
UTIL_ENABLED=(1 1 1 1 1 1)
UTIL_INSTALLED_COUNTS=()
UTIL_TOTAL_COUNTS=()

# Check which packages in each base utility group are already installed via pacman -Qi
refresh_util_install_status() {
    UTIL_INSTALLED_COUNTS=()
    UTIL_TOTAL_COUNTS=()
    local idx=0
    local group_pkgs pkg installed_count total_count
    for group_pkgs in "${UTIL_PKGS[@]}"; do
        installed_count=0
        total_count=0
        for pkg in $group_pkgs; do
            total_count=$((total_count + 1))
            if pacman -Qi "$pkg" &>/dev/null; then
                installed_count=$((installed_count + 1))
            fi
        done
        UTIL_INSTALLED_COUNTS[$idx]="$installed_count"
        UTIL_TOTAL_COUNTS[$idx]="$total_count"
        idx=$((idx + 1))
    done
}

# -----------------------------------------------------------------------------
# CLI Argument Parsing
# -----------------------------------------------------------------------------
NON_INTERACTIVE=0
for arg in "$@"; do
    case "$arg" in
        --fix|-f|--repair)
            OPT_REPAIR=1
            OPT_BASE_UTILS=0
            NON_INTERACTIVE=1
            ;;
        --verbose|-v)
            OPT_VERBOSE=1
            ;;
        --yes|-y|--non-interactive)
            NON_INTERACTIVE=1
            ;;
        --help|-h)
            print_logo
            cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --fix, -f, --repair    Run post-git-pull repair and symlink recovery directly
  --verbose, -v          Stream full command output live instead of logging to $INSTALL_LOG
  --yes, -y              Run non-interactively with default selections
  --help, -h             Show this help message
EOF
            exit 0
            ;;
        *)
            err "Unknown argument: $arg (use --help for usage)"
            ;;
    esac
done

# -----------------------------------------------------------------------------
# Pre-Flight Safety Checks
# -----------------------------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    err "Do not run this script as root. Run it as your regular user; sudo will prompt when needed."
fi

if [ ! -d "$DOTFILES/dotconfig" ] || [ ! -d "$DOTFILES/dotlocal" ]; then
    err "Dotfiles directories not found in $DOTFILES. Make sure the script is inside the repository."
fi

# -----------------------------------------------------------------------------
# Pure-Bash TUI Key Reader & Menus
# -----------------------------------------------------------------------------
# Reads a single keystroke or ANSI escape sequence into KEY_PRESSED
read_key() {
    local k=""
    local k1=""
    local k2=""
    IFS= read -rsn1 k || true
    if [ "$k" = $'\x1b' ]; then
        IFS= read -rsn1 -t 0.05 k1 || true
        if [ "$k1" = "[" ]; then
            IFS= read -rsn1 -t 0.05 k2 || true
            case "$k2" in
                A) KEY_PRESSED="UP" ;;
                B) KEY_PRESSED="DOWN" ;;
                *) KEY_PRESSED="ESC" ;;
            esac
        else
            KEY_PRESSED="ESC"
        fi
    elif [ "$k" = "" ]; then
        KEY_PRESSED="ENTER"
    elif [ "$k" = " " ]; then
        KEY_PRESSED="SPACE"
    elif [ "$k" = "k" ] || [ "$k" = "K" ]; then
        KEY_PRESSED="UP"
    elif [ "$k" = "j" ] || [ "$k" = "J" ]; then
        KEY_PRESSED="DOWN"
    elif [ "$k" = "q" ] || [ "$k" = "Q" ]; then
        KEY_PRESSED="QUIT"
    else
        KEY_PRESSED="$k"
    fi
}

format_checkbox() {
    if [ "$1" -eq 1 ]; then
        printf "${C_GREEN}[✓]${C_RESET}"
    else
        printf "${C_GRAY}[ ]${C_RESET}"
    fi
}

# Sub-menu: Arch Base Utilities
run_base_utils_submenu() {
    SUBMENU_VISITED=1
    refresh_util_install_status
    local cur=0
    local max_idx="${#UTIL_NAMES[@]}"

    while true; do
        printf "\033[H\033[2J"
        print_logo
        printf "  ${C_CYAN}Arch Base Utilities Sub-Menu${C_RESET}\n"
        printf "  ${C_GRAY}Controls: Up/Down (or j/k) move  |  Space toggles  |  Enter selects  |  q/Esc back${C_RESET}\n\n"

        local i=0
        while [ "$i" -lt "$max_idx" ]; do
            local prefix="   "
            local title_style="${C_RESET}"
            if [ "$i" -eq "$cur" ]; then
                prefix=" ${C_CYAN}>${C_RESET} "
                title_style="${C_BOLD}${C_CYAN}"
            fi

            local box
            box="$(format_checkbox "${UTIL_ENABLED[$i]}")"
            local inst="${UTIL_INSTALLED_COUNTS[$i]}"
            local tot="${UTIL_TOTAL_COUNTS[$i]}"
            local status_badge=""
            if [ "$inst" -eq "$tot" ]; then
                status_badge="${C_GREEN}(all $tot installed - will skip)${C_RESET}"
            elif [ "$inst" -gt 0 ]; then
                status_badge="${C_AMBER}($inst/$tot installed)${C_RESET}"
            else
                status_badge="${C_GRAY}(0/$tot installed)${C_RESET}"
            fi

            printf "%b%b %b%-24s${C_RESET} ${C_MAGENTA}%s${C_RESET} %b\n" \
                "$prefix" "$box" "$title_style" "${UTIL_NAMES[$i]}" "(${UTIL_NOTES[$i]})" "$status_badge"
            printf "       ${C_GRAY}Packages: %s${C_RESET}\n" "${UTIL_PKGS[$i]}"
            i=$((i + 1))
        done

        echo ""
        if [ "$cur" -eq "$max_idx" ]; then
            printf " ${C_CYAN}>${C_RESET} ${C_GREEN}${C_BOLD}[ Done / Back to Main Menu ]${C_RESET}\n"
        else
            printf "   ${C_BOLD}[ Done / Back to Main Menu ]${C_RESET}\n"
        fi

        read_key
        case "$KEY_PRESSED" in
            UP)
                if [ "$cur" -le 0 ]; then cur="$max_idx"; else cur=$((cur - 1)); fi
                ;;
            DOWN)
                if [ "$cur" -ge "$max_idx" ]; then cur=0; else cur=$((cur + 1)); fi
                ;;
            SPACE)
                if [ "$cur" -lt "$max_idx" ]; then
                    if [ "${UTIL_ENABLED[$cur]}" -eq 1 ]; then
                        UTIL_ENABLED[$cur]=0
                    else
                        UTIL_ENABLED[$cur]=1
                    fi
                fi
                ;;
            ENTER)
                if [ "$cur" -eq "$max_idx" ]; then
                    # Update parent checkbox based on whether at least one sub-group is enabled
                    local any_on=0
                    local val
                    for val in "${UTIL_ENABLED[@]}"; do
                        [ "$val" -eq 1 ] && any_on=1
                    done
                    OPT_BASE_UTILS="$any_on"
                    return 0
                else
                    if [ "${UTIL_ENABLED[$cur]}" -eq 1 ]; then
                        UTIL_ENABLED[$cur]=0
                    else
                        UTIL_ENABLED[$cur]=1
                    fi
                fi
                ;;
            ESC|QUIT)
                return 0
                ;;
        esac
    done
}

# Pre-Flight Execution Summary & Two-Step Confirmation
run_confirmation_screen() {
    refresh_util_install_status
    local choice=0

    while true; do
        printf "\033[H\033[2J"
        print_logo
        printf "  ${C_CYAN}Execution Summary & Pre-Flight Review${C_RESET}\n"
        printf "  ${C_GRAY}Review the planned changes below before modifying your system:${C_RESET}\n\n"

        # 1. Execution Mode
        if [ "$OPT_REPAIR" -eq 1 ]; then
            printf "  ${C_BLUE}Mode:${C_RESET}            ${C_AMBER}Fix / Repair Broken Installation (Post-git pull --force Recovery)${C_RESET}\n"
        else
            printf "  ${C_BLUE}Mode:${C_RESET}            ${C_GREEN}Full Dotfiles & Package Installation${C_RESET}\n"
        fi

        # 2. Verbosity
        if [ "$OPT_VERBOSE" -eq 1 ]; then
            printf "  ${C_BLUE}Output Mode:${C_RESET}     ${C_CYAN}Verbose (Live command streaming with phase banners)${C_RESET}\n"
        else
            printf "  ${C_BLUE}Output Mode:${C_RESET}     ${C_GRAY}Clean progress view (Full logs redirected to ${C_MAGENTA}%s${C_GRAY})${C_RESET}\n" "$INSTALL_LOG"
        fi

        # 3. GPU & Drivers
        if [ "$OPT_NVIDIA" -eq 1 ]; then
            printf "  ${C_BLUE}GPU & Drivers:${C_RESET}   ${C_GREEN}Install NVIDIA 580xx DKMS/utils + generate /dev/dri/{igpu,dgpu} udev rules${C_RESET}\n"
        else
            printf "  ${C_BLUE}GPU & Drivers:${C_RESET}   ${C_AMBER}Skip NVIDIA packages (%s)${C_RESET}\n" "$GPU_SUMMARY"
        fi

        # 4. Selected Package Groups
        printf "  ${C_BLUE}Repo Packages:${C_RESET}   ${C_MAGENTA}fonts-official, needed-official, performance-official, needed-aur, performance-aur${C_RESET}\n"
        if [ "$OPT_REPAIR" -eq 1 ]; then
            printf "                   ${C_GRAY}(Repair mode: only missing packages will be installed; existing builds skipped)${C_RESET}\n"
        fi

        # 5. Arch Base Utilities
        if [ "$OPT_BASE_UTILS" -eq 1 ]; then
            local enabled_groups=()
            local idx=0
            while [ "$idx" -lt "${#UTIL_NAMES[@]}" ]; do
                if [ "${UTIL_ENABLED[$idx]}" -eq 1 ]; then
                    local missing=$(( ${UTIL_TOTAL_COUNTS[$idx]} - ${UTIL_INSTALLED_COUNTS[$idx]} ))
                    enabled_groups+=("${UTIL_NAMES[$idx]} ($missing to install)")
                fi
                idx=$((idx + 1))
            done
            if [ "${#enabled_groups[@]}" -gt 0 ]; then
                printf "  ${C_BLUE}Base Utilities:${C_RESET}  ${C_MAGENTA}%s${C_RESET}\n" "$(IFS=', '; echo "${enabled_groups[*]}")"
            else
                printf "  ${C_BLUE}Base Utilities:${C_RESET}  ${C_AMBER}None selected${C_RESET}\n"
            fi
        else
            printf "  ${C_BLUE}Base Utilities:${C_RESET}  ${C_AMBER}Skipped${C_RESET}\n"
        fi

        # 6. Services to Enable
        local svcs=("power-profiles-daemon.service")
        if [ "$OPT_BASE_UTILS" -eq 1 ]; then
            [ "${UTIL_ENABLED[0]}" -eq 1 ] && svcs=("NetworkManager.service" "${svcs[@]}")
            [ "${UTIL_ENABLED[2]}" -eq 1 ] && svcs+=("bluetooth.service")
        else
            svcs=("NetworkManager.service" "bluetooth.service" "${svcs[@]}")
        fi
        [ "$OPT_NVIDIA" -eq 1 ] && svcs+=("nvidia-powerd.service")
        printf "  ${C_BLUE}Systemd Units:${C_RESET}   ${C_MAGENTA}%s${C_RESET}\n" "${svcs[*]}"

        # 7. Paths, Symlinks, and Backups
        printf "  ${C_BLUE}Path Patching:${C_RESET}   Rewrite ${C_MAGENTA}%s${C_RESET} -> ${C_MAGENTA}%s${C_RESET} across configs, scripts & symlinks\n" "$LEGACY_HOME" "$HOME"
        printf "  ${C_BLUE}Symlink Targets:${C_RESET} ${C_MAGENTA}~/.config/*, ~/.local/{bin,state,share/*}, ~/.local/share/colorschemes, ~/.*${C_RESET}\n"
        printf "  ${C_BLUE}Safety Backup:${C_RESET}   Conflicting files moved to ${C_MAGENTA}%s${C_RESET}\n\n" "$BACKUP_DIR"

        printf "  ${C_GRAY}Use Up/Down (or j/k) and press Enter:${C_RESET}\n\n"
        if [ "$choice" -eq 0 ]; then
            printf "   ${C_CYAN}>${C_RESET} ${C_GREEN}${C_BOLD}[ Confirm & Start Installation ]${C_RESET}\n"
            printf "     ${C_GRAY}[ Go Back to Menu ]${C_RESET}\n"
        else
            printf "     ${C_GRAY}[ Confirm & Start Installation ]${C_RESET}\n"
            printf "   ${C_CYAN}>${C_RESET} ${C_AMBER}${C_BOLD}[ Go Back to Menu ]${C_RESET}\n"
        fi

        read_key
        case "$KEY_PRESSED" in
            UP|DOWN)
                if [ "$choice" -eq 0 ]; then choice=1; else choice=0; fi
                ;;
            ENTER)
                if [ "$choice" -eq 0 ]; then
                    return 0
                else
                    return 1
                fi
                ;;
            ESC|QUIT)
                return 1
                ;;
        esac
    done
}

# Main Interactive Menu
run_interactive_menu() {
    printf "\033[?1049h\033[?25l"
    IN_ALT_SCREEN=1
    local cur=0

    while true; do
        printf "\033[H\033[2J"
        print_logo
        printf "  ${C_CYAN}Interactive Configuration Menu${C_RESET}\n"
        printf "  ${C_GRAY}Controls: Up/Down (or j/k) move  |  Space toggles [✓]/[ ]  |  Enter selects  |  q/Esc quits${C_RESET}\n\n"

        # Option 0: NVIDIA Drivers
        local nvidia_tag=""
        if [ "$HAS_NVIDIA" -eq 1 ]; then
            nvidia_tag="${C_GREEN}(NVIDIA GPU detected)${C_RESET}"
        else
            nvidia_tag="${C_AMBER}(No NVIDIA GPU detected)${C_RESET}"
        fi
        if [ "$cur" -eq 0 ]; then
            printf " ${C_CYAN}>${C_RESET} %b ${C_BOLD}${C_CYAN}1. Install NVIDIA Drivers & Hybrid GPU Config${C_RESET} %b\n" "$(format_checkbox "$OPT_NVIDIA")" "$nvidia_tag"
        else
            printf "   %b 1. Install NVIDIA Drivers & Hybrid GPU Config %b\n" "$(format_checkbox "$OPT_NVIDIA")" "$nvidia_tag"
        fi
        printf "       ${C_GRAY}Installs nvidia-580xx DKMS/utils and writes /dev/dri/{igpu,dgpu} udev rules${C_RESET}\n\n"

        # Option 1: Arch Base Utilities Sub-Menu
        local enabled_cnt=0
        local v
        for v in "${UTIL_ENABLED[@]}"; do [ "$v" -eq 1 ] && enabled_cnt=$((enabled_cnt + 1)); done
        local sub_tag="${C_MAGENTA}(${enabled_cnt}/${#UTIL_NAMES[@]} groups selected - press Enter to customize)${C_RESET}"
        if [ "$cur" -eq 1 ]; then
            printf " ${C_CYAN}>${C_RESET} %b ${C_BOLD}${C_CYAN}2. Install Recommended Arch Base Utilities (Sub-Menu)${C_RESET} %b\n" "$(format_checkbox "$OPT_BASE_UTILS")" "$sub_tag"
        else
            printf "   %b 2. Install Recommended Arch Base Utilities (Sub-Menu) %b\n" "$(format_checkbox "$OPT_BASE_UTILS")" "$sub_tag"
        fi
        printf "       ${C_GRAY}NetworkManager, iwd/wpa_supplicant, Bluez, PipeWire, power-profiles-daemon, archives${C_RESET}\n\n"

        # Option 2: Fix / Repair Broken Installation
        if [ "$cur" -eq 2 ]; then
            printf " ${C_CYAN}>${C_RESET} %b ${C_BOLD}${C_CYAN}3. Fix / Repair Broken Installation (Post-git pull --force Recovery)${C_RESET}\n" "$(format_checkbox "$OPT_REPAIR")"
        else
            printf "   %b 3. Fix / Repair Broken Installation (Post-git pull --force Recovery)\n" "$(format_checkbox "$OPT_REPAIR")"
        fi
        printf "       ${C_GRAY}Re-patches %s paths, restores +x permissions, repairs symlinks & udev rules${C_RESET}\n\n" "$LEGACY_HOME"

        # Option 3: Verbose Mode
        if [ "$cur" -eq 3 ]; then
            printf " ${C_CYAN}>${C_RESET} %b ${C_BOLD}${C_CYAN}4. Verbose Installation Output${C_RESET}\n" "$(format_checkbox "$OPT_VERBOSE")"
        else
            printf "   %b 4. Verbose Installation Output\n" "$(format_checkbox "$OPT_VERBOSE")"
        fi
        printf "       ${C_GRAY}Streams full pacman/paru/makepkg output live instead of logging to %s${C_RESET}\n\n" "$INSTALL_LOG"

        # Option 4: Confirm & Review Execution Plan
        if [ "$cur" -eq 4 ]; then
            printf " ${C_CYAN}>${C_RESET} ${C_GREEN}${C_BOLD}[ Confirm & Review Execution Plan ]${C_RESET}\n"
        else
            printf "   ${C_BOLD}[ Confirm & Review Execution Plan ]${C_RESET}\n"
        fi

        read_key
        case "$KEY_PRESSED" in
            UP)
                if [ "$cur" -le 0 ]; then cur=4; else cur=$((cur - 1)); fi
                ;;
            DOWN)
                if [ "$cur" -ge 4 ]; then cur=0; else cur=$((cur + 1)); fi
                ;;
            SPACE)
                case "$cur" in
                    0) OPT_NVIDIA=$((1 - OPT_NVIDIA)) ;;
                    1)
                        OPT_BASE_UTILS=$((1 - OPT_BASE_UTILS))
                        local idx=0
                        while [ "$idx" -lt "${#UTIL_ENABLED[@]}" ]; do
                            UTIL_ENABLED[$idx]="$OPT_BASE_UTILS"
                            idx=$((idx + 1))
                        done
                        ;;
                    2) OPT_REPAIR=$((1 - OPT_REPAIR)) ;;
                    3) OPT_VERBOSE=$((1 - OPT_VERBOSE)) ;;
                    4)
                        if [ "$OPT_BASE_UTILS" -eq 1 ] && [ "$SUBMENU_VISITED" -eq 0 ]; then
                            run_base_utils_submenu
                        fi
                        if run_confirmation_screen; then
                            break
                        fi
                        ;;
                esac
                ;;
            ENTER)
                case "$cur" in
                    0) OPT_NVIDIA=$((1 - OPT_NVIDIA)) ;;
                    1)
                        OPT_BASE_UTILS=1
                        run_base_utils_submenu
                        ;;
                    2) OPT_REPAIR=$((1 - OPT_REPAIR)) ;;
                    3) OPT_VERBOSE=$((1 - OPT_VERBOSE)) ;;
                    4)
                        if [ "$OPT_BASE_UTILS" -eq 1 ] && [ "$SUBMENU_VISITED" -eq 0 ]; then
                            run_base_utils_submenu
                        fi
                        if run_confirmation_screen; then
                            break
                        fi
                        ;;
                esac
                ;;
            ESC|QUIT)
                cleanup
                printf "${C_AMBER}[SKIP]${C_RESET} Installation cancelled by user.\n"
                exit 0
                ;;
        esac
    done

    printf "\033[?25h\033[?1049l"
    IN_ALT_SCREEN=0
}

# -----------------------------------------------------------------------------
# Command Runner with Verbosity Filtering, Spinner & Error Log Dump
# -----------------------------------------------------------------------------
run_cmd() {
    local desc="$1"
    shift

    if [ "$OPT_VERBOSE" -eq 1 ]; then
        msg "$desc"
        if ! "$@"; then
            err "Command failed: $*"
        fi
        ok "$desc"
        return 0
    fi

    printf "=== [%s] %s ===\nCommand: %s\n" "$(date +%H:%M:%S)" "$desc" "$*" >> "$INSTALL_LOG"

    "$@" >> "$INSTALL_LOG" 2>&1 &
    local cmd_pid=$!
    local spin='-\|/'
    local s_idx=0

    while kill -0 "$cmd_pid" 2>/dev/null; do
        s_idx=$(( (s_idx + 1) % 4 ))
        printf "\r  ${C_CYAN}[%c]${C_RESET} %s..." "${spin:$s_idx:1}" "$desc"
        sleep 0.1
    done

    local exit_code=0
    wait "$cmd_pid" || exit_code=$?
    printf "\r\033[2K"

    if [ "$exit_code" -ne 0 ]; then
        printf "  ${C_RED}[ERROR]${C_RESET} %s failed (exit code %d).\n" "$desc" "$exit_code" >&2
        printf "  ${C_RED}Last 25 lines of %s:${C_RESET}\n" "$INSTALL_LOG" >&2
        printf "  ${C_GRAY}------------------------------------------------------------${C_RESET}\n" >&2
        tail -n 25 "$INSTALL_LOG" 2>/dev/null | sed 's/^/  /' >&2 || true
        printf "  ${C_GRAY}------------------------------------------------------------${C_RESET}\n" >&2
        exit "$exit_code"
    fi

    ok "$desc"
}

# -----------------------------------------------------------------------------
# Launch Interactive Menu (Unless Non-Interactive CLI Flag Passed)
# -----------------------------------------------------------------------------
: > "$INSTALL_LOG"
if [ "$NON_INTERACTIVE" -eq 0 ] && [ -t 0 ]; then
    run_interactive_menu
fi

print_logo
if [ "$OPT_REPAIR" -eq 1 ]; then
    printf "  ${C_AMBER}[WARN]${C_RESET} Running in ${C_BOLD}Repair / Recovery Mode${C_RESET} (post-git pull --force fixup)\n"
fi
if [ "$OPT_VERBOSE" -eq 0 ]; then
    printf "  ${C_GRAY}Detailed command logs are being written to: ${C_MAGENTA}%s${C_RESET}\n" "$INSTALL_LOG"
fi

# Authenticate sudo upfront and keep the timestamp alive in the background
sudo -v
(while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
SUDO_KEEPALIVE_PID=$!

TOTAL_STEPS=7

# =============================================================================
# STEP 1: Pacman Configuration, Build Dependencies & AUR Helper (paru)
# =============================================================================
step_header 1 "$TOTAL_STEPS" "Preparing Pacman, Multilib & AUR Helper (paru)"

if [ -f "$PACMAN_CONF" ] && ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    msg "Enabling [multilib] repository in $PACMAN_CONF..."
    sudo sed -i '/^\s*#\s*\[multilib\]/,/^\s*#\s*Include/ s/^\s*#//' "$PACMAN_CONF"
    run_cmd "Synchronizing pacman databases (-Sy)" sudo pacman -Sy
else
    ok "[multilib] repository is already enabled in $PACMAN_CONF"
fi

if pacman -Qq lib32-egl-wayland &>/dev/null; then
    run_cmd "Removing outdated AUR lib32-egl-wayland package" sudo pacman -Rdd --noconfirm lib32-egl-wayland
fi

if ! pacman -Qi base-devel &>/dev/null || ! pacman -Qi git &>/dev/null; then
    run_cmd "Installing base-devel and git" sudo pacman -S --needed --noconfirm base-devel git
else
    skip_msg "base-devel and git are already installed"
fi

if [ "$OPT_NVIDIA" -eq 1 ]; then
    KERNEL_HEADERS=()
    for kdir in /usr/lib/modules/*; do
        [ -d "$kdir" ] || continue
        if [ -f "$kdir/pkgbase" ]; then
            kbase="$(cat "$kdir/pkgbase")"
            header_pkg="${kbase}-headers"
            if ! pacman -Qi "$header_pkg" &>/dev/null; then
                KERNEL_HEADERS+=("$header_pkg")
            fi
        fi
    done
    if [ "${#KERNEL_HEADERS[@]}" -gt 0 ]; then
        run_cmd "Installing kernel headers for DKMS (${KERNEL_HEADERS[*]})" sudo pacman -S --needed --noconfirm "${KERNEL_HEADERS[@]}" || warn "Could not install some kernel headers; check your kernel package."
    else
        ok "Matching kernel headers for DKMS are already present"
    fi
fi

if ! command -v paru &>/dev/null; then
    rm -rf /tmp/paru-bin
    run_cmd "Cloning paru-bin from AUR" git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
    run_cmd "Building and installing paru-bin" bash -c "cd /tmp/paru-bin && makepkg -si --noconfirm"
    rm -rf /tmp/paru-bin
else
    ok "AUR helper (paru) is already installed"
fi

# =============================================================================
# STEP 2: Arch Base Utilities Installation
# =============================================================================
step_header 2 "$TOTAL_STEPS" "Installing Selected Arch Base Utilities"

if [ "$OPT_BASE_UTILS" -eq 1 ]; then
    refresh_util_install_status
    idx=0
    while [ "$idx" -lt "${#UTIL_NAMES[@]}" ]; do
        group_name="${UTIL_NAMES[$idx]}"
        if [ "${UTIL_ENABLED[$idx]}" -eq 0 ]; then
            skip_msg "$group_name (unchecked in menu)"
        else
            missing_pkgs=()
            for pkg in ${UTIL_PKGS[$idx]}; do
                if ! pacman -Qi "$pkg" &>/dev/null; then
                    missing_pkgs+=("$pkg")
                fi
            done
            if [ "${#missing_pkgs[@]}" -eq 0 ]; then
                skip_msg "$group_name (all ${UTIL_TOTAL_COUNTS[$idx]} packages already installed)"
            else
                run_cmd "Installing $group_name (${missing_pkgs[*]})" sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"
            fi
        fi
        idx=$((idx + 1))
    done
else
    skip_msg "Arch Base Utilities group skipped"
fi

# =============================================================================
# STEP 3: Dotfiles Repository Package Lists (Official & AUR)
# =============================================================================
step_header 3 "$TOTAL_STEPS" "Installing Repository Package Lists"

# Sanitize known package list mismatches in the repository before reading
if [ -f "$AUR_DIR/needed-aur.txt" ] && grep -qx "7z" "$AUR_DIR/needed-aur.txt"; then
    sed -i 's/^7z$/7zip/' "$AUR_DIR/needed-aur.txt"
fi
if [ -f "$AUR_DIR/nvidia-aur.txt" ] && grep -qx "lib32-egl-wayland" "$AUR_DIR/nvidia-aur.txt"; then
    sed -i '/^lib32-egl-wayland$/d' "$AUR_DIR/nvidia-aur.txt"
fi

install_pkg_file() {
    local manager="$1"
    local file="$2"
    local base
    base="$(basename "$file")"

    if [[ "$base" == nvidia-* ]] && [ "$OPT_NVIDIA" -eq 0 ]; then
        skip_msg "Skipping $base (NVIDIA installation disabled)"
        return 0
    fi

    local raw_pkgs=()
    mapfile -t raw_pkgs < <(awk '{gsub(/#.*/, ""); for (i = 1; i <= NF; i++) print $i}' "$file")
    if [ "${#raw_pkgs[@]}" -eq 0 ]; then
        skip_msg "Skipping $base (empty package list)"
        return 0
    fi

    local pkgs=()
    local pkg
    for pkg in "${raw_pkgs[@]}"; do
        case "$pkg" in
            7z|p7zip)
                pkgs+=("7zip")
                ;;
            lib32-egl-wayland)
                continue
                ;;
            opencl-nvidia)
                if [ -f "$AUR_DIR/nvidia-aur.txt" ] && grep -q "nvidia-580xx" "$AUR_DIR/nvidia-aur.txt"; then
                    if [ "$manager" = "paru" ]; then
                        pkgs+=("opencl-nvidia-580xx")
                    fi
                    continue
                fi
                pkgs+=("$pkg")
                ;;
            *)
                pkgs+=("$pkg")
                ;;
        esac
    done

    # Filter out packages that are already installed (keeps Repair Mode fast and avoids redundant rebuilds)
    local missing_pkgs=()
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ "${#missing_pkgs[@]}" -eq 0 ]; then
        skip_msg "$base (all ${#pkgs[@]} packages already installed)"
        return 0
    fi

    if [ "$manager" = "pacman" ]; then
        if ! run_cmd "Installing ${#missing_pkgs[@]} official package(s) from $base" sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}"; then
            warn "Batch install from $base encountered an issue; retrying individually..."
            for pkg in "${missing_pkgs[@]}"; do
                run_cmd "Installing $pkg" sudo pacman -S --needed --noconfirm "$pkg" || warn "Could not install package: $pkg"
            done
        fi
    else
        if ! run_cmd "Installing ${#missing_pkgs[@]} AUR package(s) from $base" paru -S --needed --noconfirm "${missing_pkgs[@]}"; then
            warn "Batch install from $base encountered an issue; retrying individually..."
            for pkg in "${missing_pkgs[@]}"; do
                run_cmd "Installing $pkg" paru -S --needed --noconfirm "$pkg" || warn "Could not install package: $pkg"
            done
        fi
    fi
}

if [ -d "$OFFICIAL_DIR" ]; then
    for pkg_file in "$OFFICIAL_DIR"/*.txt; do
        [ -f "$pkg_file" ] || continue
        install_pkg_file pacman "$pkg_file"
    done
fi

if [ -d "$AUR_DIR" ]; then
    for pkg_file in "$AUR_DIR"/*.txt; do
        [ -f "$pkg_file" ] || continue
        install_pkg_file paru "$pkg_file"
    done
fi

# =============================================================================
# STEP 4: Path Sanitization, Symlink Repair & Script Permissions (fix-dotfiles)
# =============================================================================
step_header 4 "$TOTAL_STEPS" "Patching Hardcoded Paths, Repo Symlinks & Script Permissions"

# 1. Patch hardcoded /home/a7med paths in regular files (excluding install.sh and symlinks)
patched_files=0
while IFS= read -r -d '' file; do
    if grep -q "$LEGACY_HOME" "$file" 2>/dev/null; then
        sed -i \
            -e "s|${LEGACY_HOME}/dotfiles|$DOTFILES|g" \
            -e "s|${LEGACY_HOME}/Bookmarks/hypr|$DOTFILES/dotconfig/hypr|g" \
            -e "s|${LEGACY_HOME}|$HOME|g" \
            "$file"
        patched_files=$((patched_files + 1))
    fi
done < <(find "$DOTFILES/dotconfig" "$DOTFILES/dotlocal" "$DOTFILES/home" "$DOTFILES/scripts" "$DOTFILES/colorschemes" -type f ! -name "install.sh" -print0 2>/dev/null || true)
ok "Scanned repository files and patched hardcoded $LEGACY_HOME paths ($patched_files file(s) updated)"

# 2. Rewrite any internal repository symlinks that point to /home/a7med/...
repaired_repo_links=0
while IFS= read -r -d '' link; do
    target="$(readlink "$link")"
    if [[ "$target" == "$LEGACY_HOME"* ]]; then
        new_target="$target"
        new_target="${new_target/#${LEGACY_HOME}\/dotfiles/$DOTFILES}"
        new_target="${new_target/#${LEGACY_HOME}\/Bookmarks\/hypr/$DOTFILES/dotconfig/hypr}"
        new_target="${new_target/#${LEGACY_HOME}/$HOME}"
        ln -sfn "$new_target" "$link"
        repaired_repo_links=$((repaired_repo_links + 1))
    fi
done < <(find "$DOTFILES" -path "$DOTFILES/.git" -prune -o -type l -print0 2>/dev/null || true)

# 3. Explicitly verify and repair core launcher symlinks in dotlocal/bin/ (post-git pull --force recovery)
declare -A BIN_LINKS=(
    ["artapps"]="$DOTFILES/dotconfig/hypr/scripts/artapps/artapps.sh"
    ["colorpicker"]="$DOTFILES/dotconfig/hypr/scripts/screenshot/colorpicker.sh"
    ["envswitcher"]="$DOTFILES/scripts/envswitcher/envswitcher.sh"
    ["game-off"]="$DOTFILES/dotconfig/hypr/scripts/gaming-mode/game-off.sh"
    ["game-on"]="$DOTFILES/dotconfig/hypr/scripts/gaming-mode/game-on.sh"
    ["gamemode-controller"]="$DOTFILES/dotconfig/hypr/scripts/gaming-mode/gamemode-controller.sh"
    ["loginm"]="$DOTFILES/scripts/login-menu/loginmenu.sh"
    ["monitorscrshot"]="$DOTFILES/dotconfig/hypr/scripts/screenshot/monitorscrshot.sh"
    ["preset-switcher"]="$DOTFILES/dotconfig/hypr/scripts/hypr-options/preset.sh"
    ["screenshot"]="$DOTFILES/dotconfig/hypr/scripts/screenshot/screenshot.sh"
    ["themeswitcher"]="$DOTFILES/dotconfig/hypr/scripts/ThemeSwitcher/themeswitcher.sh"
    ["thexctl"]="$DOTFILES/scripts/thexctl/thexctl.sh"
    ["wallchanger"]="$DOTFILES/dotconfig/hypr/scripts/ThemeSwitcher/wallchanger.sh"
)

for bin_name in "${!BIN_LINKS[@]}"; do
    target="${BIN_LINKS[$bin_name]}"
    if [ -e "$target" ]; then
        ln -sfn "$target" "$DOTFILES/dotlocal/bin/$bin_name"
    fi
done
ok "Verified internal repository symlinks and dotlocal/bin launchers ($repaired_repo_links link(s) rewritten)"

# 4. Restore +x executable permissions across all scripts, binaries, and git hooks
find "$DOTFILES/scripts" "$DOTFILES/dotconfig/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$DOTFILES/dotlocal/bin" -maxdepth 1 -type f -exec chmod +x {} + 2>/dev/null || true
[ -f "$DOTFILES/.githooks/pre-push" ] && chmod +x "$DOTFILES/.githooks/pre-push"
ok "Restored executable (+x) permissions on all .sh scripts, dotlocal/bin binaries, and git hooks"

# =============================================================================
# STEP 5: Deploying User Configuration & Home Directory Symlinks
# =============================================================================
step_header 5 "$TOTAL_STEPS" "Linking Dotfiles into ~/.config, ~/.local & \$HOME"

# Back up any pre-existing regular file or mismatched symlink before linking
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
            warn "Backed up conflicting path ${dst} -> ${backup_target}"
        fi
    fi

    ln -sfn "$src" "$dst"
    linked_msg "$dst" "$src"
}

mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/share" \
    "$HOME/.cache/colorschemes" \
    "$HOME/.cache/wallpaper-previews"

shopt -s nullglob
for item in "$DOTFILES/dotconfig"/*; do
    link_item "$item" "$HOME/.config/$(basename "$item")"
done

for item in "$DOTFILES/dotlocal"/*; do
    name="$(basename "$item")"
    if [ "$name" = "share" ]; then
        for share_item in "$DOTFILES/dotlocal/share"/*; do
            link_item "$share_item" "$HOME/.local/share/$(basename "$share_item")"
        done
    else
        link_item "$item" "$HOME/.local/$name"
    fi
done

if [ -d "$DOTFILES/colorschemes" ]; then
    link_item "$DOTFILES/colorschemes" "$HOME/.local/share/colorschemes"
fi

shopt -s dotglob
for item in "$DOTFILES/home"/*; do
    base="$(basename "$item")"
    [ "$base" = "." ] || [ "$base" = ".." ] && continue
    link_item "$item" "$HOME/$base"
done
shopt -u dotglob nullglob

# Ensure Noctalia setup marker and default theme state are initialized
mkdir -p "$DOTFILES/dotlocal/state/noctalia"
touch "$DOTFILES/dotlocal/state/noctalia/.setup-complete"

if [ ! -f "$HOME/.cache/colorschemes/current_theme" ]; then
    echo "everforest" > "$HOME/.cache/colorschemes/current_theme"
    ok "Seeded default theme state (everforest) in ~/.cache/colorschemes/current_theme"
fi

# Generate initial Pywal color cache if wal is available and ~/.cache/wal/colors-hyprland.lua is missing
if command -v wal &>/dev/null && [ ! -f "$HOME/.cache/wal/colors-hyprland.lua" ]; then
    active_theme="$(cat "$HOME/.cache/colorschemes/current_theme" 2>/dev/null || echo "everforest")"
    wall_link="$HOME/.local/share/colorschemes/$active_theme/current_wallpaper"
    if [ -L "$wall_link" ] && [ -e "$wall_link" ]; then
        run_cmd "Generating initial Pywal color templates" wal -n -i "$(readlink -f "$wall_link")" -q || true
    fi
fi

# =============================================================================
# STEP 6: Hybrid GPU Udev Rules (/dev/dri/igpu & /dev/dri/dgpu) & Display Rules
# =============================================================================
step_header 6 "$TOTAL_STEPS" "Configuring GPU Udev Symlinks & Display Fallbacks"

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

    if [ -n "$igpu_pci" ] && [ -n "$dgpu_pci" ] && [ "$OPT_NVIDIA" -eq 1 ]; then
        sudo mkdir -p "$UDEV_RULES_DIR"
        sudo tee "$UDEV_RULES_DIR/99-hypr-gpu.rules" >/dev/null <<EOF
KERNEL=="card*", KERNELS=="$igpu_pci", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/igpu"
KERNEL=="card*", KERNELS=="$dgpu_pci", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/dgpu"
EOF
        sudo udevadm control --reload
        sudo udevadm trigger --subsystem-match=drm
        ok "Created udev rules in $UDEV_RULES_DIR/99-hypr-gpu.rules (igpu=$igpu_pci, dgpu=$dgpu_pci)"
    elif [ -n "$igpu_pci" ]; then
        warn "Only integrated GPU ($igpu_pci) active; commenting out AQ_DRM_DEVICES if set in env config"
        [ -f "$DOTFILES/dotconfig/hypr/env.conf" ] && sed -i 's/^\s*env\s*=\s*AQ_DRM_DEVICES/# env = AQ_DRM_DEVICES/' "$DOTFILES/dotconfig/hypr/env.conf"
    else
        skip_msg "No PCI DRM devices detected in $SYS_DRM_DIR"
    fi
}
setup_gpu_udev_rules

# Ensure a fallback monitor rule exists in monitors.lua or monitors.conf for other laptop panels
if [ -f "$DOTFILES/dotconfig/hypr/monitors.lua" ]; then
    if ! grep -q 'output\s*=\s*""' "$DOTFILES/dotconfig/hypr/monitors.lua"; then
        cat >> "$DOTFILES/dotconfig/hypr/monitors.lua" << 'EOF'

-- Fallback rule for unconfigured displays
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})
EOF
        ok "Added fallback monitor rule to dotconfig/hypr/monitors.lua"
    else
        ok "Fallback monitor rule already present in dotconfig/hypr/monitors.lua"
    fi
elif [ -f "$DOTFILES/dotconfig/hypr/monitors.conf" ]; then
    if ! grep -q "^monitor=,preferred,auto,1" "$DOTFILES/dotconfig/hypr/monitors.conf"; then
        printf "\n# Fallback rule for unconfigured displays\nmonitor=,preferred,auto,1\n" >> "$DOTFILES/dotconfig/hypr/monitors.conf"
        ok "Added fallback monitor rule to dotconfig/hypr/monitors.conf"
    fi
fi

# =============================================================================
# STEP 7: Git Hooks, Systemd Services, XDG Directories & Default Shell
# =============================================================================
step_header 7 "$TOTAL_STEPS" "Enabling System Services, Git Hooks & Default Shell"

if [ -d "$DOTFILES/.git" ] && [ -d "$DOTFILES/.githooks" ]; then
    git -C "$DOTFILES" config core.hooksPath .githooks
    ok "Configured repository git hooks path (.githooks)"
fi

SERVICES_TO_ENABLE=("power-profiles-daemon")
if [ "$OPT_BASE_UTILS" -eq 1 ]; then
    [ "${UTIL_ENABLED[0]}" -eq 1 ] && SERVICES_TO_ENABLE=("NetworkManager" "${SERVICES_TO_ENABLE[@]}")
    [ "${UTIL_ENABLED[2]}" -eq 1 ] && SERVICES_TO_ENABLE+=("bluetooth")
else
    SERVICES_TO_ENABLE=("NetworkManager" "bluetooth" "${SERVICES_TO_ENABLE[@]}")
fi
[ "$OPT_NVIDIA" -eq 1 ] && SERVICES_TO_ENABLE+=("nvidia-powerd")

for svc in "${SERVICES_TO_ENABLE[@]}"; do
    if systemctl list-unit-files "${svc}.service" &>/dev/null; then
        sudo systemctl enable --now "${svc}.service" >/dev/null 2>&1 || true
        ok "Enabled service: ${svc}.service"
    else
        skip_msg "Service unit ${svc}.service not present on system"
    fi
done

if command -v xdg-user-dirs-update &>/dev/null; then
    xdg-user-dirs-update
    ok "Updated XDG user directories"
fi

if command -v zsh &>/dev/null && [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    msg "Setting default login shell to zsh..."
    chsh -s "$(command -v zsh)" "${USER:-$(id -un)}" || warn "Could not change shell automatically; run: chsh -s $(command -v zsh)"
else
    ok "Default shell is already set to zsh"
fi

echo ""
if [ -d "$BACKUP_DIR" ]; then
    warn "Existing files that conflicted with symlinks were backed up to: ${C_MAGENTA}$BACKUP_DIR${C_RESET}"
fi
ok "All tasks completed. Log out or reboot to start your Hyprland session."