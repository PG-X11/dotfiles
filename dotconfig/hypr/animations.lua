-- todo - different modes of animation
hl.config({
    animations = {
        enabled = true,
    },
})

-- Smooth, predictable acceleration curves (No bouncy overshoot)
hl.curve("fluent", {
    type = "bezier",
    points = { { 0.25, 1 }, { 0.3, 1 } },
})
hl.curve("linear", {
    type = "bezier",
    points = { { 0, 0 }, { 1, 1 } },
})

-- Root animation leaf so child leaves inherit a consistent baseline
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "fluent" })

-- Borders (Clean, steady visibility)
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "fluent" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 15, bezier = "linear", style = "loop" })

-- Windows (Crisp open and close, perfectly paced)
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "fluent", style = "popin 92%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "fluent", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "fluent", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, bezier = "fluent" })

-- Fade (Smooth transitions without feeling muddy)
hl.animation({ leaf = "fade", enabled = true, speed = 3.5, bezier = "fluent" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3.5, bezier = "fluent" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3.5, bezier = "fluent" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "fluent" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "linear" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "fluent" })

-- Workspaces (Fluid vertical tracking, faster speed to cut delay)
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "fluent", style = "slidevert" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 3, bezier = "fluent", style = "slidevert" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "fluent", style = "slidevert" })

-- Layers / UI Shell (Polished panels and menus)
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "fluent", style = "popin 93%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "fluent", style = "popin 93%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3.5, bezier = "fluent", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 4, bezier = "fluent" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3.5, bezier = "fluent" })
