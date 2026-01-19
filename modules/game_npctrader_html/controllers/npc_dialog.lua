function onNpcChatWindow(data)
    local creature = g_map.getCreatureById(data.npcIds[1])
    if not creature then
        return
    end
    controllerNpcTrader.widthConsole = 395
    controllerNpcTrader.isTradeOpen = false
    controllerNpcTrader.creatureName = creature:getName() or "NPC"
    controllerNpcTrader.outfit = creature:getOutfit()
    controllerNpcTrader.buttons = data.buttons or {}
    if not controllerNpcTrader.ui or not controllerNpcTrader.ui:isVisible() then
        controllerNpcTrader:loadHtml('templates/game_npctrader.html')
    end
end
