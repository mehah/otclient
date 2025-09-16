GameAnalyzer = {}

Analyzers = {
    GameExpAnalyzer = {
        name = "Experience",
        toggle = GameExpAnalyzerToggle,
    },
}

contentPanel = nil
analyzerButton = nil
analyzerWindow = nil
expAnalyzerWindow = nil
expStart = nil
expHourStart = 0
expTimeElapsed = 0

function GameAnalyzer.init()
    --print("Init Game Analyzer")
    analyzerButton = modules.game_mainpanel.addToggleButton('analyzerButton', 
                                                            tr('Open analytics selector window'),
                                                            '/images/options/analyzers',
                                                            GameAnalyzer.toggle)

    analyzerButton:setOn(false)
    analyzerWindow = g_ui.loadUI('game_analyzer')
    analyzerWindow:setup()
    setupAnalyzerWindowResize()
    
    -- Hide toggleFilterButton and adjust contextMenuButton anchors
    local toggleFilterButton = analyzerWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    local contextMenuButton = analyzerWindow:recursiveGetChildById('contextMenuButton')
    local minimizeButton = analyzerWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        contextMenuButton:breakAnchors()
        contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        contextMenuButton:setMarginRight(7)
        contextMenuButton:setMarginTop(0)
    end
    
    -- Adjust lockButton anchors to be at the left of contextMenuButton
    local lockButton = analyzerWindow:recursiveGetChildById('lockButton')
    if lockButton and contextMenuButton then
        lockButton:breakAnchors()
        lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
        lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
        lockButton:setMarginRight(2)
        lockButton:setMarginTop(0)
    end
    
    -- Hide newWindowButton
    local newWindowButton = analyzerWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end
    
    expAnalyzerInit()
    
    loadContentPanel()

    connect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = refresh
    })
    
    -- Add an onClose handler to update all analyzer buttons
    analyzerWindow.onClose = function()
        local buttons = analyzerWindow:getChildren()
        for _, button in pairs(buttons) do
            if button:getId():find("AnalyzerButton") then
                button:setChecked(false)
                button:setOn(false)
            end
        end
    end
    
    refresh()
end

function expAnalyzerInit()
    expAnalyzerWindow = g_ui.loadUI('game_exp_analyzer')
    expAnalyzerWindow:setup()
    setupExpAnalyzerWindowResize()

    -- Hide toggleFilterButton and adjust contextMenuButton anchors
    local toggleFilterButton = expAnalyzerWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    local contextMenuButton = expAnalyzerWindow:recursiveGetChildById('contextMenuButton')
    local minimizeButton = expAnalyzerWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        contextMenuButton:breakAnchors()
        contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        contextMenuButton:setMarginRight(7)
        contextMenuButton:setMarginTop(0)
    end
    
    -- Adjust lockButton anchors to be at the left of contextMenuButton
    local lockButton = expAnalyzerWindow:recursiveGetChildById('lockButton')
    if lockButton and contextMenuButton then
        lockButton:breakAnchors()
        lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
        lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
        lockButton:setMarginRight(2)
        lockButton:setMarginTop(0)
    end
    
    -- Hide newWindowButton
    local newWindowButton = expAnalyzerWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end

    -- Add onOpen handler to ensure button stays in active state
    expAnalyzerWindow.onOpen = function()
        local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
        if button then
            button:setChecked(true)
            button:setOn(true)
        end
    end

    -- Add onClose handler to update button state
    expAnalyzerWindow.onClose = function()
        local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
        if button then
            button:setChecked(false)
            button:setOn(false)
        end
    end

    expHourStart = g_clock.seconds()
    
    local expGainValue = expAnalyzerWindow:recursiveGetChildById('expGainValue')
    if expGainValue then
        expGainValue:setText(0)
    end

    local expHourValue = expAnalyzerWindow:recursiveGetChildById('expHourValue')
    if expHourValue then
        expHourValue:setText(0)
    end
end

function expAnalyzerTerminate()
    -- Update button state before destroying window
    local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
    if button then
        button:setChecked(false)
        button:setOn(false)
    end
    
    expAnalyzerWindow:destroy()
    expStart = nil
    expHourStart = nil
    expTimeElapsed = 0
end

function GameAnalyzer.terminate()
    analyzerButton:destroy()
    analyzerWindow:destroy()
    expAnalyzerTerminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = refresh
    })

    GameAnalyzer = nil
end

function onMiniWindowOpen()
    analyzerButton:setOn(true)
    
    -- Check all analyzer windows and update their buttons
    if expAnalyzerWindow and expAnalyzerWindow:isVisible() then
        local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
        if button then
            button:setChecked(true)
            button:setOn(true)
        end
    end
    
    -- Add similar checks for other analyzer windows as they are implemented
end

function onMiniWindowClose()
    analyzerButton:setOn(false)
end

function loadContentPanel()
    contentPanel = modules.game_interface.findContentPanelAvailable(analyzerWindow, analyzerWindow:getMinimumHeight())
    if not contentPanel then
        --print("No content panel available")
        return
    end
end

function GameAnalyzer.toggle()
    if analyzerButton:isOn() then
        analyzerWindow:close()
        analyzerWindow:setOn(false)
    else
        if not analyzerWindow:getParent() then
            contentPanel:addChild(analyzerWindow)
        end
        analyzerWindow:open()
        analyzerButton:setOn(true)
    end
end

