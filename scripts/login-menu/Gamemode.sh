#!/bin/bash
mapfile -t DISPLAYS < <(grep -l "^connected" /sys/class/drm/card*-*/status | sed 's|.*/card[0-9]*-||; s|/status||')

if [ ${#DISPLAYS[@]} -eq 1 ]; then
    SELECTED="${DISPLAYS[0]}"
else
    echo "Connected displays:"
    for i in "${!DISPLAYS[@]}"; do
        echo "  $((i+1))) ${DISPLAYS[$i]}"
    done
    read -p "Select display: " CHOICE
    SELECTED="${DISPLAYS[$((CHOICE-1))]}"
fi

# 1. Find the DRM card that owns the selected display output (e.g. /dev/dri/card1)
CARD_PATH=$(grep -l "^connected" /sys/class/drm/card*-${SELECTED}/status 2>/dev/null | head -n 1)
CARD_NAME=$(echo "$CARD_PATH" | grep -o 'card[0-9]*')
PRIMARY_DEV="/dev/dri/$CARD_NAME"

# 2. Get vendor and device IDs for --prefer-vk-device (e.g. 1002:7300 or 10de:25a0)
VENDOR_ID=$(cat /sys/class/drm/"$CARD_NAME"/device/vendor 2>/dev/null | sed 's/0x//')
DEVICE_ID=$(cat /sys/class/drm/"$CARD_NAME"/device/device 2>/dev/null | sed 's/0x//')
PCI_ID="${VENDOR_ID}:${DEVICE_ID}"

# 3. Build card priority list for wlroots (Primary GPU first, then fallback to others)
OTHER_DEVS=$(ls /dev/dri/card[0-9]* 2>/dev/null | grep -v "$PRIMARY_DEV" | paste -sd ":" -)
if [ -n "$OTHER_DEVS" ]; then
    EXPORT_DRM_DEVS="${PRIMARY_DEV}:${OTHER_DEVS}"
else
    EXPORT_DRM_DEVS="${PRIMARY_DEV}"
fi

echo "Selected Output: $SELECTED"
echo "Primary GPU Card: $PRIMARY_DEV"
echo "Vulkan PCI ID: $PCI_ID"

# 4. Launch Gamescope with wlroots GPU priority and Vulkan preference
WLR_DRM_DEVICES="$EXPORT_DRM_DEVS" gamescope \
  -W 1920 -H 1080 -r 144 \
  --adaptive-sync -e \
  -O "$SELECTED" \
  --prefer-vk-device "$PCI_ID" \
  -- steam
