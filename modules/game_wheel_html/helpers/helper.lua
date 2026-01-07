local wheel = dofile("wheel.lua")
local bonus = dofile("bonus.lua")
local buttons = dofile("buttons.lua")
local nodes = dofile("nodes.lua")
local gems = dofile("gems.lua")

local helper = {
    wheel = wheel,
    bonus = bonus,
    gems = gems,
    buttons = buttons,
    nodes = nodes,
}

return helper
