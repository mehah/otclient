modules.game_interface.gameRootPanel.onMouseRelease = function(widget, mousePos, mouseButton)
    if mouseButton == 2 then
        local child = rootWidget:recursiveGetChildByPos(mousePos)
        if child == widget then
            local menu = g_ui.createWidget('PopupMenu')
            menu:setId("blzMenu")
            menu:setGameMenu(true)
            menu:addOption('AttackBot', AttackBot.show, "OTCv8")
            menu:addOption('HealBot', HealBot.show, "OTCv8")
            menu:addOption('Conditions', Conditions.show, "OTCv8")
            menu:addSeparator()
            menu:addOption('CaveBot', function() 
                if CaveBot.isOn() then 
                    CaveBot.setOff() 
                else 
                    CaveBot.setOn() 
                end 
            end, CaveBot.isOn() and "ON " or "OFF ")
            menu:addOption('TargetBot', function() 
                if TargetBot.isOn() then 
                    TargetBot.setOff() 
                else 
                    TargetBot.setOn() 
                end 
            end, TargetBot.isOn() and "ON " or "OFF ")
            menu:display(mousePos)
            return true
        end
    end
end