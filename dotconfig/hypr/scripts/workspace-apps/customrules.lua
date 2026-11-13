local browser = "librewolf"

-- Workspace 1
hl.window_rule({
    match = { class = "^(clock)$" },
    float = true,
    size = { 829, 451 },
    center = true,
})

-- Workspace 2
hl.window_rule({
    match = { class = "^(mainTerm)$" },
    float = true,
    workspace = "2",
    size = { 761, 538 },
    move = { 813, 337 },
})

hl.window_rule({
    match = { class = "^(pipesTerm)$" },
    float = true,
    workspace = "2",
    size = { 626, 478 },
    move = { 26, 64 },
})

-- Workspace 3
hl.window_rule({
    match = { class = "^(" .. browser .. ")$" },
    workspace = "3",
})

-- Workspace 4
hl.window_rule({
    match = { class = "^(QMPlay2)$" },
    float = true,
    workspace = "4",
    size = { 674, 499 },
    move = { 15, 56 },
})

hl.window_rule({
    match = { class = "^(cavaTerm)$" },
    float = true,
    workspace = "4",
    size = { 673, 290 },
    move = { 18, 575 },
})

hl.window_rule({
    match = { class = "^(rangerTerm)$" },
    float = true,
    workspace = "4",
    size = { 856, 812 },
    move = { 729, 59 },
})
