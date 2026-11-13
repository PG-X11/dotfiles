---- variabls
local home = os.getenv("HOME")
local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"
local altFileManager = "kitty -e ranger"
-- local menu = "rofi -show drun"
local menu = "noctalia msg panel-toggle launcher"
local browser = "librewolf"
local mediaplayer = "QMPlay2"

---- edit keybinds here , duh
---- basic hyprland controls
-- Switch workspaces with mainMod + [0-9]
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = "1" }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = "2" }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = "3" }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = "4" }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = "5" }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = "6" }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = "7" }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = "8" }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = "9" }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = "2" }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = "3" }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = "4" }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = "5" }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = "6" }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = "7" }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = "8" }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = "9" }))

-- Move focus with $mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- alongside basic movement
hl.bind(mainMod .. " + CTRL + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + W", hl.dsp.window.float())

-- Resize active window with $mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Move window with Super + Left Click
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Resize window with Super + Right Click
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Changing workspace using arrows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "+1" }))

---- launching and quitting apps
-- essentials
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Delete", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(altFileManager))
hl.bind("SHIFT + F11", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(mediaplayer))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(home .. "/.local/bin/artapps"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(home .. "/.local/bin/gamemode-controller"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("rofi -show window"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("kate " .. home .. "/.config/hypr"))
hl.bind(mainMod .. " + R", function()
    hl.dispatch(hl.dsp.reload_config())
    hl.exec_cmd("noctalia msg config-reload")
end)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
-- theme changer and wallpaper changer
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(home .. "/.local/bin/wallchanger"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(home .. "/.local/bin/themeswitcher"))

-- preset changer
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd(home .. "/.local/bin/preset-switcher"))

-- screen shots
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(home .. "/.local/bin/screenshot | wl-copy"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd(home .. "/.local/bin/monitorscrshot | wl-copy"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(home .. "/.local/bin/colorpicker"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("wayscriber --daemon-toggle"))

-- clipboard history with wl clip and cliphist
-- hl.bind(mainMod .. " + V", hl.dsp.exec_cmd([[cliphist list | grep -v "file://" | rofi -dmenu -display-columns 2 -p "Clipboard" -config ]] .. home .. [[/dotfiles/scripts/clipboard/config.rasi | cliphist decode | wl-copy]]))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd([[cliphist wipe && noctalia msg clipboard-clear && notify-send "clipboard wiped!"]]))

-- noctalia shell toggle
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd([[bash -c 'pgrep noctalia >/dev/null && pkill noctalia || noctalia &']]))

-- Workspace app launchers
hl.bind("ALT + 1", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace-apps/layout1.sh"))
hl.bind("ALT + 2", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace-apps/layout2.sh"))
hl.bind("ALT + 3", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace-apps/layout3.sh"))
hl.bind("ALT + 4", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/workspace-apps/layout4.sh"))

---- Plugins
-- Gloview
-- hl.bind(mainMod .. " + TAB", function() if hl.plugin and hl.plugin.gloview then hl.plugin.gloview.desktop() end end)
hl.bind(mainMod .. " + SHIFT + TAB", function()
    if hl.plugin and hl.plugin.gloview then
        hl.plugin.gloview.toggle()
    end
end)
-- hl.bind(mainMod .. " + CTRL + TAB", function() if hl.plugin and hl.plugin.gloview then hl.plugin.gloview.allworkspaces() end end)

---- Audio and media control
-- audio down up
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
--- added noctalia mic control
hl.bind("SHIFT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg mic-volume-up 5"), { locked = true })
hl.bind("SHIFT + XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg mic-volume-down 5"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
-- hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(""), { repeating = true, locked = true })
-- Requires playerctl

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })

-- mute mic
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind(mainMod .. " + CTRL + X", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

---- brightness controls
--
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("ALT + F12", hl.dsp.exec_cmd("brightnessctl set 100%")) -- max brightness
hl.bind("ALT + F11", hl.dsp.exec_cmd("brightnessctl set 1%")) -- min brightness


---- layout control
-- scrolling
hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("move +col"))

---- environment switcher script
hl.bind(mainMod .. " + SHIFT + Delete", hl.dsp.exec_cmd("bash " .. home .. "/dotfiles/scripts/envswitcher/envswitcher.sh"))
