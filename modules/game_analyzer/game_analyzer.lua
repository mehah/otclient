GameAnalyzer = {}

-- Import ExperienceRate constants
ExperienceRate = {
    BASE = 0,
    VOUCHER = 1,
    LOW_LEVEL = 2,
    XP_BOOST = 3,
    STAMINA_MULTIPLIER = 4
}

Analyzers = {
    GameExpAnalyzer = {
        name = "Experience",
        toggle = GameExpAnalyzerToggle,
    },
}

local ExpRating = {}
contentPanel = nil
analyzerButton = nil
analyzerWindow = nil
expAnalyzerWindow = nil
expStart = nil       -- Track experience when window opens
rawExpTotal = 0      -- Track total raw experience gained
expHourStart = 0     -- Track when we started measuring

-- Create a global alias for the function
function updateExperienceRate(localPlayer)
    return GameAnalyzer.updateExperienceRate(localPlayer)
end

-- Create global aliases for other functions that might be called
function calculateRawExperience(modifiedExp, expRateTotal)
    return GameAnalyzer.calculateRawExperience(modifiedExp, expRateTotal)
end

function calculateRawExpPerHour(rawExpGained, timeElapsed)
    return GameAnalyzer.calculateRawExpPerHour(rawExpGained, timeElapsed)
end

function calculateExpPerHour(expGained, timeElapsed)
    return GameAnalyzer.calculateExpPerHour(expGained, timeElapsed)
end

function calculateNextLevelPercent(player)
    return GameAnalyzer.calculateNextLevelPercent(player)
end

function safeNumber(str)
    if not str or str == "" then
        return 0
    end
    
    -- Remove commas
    local cleanStr = string.gsub(str, ",", "")
    
    -- Call tonumber directly instead of using pcall
    local result = tonumber(cleanStr)
    
    -- Return the result or 0 if it's nil
    return result or 0
end

function comma_value(amount)
    return GameAnalyzer.comma_value(amount)
end

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
        onExperienceRateChange = GameAnalyzer.onExperienceRateChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onPingBack = refresh
    })
    
    refresh()
end

