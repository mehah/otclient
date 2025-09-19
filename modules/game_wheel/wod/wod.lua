WheelOfDestiny = {}  
  
function WheelOfDestiny.show(container)  
    local wodUI = g_ui.loadUI('wod', container)  
    if wodUI then  
        wodUI:fill('parent')  
        WheelOfDestiny.setupVocationOverlay(wodUI)  
        WheelOfDestiny.setupLargeBonusOverlays(wodUI, true) -- ou baseado em alguma condição  
    end  
end 
  
function WheelOfDestiny.setupVocationOverlay(ui)  
    local player = g_game.getLocalPlayer()  
    if not player then  
        return  
    end  
      
    local vocation = player:getVocation()  
    local overlayImage = WheelOfDestiny.getVocationOverlayImage(vocation)  
      
    if overlayImage then  
        local overlay = ui:getChildById('vocationOverlay')  
        if overlay then  
            overlay:setImageSource(overlayImage)  
            overlay:setVisible(true)  
        end  
    end  
end  
  
function WheelOfDestiny.getVocationOverlayImage(vocation)  
    local vocationImages = {  
        -- Apenas vocações promovidas  
        [11] = '/images/game/wheel/wod/backdrop_skillwheel_front_knight',  -- Elite Knight  
        [12] = '/images/game/wheel/wod/backdrop_skillwheel_front_paladin', -- Royal Paladin  
        [13] = '/images/game/wheel/wod/backdrop_skillwheel_front_sorc',    -- Master Sorcerer  
        [14] = '/images/game/wheel/wod/backdrop_skillwheel_front_druid',   -- Elder Druid  
    }  
      
    -- Exalted Monk só aparece se protocolo > 1500  
    local clientVersion = g_game.getClientVersion()  
    if clientVersion > 1500 then  
        vocationImages[15] = '/images/game/wheel/wod/backdrop_skillwheel_front_monk'  -- Exalted Monk  
    end  
      
    return vocationImages[vocation]  
end

function WheelOfDestiny.setupLargeBonusOverlays(ui, showBonuses)  
    local bonusWidgets = {'largeBonusTL', 'largeBonusTR', 'largeBonusBL', 'largeBonusBR'}  
      
    for _, widgetId in ipairs(bonusWidgets) do  
        local widget = ui:getChildById(widgetId)  
        if widget then  
            widget:setVisible(showBonuses or false)  
        end  
    end  
end

function WheelOfDestiny.setupDataWindows(ui)  
    local windowTitles = {  
        leftWindow1 = "Selection",  
        leftWindow2 = "Information",   
        rightWindow1 = "Dedication Perks",  
        rightWindow2 = "Conviction Perks",  
        rightWindow3 = "Vessels",  
        rightWindow4 = "Revelation Perks"  
    }  
      
    for windowId, title in pairs(windowTitles) do  
        local window = ui:getChildById(windowId)  
        if window then  
            local titleLabel = window:getChildById(windowId:gsub("Window", "Title"))  
            if titleLabel then  
                titleLabel:setText(title)  
            end  
            window:setVisible(true)  
        end  
    end  
end

