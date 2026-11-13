-- Plugins (loaded before modules that bind plugin actions)
-- pcall(hl.plugin.load, "/usr/lib/gloview.so")

---- sourcing files for organization
require("./common")
require("./keybinds")
require("./env")
require("./windowrules")
require("./animations")
require("./monitors")
pcall(require, "./colors/colors")
pcall(require, "./scripts/workspace-apps/customrules")
pcall(require, "./scripts/artapps/artapps")
pcall(require, "./scripts/hypr-options/current-preset")

---- auto starts
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("xrandr --output eDP-1 --primary")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    -- hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace-apps/layout1.sh") -- FOR NOW THIS IS NOT WORKING
    -- hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace-apps/layout2.sh") -- FOR NOW THIS IS NOT WORKING
    -- hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace-apps/layout3.sh") -- FOR NOW THIS IS NOT WORKING
    -- hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace-apps/layout4.sh") -- FOR NOW THIS IS NOT WORKING

    ---- Clip board
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- keyboard layouts
    hl.exec_cmd("fcitx5")

    -- bar
    hl.exec_cmd("noctalia")

    -- wayscriber
    hl.exec_cmd("wayscriber -d")
end)
