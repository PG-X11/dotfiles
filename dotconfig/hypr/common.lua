-- Variables
-- todo - rewrite and configure for best, different presets too  eg.. glass, box, normal, no blur, no transparency, bash shell script controller
-- random settings

-- Load pywal generated colors via require() so Hyprland's file watcher auto-reloads when wal updates it
local wal_path = os.getenv("HOME") .. "/.cache/wal/colors-hyprland"
package.loaded[wal_path] = nil
local ok, wal = pcall(require, wal_path)
if not ok or type(wal) ~= "table" then
    wal = {}
end

local c_bg = wal.background or _G.background or "rgb(2b3339)"
local c1 = wal.color1 or _G.color1 or "rgb(a6b465)"
local c2 = wal.color2 or _G.color2 or "rgb(869759)"

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    input = {
        sensitivity = 0.7,
        force_no_accel = true,
        repeat_delay = 333,
        repeat_rate = 50,
        accel_profile = "flat",
        focus_on_close = 0,
    },

    general = {
        allow_tearing = true,
        gaps_in = 7,
        gaps_out = 18,
        -- Borders
        col = {
            active_border = { colors = { c1, c1, c2 }, angle = 45 },
            inactive_border = c_bg,
        },
        border_size = 3,
        resize_on_border = true,
        layout = "scrolling",
    },

    -- Scrolling layout config
    scrolling = {
        focus_fit_method = 1,
        follow_focus = 1, -- 0: don't move, 1: move on focus/click, 2: move on focus
        wrap_focus = true,
        fullscreen_on_one_column = true,
        follow_min_visible = 0.1,
    },

    -- Decoration Styles
    decoration = {
        border_part_of_window = false,
        rounding = 20,
        active_opacity = 1.0,
        inactive_opacity = 0.8, -- 0.92
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            ignore_opacity = true, -- keep true so app/terminal background transparency blurs properly
            new_optimizations = true,
            xray = false,
            noise = 0.1,
            contrast = 2.0,
            brightness = 1.0,
            vibrancy = 0.2, -- 0.57 limits vibrancy to [0.0 - 1.0]
            vibrancy_darkness = 0.2,
        },

        shadow = {
            enabled = false,
            range = 12,
            render_power = 3,
        },
    },

    -- Miscellaneous Options
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        -- variable refresh rate
        -- vrr = 1,
    },

    -- figured this out after a while
    -- using this :
    render = {
        direct_scanout = 1, -- 0: disabled, 1: enabled, 2: auto
        non_shader_cm = 0,
    }, -- will make full screen apps not get rules from the compositor, which fixes most games and tf2 for sure

    cursor = {
        no_hardware_cursors = 1, -- 0: use hw cursors, 1: disable, 2: auto
        no_break_fs_vrr = 1,     -- 0: disabled, 1: enabled, 2: auto
        sync_gsettings_theme = true,
        min_refresh_rate = 100,
        warp_on_change_workspace = 1,
        use_cpu_buffer = 1,
    },
})

-- tablets
-- xp pen deco 3
hl.device({
    name = "xp-pen-deco-03",
    -- output = "eDP-1",
})