function expAnalyzerInit()
    expAnalyzerWindow = g_ui.loadUI('game_exp_analyzer')
    expAnalyzerWindow:setup()
    setupExpAnalyzerWindowResize()

    -- Reset tracking variables
    expStart = nil
    rawExpTotal = 0
    expHourStart = 0
    
    -- Initialize values with string "0"
    expAnalyzerWindow:recursiveGetChildById('rawExpGainValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('expGainValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('rawExpHourValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('expHourValue'):setText("0")

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
    -- Initialize values with string "0"
    expAnalyzerWindow:recursiveGetChildById('rawExpGainValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('expGainValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('rawExpHourValue'):setText("0")
    expAnalyzerWindow:recursiveGetChildById('expHourValue'):setText("0")
end

function expAnalyzerTerminate()
    -- Update button state before destroying window
    local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
    if button then
        button:setChecked(false)
        button:setOn(false)
    end
    
    -- Reset all tracking variables
    expStart = nil
    rawExpTotal = 0
    expHourStart = 0
    
    expAnalyzerWindow:destroy()
end

function GameAnalyzer.updateExperienceRate(localPlayer)
    -- This function follows a similar pattern to the one in skills.lua
    local baseRate = ExpRating[ExperienceRate.BASE] or 100
    local expRateTotal = baseRate

    for type, value in pairs(ExpRating) do
        if type ~= ExperienceRate.BASE and type ~= ExperienceRate.STAMINA_MULTIPLIER then
            expRateTotal = expRateTotal + (value or 0)
        end
    end

    local staminaMultiplier = ExpRating[ExperienceRate.STAMINA_MULTIPLIER] or 100
    expRateTotal = expRateTotal * staminaMultiplier / 100
    
    return expRateTotal
end

-- Calculate raw experience from modified experience
function GameAnalyzer.calculateRawExperience(modifiedExp, expRateTotal)
    -- Reverse the experience modifier calculation
    -- If modifiedExp = rawExp * (expRateTotal/100)
    -- Then rawExp = modifiedExp * 100 / expRateTotal
    -- If expRateTotal is not provided or invalid, compute it from known modifiers
    if not expRateTotal or expRateTotal <= 0 then
        -- Try to compute total rate from stored ExpRating
        local computedRate = GameAnalyzer.calculateTotalExpRate() or 100
        if g_logger and g_logger.debug then
            g_logger.debug(string.format("[ExpAnalyzer] calculateRawExperience: expRateTotal missing, using computedRate=%.2f", computedRate))
        end
        expRateTotal = computedRate
    end
    
    -- Calculate raw experience - make sure we're dividing correctly
    -- For example: 100 exp with 150% rate should return 67 raw exp (100 * 100 / 150)
    local rawExp = math.floor(modifiedExp * 100 / expRateTotal)
    return rawExp
end

-- Calculate the experience rate from all modifiers
-- This is useful for showing the total XP boost percentage
function GameAnalyzer.calculateTotalExpRate()
    local baseRate = ExpRating[ExperienceRate.BASE] or 100
    local voucherRate = ExpRating[ExperienceRate.VOUCHER] or 0
    local lowLevelRate = ExpRating[ExperienceRate.LOW_LEVEL] or 0
    local xpBoostRate = ExpRating[ExperienceRate.XP_BOOST] or 0
    local staminaMultiplier = ExpRating[ExperienceRate.STAMINA_MULTIPLIER] or 100
    
    -- Calculate the total percentage before stamina multiplier
    local subtotal = baseRate + voucherRate + lowLevelRate + xpBoostRate
    
    -- Apply stamina multiplier (it's a percentage of the subtotal)
    local totalRate = (subtotal * staminaMultiplier) / 100
    
    -- Return the total rate and the percentage increase over base
    local increasePercent = math.floor(totalRate - 100)
    
    return totalRate, increasePercent
end

function GameAnalyzer.onExperienceRateChange(localPlayer, type, value)
    -- Store the new experience rate value
    ExpRating[type] = value
    
    -- Log rate change to console for debugging
    g_logger.debug("Experience rate changed: " .. type .. " = " .. value)
    
    -- If expAnalyzerWindow is visible, update the experience values with new rate
    if expAnalyzerWindow and expAnalyzerWindow:isVisible() and localPlayer then
        -- Update experience values with new rate
        onExperienceChange(localPlayer, localPlayer:getExperience())
    end
end

function GameAnalyzer.terminate()
    -- Don't close windows here, just destroy them
    -- The visible state will be saved thanks to &save: true in OTUI
    
    analyzerButton:destroy()
    analyzerWindow:destroy()
    expAnalyzerTerminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onExperienceRateChange = GameAnalyzer.onExperienceRateChange
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
    -- Reset the button state when the window is closed
    if analyzerButton then
        analyzerButton:setOn(false)
    end
    
    -- Also reset all inner analyzer buttons
    local buttons = analyzerWindow:getChildren()
    for _, button in pairs(buttons) do
        if button:getId():find("AnalyzerButton") then
            button:setChecked(false)
            button:setOn(false)
        end
    end
end

function loadContentPanel()
    contentPanel = modules.game_interface.findContentPanelAvailable(analyzerWindow, analyzerWindow:getMinimumHeight())
    if not contentPanel then
        --print("No content panel available")
        return
    end
    
    -- Let setupOnStart handle window placement when we go online
    -- This ensures windows are placed exactly where they were before
end

function GameAnalyzer.toggle()
    if analyzerButton:isOn() then
        -- If button is on (pressed), close the window
        -- onMiniWindowClose will handle resetting the button state
        analyzerWindow:close()
    else
        -- If button is off, open the window
        -- Add to content panel if it doesn't have a parent
        if not analyzerWindow:getParent() then
            contentPanel:addChild(analyzerWindow)
        end
        analyzerWindow:open()
        analyzerButton:setOn(true)
    end
end

function online()
    analyzerButton:show()
    
    -- Setup window using saved position and state
    if analyzerWindow:isVisible() then
        if not analyzerWindow:getParent() then
            contentPanel:addChild(analyzerWindow)
        end
        
        -- Setup the window based on saved character settings
        analyzerWindow:setupOnStart()
        
        -- Ensure button state matches window state
        analyzerButton:setOn(true)
    else
        analyzerButton:setOn(false)
    end
    
    -- Also setup experience analyzer window if it's visible
    if expAnalyzerWindow and expAnalyzerWindow:isVisible() then
        if not expAnalyzerWindow:getParent() then
            contentPanel:addChild(expAnalyzerWindow)
        end
        
        -- Setup the window based on saved character settings
        expAnalyzerWindow:setupOnStart()
        
        -- Update the button state
        local button = analyzerWindow:recursiveGetChildById('expAnalyzerButton')
        if button then
            button:setChecked(true)
            button:setOn(true)
        end
    end
    
    refresh()
    expStart = nil
    expHourStart = 0
    expTimeElapsed = 0
end

function offline()
    -- Save the current visibility state (already handled by &save: true in OTUI)
    -- Hide the button but preserve window state
    analyzerButton:hide()
    
    -- Remove from parent but don't close (which would reset the visible state)
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
        -- If window doesn't have a parent, add it to content panel
        if not expAnalyzerWindow:getParent() then
            contentPanel:addChild(expAnalyzerWindow)
        end
        
        -- Reset tracking variables when opening window
        local player = g_game.getLocalPlayer()
        if player then
            expStart = player:getExperience()
            rawExpTotal = 0
            expHourStart = g_clock.seconds()
            
            -- Reset all displayed values to 0
            local rawExpGainValue = expAnalyzerWindow:recursiveGetChildById('rawExpGainValue')
            local expGainValue = expAnalyzerWindow:recursiveGetChildById('expGainValue')
            local rawExpHourValue = expAnalyzerWindow:recursiveGetChildById('rawExpHourValue')
            local expHourValue = expAnalyzerWindow:recursiveGetChildById('expHourValue')
            
            if rawExpGainValue then rawExpGainValue:setText('0') end
            if expGainValue then expGainValue:setText('0') end
            if rawExpHourValue then rawExpHourValue:setText('0') end
            if expHourValue then expHourValue:setText('0') end
        end
        
        -- Ensure the button stays in active state
        analyzer:setOn(true)
        analyzer:setChecked(true)
        
        -- Open the window after setting button state
        expAnalyzerWindow:open()
        
        -- Let setupOnStart handle window placement if needed
        expAnalyzerWindow:setupOnStart()
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
        -- Get the current experience rate total
        local expRateTotal = GameAnalyzer.updateExperienceRate(player)
        
        -- Calculate raw experience values
        local expDiff = exp - (oldExp or exp)
        
        -- Only process positive experience gains
        if expDiff > 0 then
            -- Calculate the equivalent raw experience gain
            local rawExpDiff = GameAnalyzer.calculateRawExperience(expDiff, expRateTotal)

            -- Debug: log values so we can verify the rate and calculation
            if g_logger and g_logger.debug then
                local rates = string.format("expRateTotal=%.2f", (expRateTotal or -1))
                g_logger.debug(string.format("[ExpAnalyzer] exp=%d oldExp=%s expDiff=%d %s rawExpDiff=%d", exp, tostring(oldExp), expDiff, rates, rawExpDiff))
            end
            
            -- Initialize tracking variables if needed
            if expStart == nil then
                expStart = exp
                rawExpTotal = 0
                expHourStart = g_clock.seconds()
            end
            
            -- Accumulate raw experience gain
            rawExpTotal = rawExpTotal + rawExpDiff
            
            -- Update the UI
            local rawExpGainValue = expAnalyzerWindow:recursiveGetChildById('rawExpGainValue')
            if rawExpGainValue then
                rawExpGainValue:setText(GameAnalyzer.comma_value(rawExpTotal))
            end
            
            -- Update standard experience gain
            local expGainValue = expAnalyzerWindow:recursiveGetChildById('expGainValue')
            if expGainValue then
                expGainValue:setText(GameAnalyzer.comma_value(exp - expStart))
            end

            -- ...existing code... (per-hour updates moved below)
        end

        -- Calculate and update next level info
        local nextLevelValue = expAnalyzerWindow:recursiveGetChildById('nextLevelValue')
        local progressBar = expAnalyzerWindow:recursiveGetChildById('expToNextLvlBar')
        
        if nextLevelValue and progressBar then
            local percent, expNeeded = GameAnalyzer.calculateNextLevelPercent(player)
            
            -- Update next level value with experience needed
            nextLevelValue:setText(GameAnalyzer.comma_value(expNeeded))
            
            -- Update progress bar with percentage to next level
            progressBar:setPercent(percent)
        end
    -- Update per-hour displays every time (so they decrease over time)
    -- This block runs inside the `if expAnalyzerWindow then` guard above
    -- Calculate and update raw experience per hour
    local rawExpHourValue = expAnalyzerWindow:recursiveGetChildById('rawExpHourValue')
    if rawExpHourValue then
        if expHourStart == 0 then
            expHourStart = g_clock.seconds()
        end
        local timeElapsed = g_clock.seconds() - expHourStart
        if timeElapsed > 0 then
            local rawExpPerHour = GameAnalyzer.calculateRawExpPerHour(rawExpTotal, timeElapsed)
            rawExpHourValue:setText(rawExpPerHour)
        end
    end

    -- Calculate and update standard experience per hour
    local expHourValue = expAnalyzerWindow:recursiveGetChildById('expHourValue')
    if expHourValue then
        if expHourStart == 0 then
            expHourStart = g_clock.seconds()
        end
        local timeElapsed = g_clock.seconds() - expHourStart
        if timeElapsed > 0 then
            local expGained = (expStart and (exp - expStart)) or 0
            local expPerHour = GameAnalyzer.calculateExpPerHour(expGained, timeElapsed)
            expHourValue:setText(expPerHour)
        end
    end
    end
end

function GameAnalyzer.calculateExpPerHour(expGained, timeElapsed)
    -- Ensure we don't divide by zero
    if timeElapsed <= 0 then
        return "0"
    end
    
    local expPerHour = math.floor((expGained / timeElapsed) * 3600)
    
    -- Handle negative values properly
    if expPerHour < 0 then
        return "-" .. GameAnalyzer.comma_value(math.abs(expPerHour))
    else
        return GameAnalyzer.comma_value(expPerHour)
    end
end

function GameAnalyzer.calculateRawExpPerHour(rawExpGained, timeElapsed)
    -- Ensure we don't divide by zero
    if timeElapsed <= 0 then
        return "0"
    end
    
    local rawExpPerHour = math.floor((rawExpGained / timeElapsed) * 3600)
    
    -- Handle negative values properly
    if rawExpPerHour < 0 then
        return "-" .. GameAnalyzer.comma_value(math.abs(rawExpPerHour))
    else
        return GameAnalyzer.comma_value(rawExpPerHour)
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

-- Safely convert a string to a number
function GameAnalyzer.safeNumber(str)
    if not str or str == "" then
        return 0
    end
    
    -- Remove commas
    local cleanStr = string.gsub(str, ",", "")
    
    -- Call tonumber directly
    local result = tonumber(cleanStr)
    
    -- Return the result or 0 if it's nil
    return result or 0
end

-- Format numbers with commas
function GameAnalyzer.comma_value(amount)
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

-- Calculate experience required for a specific level
function expForLevel(level)
    return math.floor((50 * level * level * level) / 3 - 100 * level * level + (850 * level) / 3 - 200)
end

-- Calculate experience needed to advance to the next level
function expToAdvance(currentLevel, currentExp)
    return expForLevel(currentLevel + 1) - currentExp
end

-- Calculate percentage to next level
function GameAnalyzer.calculateNextLevelPercent(player)
    local currentLevel = player:getLevel()
    local currentExp = player:getExperience()
    local nextLevelExp = expForLevel(currentLevel + 1)
    local prevLevelExp = expForLevel(currentLevel)
    
    -- Calculate the experience needed for this level and how much we've gained
    local expNeeded = nextLevelExp - prevLevelExp
    local expGained = currentExp - prevLevelExp
    
    -- Calculate the percentage (0-100)
    local percent = math.min(math.floor((expGained / expNeeded) * 100), 100)
    
    return percent, expNeeded - expGained
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