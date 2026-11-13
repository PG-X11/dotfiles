-- Monitors
-- 1. Laptop Screen
hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1.2,
    bitdepth = 10,
    vrr = 0,
})

-- 2. LG UltraGear (120Hz)
-- hl.monitor({
--     output = "HDMI-A-1",
--     mode = "1920x1080@119.98",
--     position = "1600x0",
--     scale = 1.2,
--     bitdepth = 10,
--     vrr = 2,
-- })

-- LG UltraGear (144Hz OC)
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@143.98",
    position = "1600x0",
    scale = 1.2,
    bitdepth = 10,
    vrr = 2,
})

---- Workspaces
local lgm = "desc:LG Electronics LG ULTRAGEAR 0x0009F446"
hl.workspace_rule({ workspace = "1", monitor = lgm, persistent = true, default = true })
hl.workspace_rule({ workspace = "2", monitor = lgm, persistent = true, default = true })
hl.workspace_rule({ workspace = "3", monitor = lgm, persistent = true, default = true })
hl.workspace_rule({ workspace = "4", monitor = lgm, persistent = true, default = true })
hl.workspace_rule({ workspace = "5", monitor = lgm, persistent = true, default = true })

local edp = "desc:AU Optronics 0x60ED"
hl.workspace_rule({ workspace = "6", monitor = edp, persistent = true, default = true })
hl.workspace_rule({ workspace = "7", monitor = edp, persistent = true, default = true })
hl.workspace_rule({ workspace = "8", monitor = edp, persistent = true, default = true })
hl.workspace_rule({ workspace = "9", monitor = edp, persistent = true, default = true })
-- hl.workspace_rule({ workspace = "10", monitor = edp, persistent = true })
