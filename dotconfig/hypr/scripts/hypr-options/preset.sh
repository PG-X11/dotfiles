user_option=$(printf "preset-1\npreset-2\npreset-3\npreset-4\ndefault-preset" | rofi \
    -dmenu -p '' \
    -config '/home/a7med/Bookmarks/hypr/scripts/hypr-options/rofi/config.rasi'
)

if [[ "$user_option" == "preset-1" ]]; then
    cp ./presets/preset-1.conf ./current-preset.conf
elif [[ "$user_option" == "preset-2" ]]; then
    cp ./presets/preset-2.conf ./current-preset.conf
elif [[ "$user_option" == "preset-3" ]]; then
    cp ./presets/preset-3.conf ./current-preset.conf
elif [[ "$user_option" == "preset-4" ]]; then
    cp ./presets/preset-4.conf ./current-preset.conf
elif [[ "$user_option" == "default-preset" ]]; then
    cp ./presets/empty-preset.conf ./current-preset.conf
else
    notify-send "ERR - user did not input! " "did you esc?"
fi
