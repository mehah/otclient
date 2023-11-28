setDefaultTab("Tools")
g_game.cancelAttackAndFollow()

local frags = 0
local unequip = false
local m = macro(50, "AntiRS & Msg", function() end)

function safeExit()
    CaveBot.setOff()
    TargetBot.setOff()
    g_game.cancelAttackAndFollow()
    g_game.cancelAttackAndFollow()
    g_game.cancelAttackAndFollow()
    modules.game_interface.forceExit()
end

onTextMessage(function(mode, text)
    if not m.isOn() then return end
    if not text:find("Warning! The murder of") then return end
    frags = frags + 1
    if killsToRs() < 6 or frags > 1 then
        EquipManager.setOff()
        schedule(100, function()
            local id = getLeft() and getLeft():getId()

            if id and not unequip then
                unequip = true
                g_game.equipItemId(id)
            end
            safeExit()
        end)
    end
end)