function online()
    analyzerButton:show()
    refresh()
    expStart = nil
    expHourStart = 0
    expTimeElapsed = 0
end

function offline()
    analyzerButton:hide()
    analyzerWindow:setParent(nil, true)
    expStart = nil
    expHourStart = 0
    expTimeElapsed = 0
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if expStart == nil then
        expStart = player:getExperience()
    end

    onExperienceChange(player, player:getExperience())
    
    -- Update all button states based on window visibility
    -- XP Analyzer
    if expAnalyzerWindow and expAnalyzerWindow:isVisible() then
        local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
        if button then
            button:setChecked(true)
            button:setOn(true)
        end
    end
    
    -- As other analyzers are implemented, add their button state checks here
end

function toggleAnalyzer(analyzer)
    -- Toggle checked state
    local newState = not analyzer:isChecked()
    analyzer:setChecked(newState)
    
    -- Make sure setOn is also toggled the same way
    analyzer:setOn(newState)
    
    toggleFromAnalyzer(analyzer)
end

function toggleFromAnalyzer(analyzer)
    local analyzerType = getFirstWordBeforeCapital(analyzer:getId())
    analyzerType = 'Game' .. analyzerType .. 'Analyzer'

    local analyzerConfig = Analyzers[analyzerType]
    if analyzerConfig and analyzerConfig.toggle then
        analyzerConfig.toggle(analyzer)
    else
       --print("Toggle function for " .. analyzerType .. " not found")
    end
end

function GameExpAnalyzerToggle(analyzer)
    if analyzer:isChecked() then
        if not expAnalyzerWindow:getParent() then
            contentPanel:addChild(expAnalyzerWindow)
        end
        
        -- Ensure the button stays in active state
        analyzer:setOn(true)
        analyzer:setChecked(true)
        
        -- Open the window after setting button state
        expAnalyzerWindow:open()
    else
        -- Ensure the button is in inactive state
        analyzer:setOn(false)
        analyzer:setChecked(false)
        
        -- Close the window after setting button state
        expAnalyzerWindow:close()
    end
end

function onExperienceChange(player, exp, oldExp)
    if expAnalyzerWindow then
        local expGainValue = expAnalyzerWindow:recursiveGetChildById('expGainValue')
        if expGainValue then
            if expStart == nil then
                expStart = exp
            end
            expGainValue:setText(exp - expStart)
        end

        local expHourValue = expAnalyzerWindow:recursiveGetChildById('expHourValue')
        if expHourValue then
            if expHourStart == 0 then
                expHourStart = g_clock.seconds()
            end
            
            local timeElapsed = g_clock.seconds() - expHourStart
            expHourValue:setText(calculateExpPerHour(exp, expStart, timeElapsed, expHourStart))
        end
    end
end

function calculateExpPerHour(exp, expStart, timeElapsed, expHourStart)
    local expGained = exp - expStart
    
    -- Ensure we don't divide by zero
    if timeElapsed <= 0 then
        return "0"
    end
    
    local expPerHour = math.floor((expGained / timeElapsed) * 3600)
    --print("Exp Per Hour: " .. expPerHour)
    
    -- Handle negative values properly
    if expPerHour < 0 then
        return "-" .. comma_value(math.abs(expPerHour))
    else
        return comma_value(expPerHour)
    end
end

function getFirstWordBeforeCapital(str)
    local firstWord = str:match("^[^A-Z]*")
    if firstWord then
        firstWord = firstWord:sub(1, 1):upper() .. firstWord:sub(2)
    end
    return firstWord
end

-- Function to create toggle handlers for future analyzers
function createAnalyzerToggleFunction(analyzerName, analyzerWindow)
    return function(analyzer)
        if analyzer:isChecked() then
            if not analyzerWindow:getParent() then
                contentPanel:addChild(analyzerWindow)
            end
            analyzerWindow:open()
            
            -- Ensure button stays in active state
            analyzer:setOn(true)
            analyzer:setChecked(true)
        else
            analyzerWindow:close()
            
            -- Ensure button is in inactive state
            analyzer:setOn(false)
            analyzer:setChecked(false)
        end
    end
end

-- Format numbers with commas
function comma_value(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Resize control functions
function setupAnalyzerWindowResize()
    -- Define resize restriction function
    local function restrictResize()
        analyzerWindow.onResize = function()
            local minHeight = 80 -- Minimum window height
            local maxHeight = 250 -- Maximum window height
            
            if analyzerWindow:getHeight() < minHeight then
                analyzerWindow:setHeight(minHeight)
            elseif analyzerWindow:getHeight() > maxHeight then
                analyzerWindow:setHeight(maxHeight)
            end
        end
    end
    restrictResize()

    -- Remove resize restriction on minimize, restore on maximize
    analyzerWindow.onMinimize = function()
        analyzerWindow.onResize = nil
    end

    analyzerWindow.onMaximize = function()
        restrictResize()
    end
end

function setupExpAnalyzerWindowResize()
    -- Define resize restriction function
    local function restrictResize()
        expAnalyzerWindow.onResize = function()
            local minHeight = 80 -- Minimum window height
            if expAnalyzerWindow:getHeight() < minHeight then
                expAnalyzerWindow:setHeight(minHeight)
            end
        end
    end
    restrictResize()

    -- Remove resize restriction on minimize, restore on maximize
    expAnalyzerWindow.onMinimize = function()
        expAnalyzerWindow.onResize = nil
    end

    expAnalyzerWindow.onMaximize = function()
        restrictResize()
    end
end