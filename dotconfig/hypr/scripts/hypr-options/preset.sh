#!/bin/bash
work_dir=(/home/$USER/.config/hypr/scripts/hypr-options)
user_option=$(printf "preset-1\npreset-2\npreset-3\npreset-4\ndefault-preset" | rofi \
    -dmenu -p '' \
    -config '/home/a7med/Bookmarks/hypr/scripts/hypr-options/rofi/config.rasi'
)

if [[ "$user_option" == "preset-1" ]]; then
    ln -sfn $work_dir/presets/preset-1.lua $work_dir/current-preset.lua
elif [[ "$user_option" == "preset-2" ]]; then
    ln -sfn $work_dir/presets/preset-2.lua $work_dir/current-preset.lua
elif [[ "$user_option" == "preset-3" ]]; then
    ln -sfn $work_dir/presets/preset-3.lua $work_dir/current-preset.lua
elif [[ "$user_option" == "preset-4" ]]; then
    ln -sfn $work_dir/presets/preset-4.lua $work_dir/current-preset.lua
elif [[ "$user_option" == "default-preset" ]]; then
    cp $work_dir/presets/empty-preset.lua $work_dir/current-preset.lua
else
    echo "user aborted "
    # notify-send "ERR - user did not input! " "did you esc?"
fi

hyprctl reload
