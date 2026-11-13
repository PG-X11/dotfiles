-- window rules
-- steam no border
hl.window_rule({
    match = { class = "^(steam.*)$" },
    border_size = 0,
})

-- quick shell override full screen issue
-- hl.layer_rule({ match = { namespace = "quickshell" }, ignore_alpha = 0 }) -- fix later

-- Transparency
-- hl.window_rule({ match = { class = "^(firefox)$" }, opacity = "0.9 override 0.9 override" })
-- hl.window_rule({ match = { class = "^(org.kde.kate)$" }, opacity = "0.9 override 0.9 override" })

-- full screen strip from compositor
-- Use fullscreen_state_client = 2 (true client fullscreen) instead of fullscreen = true.
-- With scrolling.fullscreen_on_one_column = true, fullscreen = true matches any single window on a workspace
-- and strips its transparency (force_rgbx), blur (no_blur), and animations (no_anim) until you drag/move it.
hl.window_rule({
    match = { fullscreen_state_client = 2 },
    immediate = true,
    no_blur = true,
    no_shadow = true,
})

hl.window_rule({
    match = { class = "^(tf_linux64)$" },
    immediate = true,
})

hl.window_rule({
    match = { class = "^(steam_app_.*)$" },
    immediate = true,
})
