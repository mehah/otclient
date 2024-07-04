-- @ Health/Mana
local function healthManaEvent()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    healthManaController.ui.health.text:setText(player:getHealth())
    healthManaController.ui.health.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.health.total:getWidth() * player:getHealth()) / player:getMaxHealth())))

    healthManaController.ui.mana.text:setText(player:getMana())
    healthManaController.ui.mana.current:setWidth(math.max(12, math.ceil(
        (healthManaController.ui.mana.total:getWidth() * player:getMana()) / player:getMaxMana())))
end

healthManaController = Controller:new()
healthManaController:setUI('healthinfo', modules.game_interface.getMainRightPanel())

function healthManaController:onInit()
end

function healthManaController:onTerminate()
end

function healthManaController:onGameStart()
    healthManaController:registerEvents(LocalPlayer, {
        onHealthChange = healthManaEvent,
        onManaChange = healthManaEvent
    }):execute()
end

-- @ End of Health/Mana
