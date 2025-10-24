local wheel = dofile("wheel.lua")
local icons = dofile("icons.lua")
local bonus = dofile("bonus.lua")
local buttons = dofile("buttons.lua")
local nodes = dofile("nodes.lua")

local helper = {
    wheel = wheel,
    icons = icons,
    bonus = bonus,
    buttons = buttons,
    nodes = nodes,
}

return helper
