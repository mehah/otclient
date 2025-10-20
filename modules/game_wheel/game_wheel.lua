dofile('wod/wod')  
dofile('gem/gem')  
dofile('frag/frag')  
  
Wheel = {}  
  
local wheelButton = nil  
local contentContainer = nil  
local previousType = nil  
local windowTypes = {}  
local tabStack = {}  
  
-- Tabs do Wheel of Destiny  
local wheelOfDestiny = nil  
local gemAtelier = nil  
local fragmentWorkshop = nil  
  
function toggle()  
    if not controllerWheel.ui then  
        return  
    end  
      
    -- Verificações de acesso  
    local player = g_game.getLocalPlayer()  
    if not player then  
        return  
    end  
      
    local level = player:getLevel()  
    local vocation = player:getVocation()  
    local isPremium = player:isPremium()  
      
    -- Verificar todas as condições de uma vez  
    local promotedVocations = {11, 12, 13, 14, 15}  
    local isPromoted = false  
    for _, promotedId in ipairs(promotedVocations) do  
        if vocation == promotedId then  
            isPromoted = true  
            break  
        end  
    end  
      
    -- Se qualquer verificação falhar, mostrar error box  
    if level <= 51 or not isPromoted or not isPremium then  
        displayErrorBox(tr('Info'), 'To be able to use the Wheel of Destiny, a character must be at least level 51, be promoted and have active Premium Time.')  
        return  
    end  
      
    -- Se passou em todas as verificações, abrir o módulo  
    if controllerWheel.ui:isVisible() then  
        return hide()  
    end  
    show("wheelOfDestiny")  
end
  
controllerWheel = Controller:new()  
controllerWheel:setUI('game_wheel')  
  
function controllerWheel:onInit()  
end  
  
function controllerWheel:onGameStart()  
    if g_game.getClientVersion() >= 1310 then  
        wheelButton = modules.game_mainpanel.addToggleButton('WheelButton', tr('Wheel of Destiny'),  
            '/images/options/wheel', function() toggle() end, false, 8)  
        wheelButton:setOn(false)  
  
        contentContainer = controllerWheel.ui:recursiveGetChildById('contentContainer')  
        local buttonContainer = controllerWheel.ui:recursiveGetChildById('buttonContainer')  
        wheelOfDestiny = buttonContainer:recursiveGetChildById('wheelOfDestiny')  
        gemAtelier = buttonContainer:recursiveGetChildById('gemAtelier')  
        fragmentWorkshop = buttonContainer:recursiveGetChildById('fragmentWorkshop')  
  
        windowTypes = {  
            wheelOfDestiny = { obj = wheelOfDestiny, func = showWheelOfDestiny },  
            gemAtelier = { obj = gemAtelier, func = showGemAtelier },  
            fragmentWorkshop = { obj = fragmentWorkshop, func = showFragmentWorkshop }  
        }  
    end  
end  
  
function controllerWheel:onGameEnd()  
    hide()  
end  
  
function controllerWheel:onTerminate()  
    if wheelButton then  
        wheelButton:destroy()  
        wheelButton = nil  
    end  
end  
  
function hide()  
    if not controllerWheel.ui then  
        return  
    end  
    resetWheelTabs()  
    controllerWheel.ui:hide()  
end  
  
function resetWheelTabs()  
    tabStack = {}  
    if controllerWheel.ui.BackButton then  
        controllerWheel.ui.BackButton:setEnabled(false)  
    end  
    if previousType then  
        local previousWindow = windowTypes[previousType]  
        if previousWindow and previousWindow.obj then  
            previousWindow.obj:enable()  
            previousWindow.obj:setOn(false)  
        end  
        previousType = nil  
    end  
end  
  
function show(defaultWindow)  
    if not controllerWheel.ui or not wheelButton then  
        return  
    end  
  
    controllerWheel.ui:show()  
    controllerWheel.ui:raise()  
    controllerWheel.ui:focus()  
    SelectWindow(defaultWindow, false)  
end  
  
function toggleBack()  
    local previousTab = table.remove(tabStack, #tabStack)  
    if #tabStack < 1 then  
        controllerWheel.ui.BackButton:setEnabled(false)  
    end  
    SelectWindow(previousTab, true)  
end  
  
function SelectWindow(type, isBackButtonPress)  
    if previousType then  
        local previousWindow = windowTypes[previousType]  
        if previousWindow and previousWindow.obj then  
            previousWindow.obj:enable()  
            previousWindow.obj:setOn(false)  
        end  
        if not isBackButtonPress then  
            table.insert(tabStack, previousType)  
            if controllerWheel.ui.BackButton then  
                controllerWheel.ui.BackButton:setEnabled(true)  
            end  
        end  
    end  
          
    if contentContainer then  
        contentContainer:destroyChildren()  
    end  
  
    local window = windowTypes[type]  
    if window then  
        if window.obj then  
            window.obj:setOn(true)  
            window.obj:disable()  
        end  
        previousType = type  
        if window.func then  
            window.func(contentContainer)  
        end  
    end  
end  
  
-- Funções para cada tab (agora carregam os módulos específicos)  
function showWheelOfDestiny(container)  
    if WheelOfDestiny and WheelOfDestiny.show then  
        WheelOfDestiny.show(container)  
    end  

    WheelOfDestiny.updateSlicesProgress("TopLeft", {
        [1] = { value = 40, total = 50 },
        [2] = { value = 0, total = 75 },
        [3] = { value = 75, total = 75 },
        [4] = { value = 80, total = 100 },
        [5] = { value = 100, total = 100 },
        [6] = { value = 0, total = 100 },
        [7] = { value = 80, total = 150 },
        [8] = { value = 0, total = 150 },
        [9] = { value = 200, total = 200 },
    })
    WheelOfDestiny.updateSlicesProgress("BottomLeft", {
        [1] = { value = 40, total = 50 },
        [2] = { value = 0, total = 75 },
        [3] = { value = 75, total = 75 },
        [4] = { value = 80, total = 100 },
        [5] = { value = 100, total = 100 },
        [6] = { value = 0, total = 100 },
        [7] = { value = 80, total = 150 },
        [8] = { value = 0, total = 150 },
        [9] = { value = 200, total = 200 },
    })
    WheelOfDestiny.updateSlicesProgress("BottomRight", {
        [1] = { value = 40, total = 50 },
        [2] = { value = 0, total = 75 },
        [3] = { value = 75, total = 75 },
        [4] = { value = 80, total = 100 },
        [5] = { value = 100, total = 100 },
        [6] = { value = 0, total = 100 },
        [7] = { value = 80, total = 150 },
        [8] = { value = 0, total = 150 },
        [9] = { value = 200, total = 200 },
    })
    WheelOfDestiny.updateSlicesProgress("TopRight", {
        [1] = { value = 40, total = 50 },
        [2] = { value = 25, total = 75 },
        [3] = { value = 75, total = 75 },
        [4] = { value = 80, total = 100 },
        [5] = { value = 100, total = 100 },
        [6] = { value = 15, total = 100 },
        [7] = { value = 80, total = 150 },
        [8] = { value = 120, total = 150 },
        [9] = { value = 200, total = 200 },
    })
end  
  
function showGemAtelier(container)  
    if GemAtelier and GemAtelier.show then  
        GemAtelier.show(container)  
    end  
end  
  
function showFragmentWorkshop(container)  
    if FragmentWorkshop and FragmentWorkshop.show then  
        FragmentWorkshop.show(container)  
    end  
end