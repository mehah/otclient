skillsWindow = nil
skillsButton = nil
skillsSettings = nil
local ExpRating = {}

function init()
    connect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange,
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
        onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onTotalCapacityChange = onTotalCapacityChange,
        onStaminaChange = onStaminaChange,
        onOfflineTrainingChange = onOfflineTrainingChange,
        onRegenerationChange = onRegenerationChange,
        onSpeedChange = onSpeedChange,
        onBaseSpeedChange = onBaseSpeedChange,
        onMagicLevelChange = onMagicLevelChange,
        onBaseMagicLevelChange = onBaseMagicLevelChange,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onBaseSkillChange,
        onFlatDamageHealingChange = onFlatDamageHealingChange,
        onAttackInfoChange = onAttackInfoChange,
        onConvertedDamageChange = onConvertedDamageChange,
        onImbuementsChange = onImbuementsChange,
        onDefenseInfoChange = onDefenseInfoChange,
        onCombatAbsorbValuesChange = onCombatAbsorbValuesChange,
        onForgeBonusesChange = onForgeBonusesChange,
        onExperienceRateChange = onExperienceRateChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    skillsButton = modules.game_mainpanel.addToggleButton('skillsButton', tr('Skills') .. ' (Alt+S)',
                                                                   '/images/options/button_skills', toggle, false, 1)
    skillsButton:setOn(true)
    skillsWindow = g_ui.loadUI('skills')
    
    -- Set minimum height for skills window
    skillsWindow:setContentMinimumHeight(80)

    Keybind.new("Windows", "Show/hide skills windows", "Alt+S", "")
    Keybind.bind("Windows", "Show/hide skills windows", {
      {
        type = KEY_DOWN,
        callback = toggle,
      }
    })

    skillSettings = g_settings.getNode('skills-hide')
    if not skillSettings then
        skillSettings = {}
    end

    -- Hide toggleFilterButton and adjust contextmenuButton anchors
    local toggleFilterButton = skillsWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    local contextMenuButton = skillsWindow:recursiveGetChildById('contextMenuButton')
    local minimizeButton = skillsWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        contextMenuButton:setMarginRight(7)
        
        -- Add onClick handler for context menu
        contextMenuButton.onClick = function(widget, mousePos, mouseButton)
            return showSkillsContextMenu(widget, mousePos, mouseButton)
        end
    end
    
    -- Add onClick handler to newWindowButton to open Cyclopedia Character tab
    local newWindowButton = skillsWindow:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton.onClick = function()
            if modules.game_cyclopedia then
                modules.game_cyclopedia.show("character")
            end
        end
    end

    refresh()
    skillsWindow:setup()
    if g_game.isOnline() then
        skillsWindow:setupOnStart()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange,
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
        onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onTotalCapacityChange = onTotalCapacityChange,
        onStaminaChange = onStaminaChange,
        onOfflineTrainingChange = onOfflineTrainingChange,
        onRegenerationChange = onRegenerationChange,
        onSpeedChange = onSpeedChange,
        onBaseSpeedChange = onBaseSpeedChange,
        onMagicLevelChange = onMagicLevelChange,
        onBaseMagicLevelChange = onBaseMagicLevelChange,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onBaseSkillChange,
        onFlatDamageHealingChange = onFlatDamageHealingChange,
        onAttackInfoChange = onAttackInfoChange,
        onConvertedDamageChange = onConvertedDamageChange,
        onImbuementsChange = onImbuementsChange,
        onDefenseInfoChange = onDefenseInfoChange,
        onCombatAbsorbValuesChange = onCombatAbsorbValuesChange,
        onForgeBonusesChange = onForgeBonusesChange,
        onExperienceRateChange = onExperienceRateChange
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    Keybind.delete("Windows", "Show/hide skills windows")
    skillsWindow:destroy()
    skillsButton:destroy()

    skillsWindow = nil
    skillsButton = nil
end

function showSkillsContextMenu(widget, mousePos, mouseButton)
    local menu = g_ui.createWidget('SkillsListSubMenu')
    menu:setGameMenu(true)

    if not g_game.getFeature(GameOfflineTrainingTime) then
        local offlineTrainingOption = menu:getChildById('showOfflineTraining')
        if offlineTrainingOption then
            offlineTrainingOption:setVisible(false)
        end
    end
    
    -- Hide offense, defense, and misc stats options for older client versions
    if g_game.getClientVersion() < 1412 then
        local offenceStatsOption = menu:getChildById('showOffenceStats')
        if offenceStatsOption then
            offenceStatsOption:setVisible(false)
        end
        
        local defenceStatsOption = menu:getChildById('showDefenceStats')
        if defenceStatsOption then
            defenceStatsOption:setVisible(false)
        end
        
        local miscStatsOption = menu:getChildById('showMiscStats')
        if miscStatsOption then
            miscStatsOption:setVisible(false)
        end
        
        -- Hide horizontal separators related to the stats options
        -- Since all stats are hidden, hide all separators except the first one
        local children = menu:getChildren()
        local separatorCount = 0
        
        for i, child in ipairs(children) do
            -- Check if this is a horizontal separator by class name or id
            if child:getClassName() == 'HorizontalSeparator' or child:getId() == 'HorizontalSeparator' then
                separatorCount = separatorCount + 1
                -- Keep the first separator (after Reset Experience Counter), hide the rest
                if separatorCount > 1 then
                    child:setVisible(false)
                end
            end
        end
    end

    for _, choice in ipairs(menu:getChildren()) do
        local choiceId = choice:getId()
        if choiceId and choiceId ~= 'HorizontalSeparator' then
            if choiceId == 'resetExperienceCounter' then
                choice.onClick = function()
                    onSkillsMenuAction(choiceId)
                    menu:destroy()
                end
            else
                -- For toggle options, get current state and set accordingly
                local currentState = getSkillVisibilityState(choiceId)
                choice:setChecked(currentState)
                choice.onCheckChange = function()
                    onSkillsMenuAction(choiceId)
                    menu:destroy()
                end
            end
        end
    end
    
    local buttonPos = widget:getPosition()
    local buttonSize = widget:getSize()
    local menuWidth = menu:getWidth()
    
    local buttonCenterX = buttonPos.x + buttonSize.width / 2
    local buttonCenterY = buttonPos.y + buttonSize.height / 2
    
    local menuX = buttonCenterX - menuWidth
    local menuY = buttonCenterY
    
    menu:display({x = menuX, y = menuY})
    return true
end

function onSkillsMenuAction(actionId)
    if actionId == 'resetExperienceCounter' then
        resetExperienceCounter()
    elseif actionId == 'showLevel' then
        toggleSkillProgressBar('level')
    elseif actionId == 'showStamina' then
        toggleSkillProgressBar('stamina')
    elseif actionId == 'showOfflineTraining' then
        toggleSkillProgressBar('offlineTraining')
    elseif actionId == 'showMagic' then
        toggleSkillProgressBar('magiclevel')
    elseif actionId == 'showFist' then
        toggleSkillProgressBar('skillId0')
    elseif actionId == 'showClub' then
        toggleSkillProgressBar('skillId1')
    elseif actionId == 'showSword' then
        toggleSkillProgressBar('skillId2')
    elseif actionId == 'showAxe' then
        toggleSkillProgressBar('skillId3')
    elseif actionId == 'showDistance' then
        toggleSkillProgressBar('skillId4')
    elseif actionId == 'showShielding' then
        toggleSkillProgressBar('skillId5')
    elseif actionId == 'showFishing' then
        toggleSkillProgressBar('skillId6')
    elseif actionId == 'showOffenceStats' then
        toggleOffenceStatsVisibility()
    elseif actionId == 'showDefenceStats' then
        toggleDefenceStatsVisibility()
    elseif actionId == 'showMiscStats' then
        toggleMiscStatsVisibility()
    elseif actionId == 'showAllSkillBars' then
        toggleAllSkillBars()
    end
end

function getSkillVisibilityState(actionId)
    if actionId == 'showLevel' then
        return isSkillPercentBarVisible('level')
    elseif actionId == 'showStamina' then
        return isSkillPercentBarVisible('stamina')
    elseif actionId == 'showOfflineTraining' then
        return isSkillPercentBarVisible('offlineTraining')
    elseif actionId == 'showMagic' then
        return isSkillPercentBarVisible('magiclevel')
    elseif actionId == 'showFist' then
        return isSkillPercentBarVisible('skillId0')
    elseif actionId == 'showClub' then
        return isSkillPercentBarVisible('skillId1')
    elseif actionId == 'showSword' then
        return isSkillPercentBarVisible('skillId2')
    elseif actionId == 'showAxe' then
        return isSkillPercentBarVisible('skillId3')
    elseif actionId == 'showDistance' then
        return isSkillPercentBarVisible('skillId4')
    elseif actionId == 'showShielding' then
        return isSkillPercentBarVisible('skillId5')
    elseif actionId == 'showFishing' then
        return isSkillPercentBarVisible('skillId6')
    elseif actionId == 'showOffenceStats' then
        return areOffenceStatsVisible()
    elseif actionId == 'showDefenceStats' then
        return areDefenceStatsVisible()
    elseif actionId == 'showMiscStats' then
        return areMiscStatsVisible()
    elseif actionId == 'showAllSkillBars' then
        return areAllSkillBarsVisible()
    end
    return false
end

function isSkillVisible(skillId)
    local skill = skillsWindow:recursiveGetChildById(skillId)
    return skill and skill:isVisible()
end

function isSkillPercentBarVisible(skillId)
    local skill = skillsWindow:recursiveGetChildById(skillId)
    if skill then
        local percentBar = skill:getChildById('percent')
        return percentBar and percentBar:isVisible()
    end
    return false
end

function toggleSkillProgressBar(skillId)
    local skill = skillsWindow:recursiveGetChildById(skillId)
    if skill then
        local percentBar = skill:getChildById('percent')
        local skillIcon = skill:getChildById('icon')
        
        if percentBar then
            local isVisible = percentBar:isVisible()
            percentBar:setVisible(not isVisible)
            
            -- Also toggle skill icon if it exists
            if skillIcon then
                skillIcon:setVisible(not isVisible)
            end
            
            -- Adjust skill button height
            if not isVisible then
                skill:setHeight(21) -- Show progress bar
            else
                skill:setHeight(15) -- Hide progress bar
            end
            
            -- Save the setting
            local char = g_game.getCharacterName()
            if not skillSettings[char] then
                skillSettings[char] = {}
            end
            skillSettings[char][skillId] = isVisible and 1 or 0  -- 1 = hidden, 0 = visible
            g_settings.setNode('skills-hide', skillSettings)
        end
    end
end

function toggleSkillVisibility(skillId)
    local skill = skillsWindow:recursiveGetChildById(skillId)
    if skill then
        local percentBar = skill:getChildById('percent')
        local skillIcon = skill:getChildById('icon')
        
        if percentBar then
            local isVisible = percentBar:isVisible()
            percentBar:setVisible(not isVisible)
            
            -- Also toggle skill icon if it exists
            if skillIcon then
                skillIcon:setVisible(not isVisible)
            end
            
            -- Adjust skill button height
            if not isVisible then
                skill:setHeight(21) -- Show progress bar
            else
                skill:setHeight(15) -- Hide progress bar
            end
            
            -- Save the setting
            local char = g_game.getCharacterName()
            if not skillSettings[char] then
                skillSettings[char] = {}
            end
            skillSettings[char][skillId] = isVisible and 1 or 0  -- 1 = hidden, 0 = visible
            g_settings.setNode('skills-hide', skillSettings)
        end
    end
end

function resetExperienceCounter()
    -- Reset experience counter logic can be added here
    -- For now, we'll just show a message
    local player = g_game.getLocalPlayer()
    if player then
        modules.game_textmessage.displayGameMessage('Experience counter has been reset.')
    end
end

function areOffenceStatsVisible()
    local offenceStats = {
        'skillId7', 'skillId8', 'skillId9', 'skillId10', 'skillId11', 'skillId12', 
        'skillId13', 'skillId14', 'skillId15', 'skillId16', 'separadorOnOffenceInfoChange'
    }
    for _, skillId in pairs(offenceStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill and skill:isVisible() then
            return true
        end
    end
    return false
end

function toggleOffenceStatsVisibility()
    local offenceStats = {
        'skillId7', 'skillId8', 'skillId9', 'skillId10', 'skillId11', 'skillId12', 
        'skillId13', 'skillId14', 'skillId15', 'skillId16', 'separadorOnOffenceInfoChange'
    }
    local shouldShow = not areOffenceStatsVisible()
    
    for _, skillId in pairs(offenceStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill then
            skill:setVisible(shouldShow)
        end
    end
    
    -- Save settings
    local char = g_game.getCharacterName()
    if not skillSettings[char] then
        skillSettings[char] = {}
    end
    skillSettings[char]['offenceStats_visible'] = shouldShow
    g_settings.setNode('skills-hide', skillSettings)
end

function areDefenceStatsVisible()
    local defenceStats = {
        'physicalResist', 'fireResist', 'earthResist', 'energyResist', 'IceResist', 
        'HolyResist', 'deathResist', 'HealingResist', 'drowResist', 'lifedrainResist', 
        'manadRainResist', 'defenceValue', 'armorValue', 'mitigation', 'dodge', 
        'damageReflection', 'separadorOnDefenseInfoChange'
    }
    for _, skillId in pairs(defenceStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill and skill:isVisible() then
            return true
        end
    end
    return false
end

function toggleDefenceStatsVisibility()
    local defenceStats = {
        'physicalResist', 'fireResist', 'earthResist', 'energyResist', 'IceResist', 
        'HolyResist', 'deathResist', 'HealingResist', 'drowResist', 'lifedrainResist', 
        'manadRainResist', 'defenceValue', 'armorValue', 'mitigation', 'dodge', 
        'damageReflection', 'separadorOnDefenseInfoChange'
    }
    local shouldShow = not areDefenceStatsVisible()
    
    for _, skillId in pairs(defenceStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill then
            skill:setVisible(shouldShow)
        end
    end
    
    -- Save settings
    local char = g_game.getCharacterName()
    if not skillSettings[char] then
        skillSettings[char] = {}
    end
    skillSettings[char]['defenceStats_visible'] = shouldShow
    g_settings.setNode('skills-hide', skillSettings)
end

function areMiscStatsVisible()
    local miscStats = {
        'momentum', 'transcendence', 'amplification', 'separadorOnForgeBonusesChange'
    }
    for _, skillId in pairs(miscStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill and skill:isVisible() then
            return true
        end
    end
    return false
end

function toggleMiscStatsVisibility()
    local miscStats = {
        'momentum', 'transcendence', 'amplification', 'separadorOnForgeBonusesChange'
    }
    local shouldShow = not areMiscStatsVisible()
    
    for _, skillId in pairs(miscStats) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill then
            skill:setVisible(shouldShow)
        end
    end
    
    -- Save settings
    local char = g_game.getCharacterName()
    if not skillSettings[char] then
        skillSettings[char] = {}
    end
    skillSettings[char]['miscStats_visible'] = shouldShow
    g_settings.setNode('skills-hide', skillSettings)
end

function areAllSkillBarsVisible()
    local allSkills = {
        'level', 'stamina', 'offlineTraining', 'magiclevel', 'skillId0', 'skillId1', 
        'skillId2', 'skillId3', 'skillId4', 'skillId5', 'skillId6'
    }
    for _, skillId in pairs(allSkills) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill then
            local percentBar = skill:getChildById('percent')
            if percentBar and not percentBar:isVisible() then
                return false
            end
        end
    end
    return true
end

function toggleAllSkillBars()
    local allSkills = {
        'level', 'stamina', 'offlineTraining', 'magiclevel', 'skillId0', 'skillId1', 
        'skillId2', 'skillId3', 'skillId4', 'skillId5', 'skillId6'
    }
    local shouldShow = not areAllSkillBarsVisible()
    
    for _, skillId in pairs(allSkills) do
        local skill = skillsWindow:recursiveGetChildById(skillId)
        if skill then
            local percentBar = skill:getChildById('percent')
            local skillIcon = skill:getChildById('icon')
            
            if percentBar then
                percentBar:setVisible(shouldShow)
                
                -- Also toggle skill icon if it exists
                if skillIcon then
                    skillIcon:setVisible(shouldShow)
                end
                
                -- Adjust skill button height
                if shouldShow then
                    skill:setHeight(21) -- Show progress bar
                else
                    skill:setHeight(15) -- Hide progress bar
                end
                
                -- Save settings
                local char = g_game.getCharacterName()
                if not skillSettings[char] then
                    skillSettings[char] = {}
                end
                skillSettings[char][skillId] = shouldShow and 0 or 1  -- 1 = hidden, 0 = visible
            end
        end
    end
    
    g_settings.setNode('skills-hide', skillSettings)
end

function expForLevel(level)
    return math.floor((50 * level * level * level) / 3 - 100 * level * level + (850 * level) / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
    return expForLevel(currentLevel + 1) - currentExp
end

function resetSkillColor(id)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')
    widget:setColor('#bbbbbb')
end

function toggleSkill(id, state)
    local skill = skillsWindow:recursiveGetChildById(id)
    skill:setVisible(state)
end

function setSkillBase(id, value, baseValue)
    if baseValue <= 0 or value < 0 then
        return
    end
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')

    if value > baseValue then
        widget:setColor('#008b00') -- green
        skill:setTooltip(baseValue .. ' +' .. (value - baseValue))
    elseif value < baseValue then
        widget:setColor('#b22222') -- red
        skill:setTooltip(baseValue .. ' ' .. (value - baseValue))
    else
        widget:setColor('#bbbbbb') -- default
        skill:removeTooltip()
    end
end

function setSkillValue(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    if skill then
        local widget = skill:getChildById('value')
        if id == "skillId7" or id == "skillId8" or id == "skillId9" or id == "skillId11" or id == "skillId13" or id == "skillId14" or id == "skillId15" or id == "skillId16" then
            if g_game.getFeature(GameEnterGameShowAppearance) then
                value = value / 100
            end
            widget:setText(value .. "%")
        else
            widget:setText(value)
        end
    end
end

function setSkillColor(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    if skill then
        local widget = skill:getChildById('value')
        widget:setColor(value)
    end
end

function setSkillTooltip(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    if skill then
        if value then
            skill:setTooltip(value)
        else
            skill:removeTooltip()
        end
    end
end

function setSkillPercent(id, percent, tooltip, color)
    local skill = skillsWindow:recursiveGetChildById(id)
    if skill then
        local widget = skill:getChildById('percent')
        if widget then
            widget:setPercent(math.floor(percent))

            if tooltip then
                widget:setTooltip(tooltip)
            end

            if color then
                widget:setBackgroundColor(color)
            end
        end
    end
end

function checkAlert(id, value, maxValue, threshold, greaterThan)
    if greaterThan == nil then
        greaterThan = false
    end
    local alert = false

    -- maxValue can be set to false to check value and threshold
    -- used for regeneration checking
    if type(maxValue) == 'boolean' then
        if maxValue then
            return
        end

        if greaterThan then
            if value > threshold then
                alert = true
            end
        else
            if value < threshold then
                alert = true
            end
        end
    elseif type(maxValue) == 'number' then
        if maxValue < 0 then
            return
        end

        local percent = math.floor((value / maxValue) * 100)
        if greaterThan then
            if percent > threshold then
                alert = true
            end
        else
            if percent < threshold then
                alert = true
            end
        end
    end

    if alert then
        setSkillColor(id, '#b22222') -- red
    else
        resetSkillColor(id)
    end
end

function update()
    local offlineTraining = skillsWindow:recursiveGetChildById('offlineTraining')
    if not g_game.getFeature(GameOfflineTrainingTime) then
        offlineTraining:hide()
    else
        offlineTraining:show()
    end

    local regenerationTime = skillsWindow:recursiveGetChildById('regenerationTime')
    if not g_game.getFeature(GamePlayerRegenerationTime) then
        regenerationTime:hide()
    else
        regenerationTime:show()
    end
    local xpBoostButton = skillsWindow:recursiveGetChildById('xpBoostButton')
    local xpGainRate = skillsWindow:recursiveGetChildById('xpGainRate')
    if g_game.getFeature(GameExperienceBonus) then
        xpBoostButton:show()
        xpGainRate:show()
    else
        xpBoostButton:hide()
        xpGainRate:hide()
    end
end

function online()
    skillsWindow:setupOnStart() -- load character window configuration
    
    -- Hide toggleFilterButton and adjust contextmenuButton anchors
    local toggleFilterButton = skillsWindow:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
        toggleFilterButton:setOn(false)
    end
    
    local contextMenuButton = skillsWindow:recursiveGetChildById('contextMenuButton')
    local minimizeButton = skillsWindow:recursiveGetChildById('minimizeButton')
    if contextMenuButton and minimizeButton then
        contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        contextMenuButton:setMarginRight(7)
    end
    
    -- Add onClick handler to newWindowButton to open Cyclopedia Character tab
    local newWindowButton = skillsWindow:recursiveGetChildById('newWindowButton')

    if g_game.getClientVersion() < 1310 then
        newWindowButton:hide()
    end

    if newWindowButton then
        newWindowButton.onClick = function()
            if modules.game_cyclopedia then
                modules.game_cyclopedia.show("character")
            end
        end
    end
    
    refresh()
    if g_game.getFeature(GameEnterGameShowAppearance) then
        skillsWindow:recursiveGetChildById('regenerationTime'):getChildByIndex(1):setText('Food')
    end
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if expSpeedEvent then
        expSpeedEvent:cancel()
    end
    expSpeedEvent = cycleEvent(checkExpSpeed, 30 * 1000)

    onExperienceChange(player, player:getExperience())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
    onHealthChange(player, player:getHealth(), player:getMaxHealth())
    onManaChange(player, player:getMana(), player:getMaxMana())
    onSoulChange(player, player:getSoul())
    onFreeCapacityChange(player, player:getFreeCapacity())
    onStaminaChange(player, player:getStamina())
    onMagicLevelChange(player, player:getMagicLevel(), player:getMagicLevelPercent())
    onOfflineTrainingChange(player, player:getOfflineTrainingTime())
    onRegenerationChange(player, player:getRegenerationTime())
    onSpeedChange(player, player:getSpeed())

    local hasAdditionalSkills = g_game.getFeature(GameAdditionalSkills)
    for i = Skill.Fist, Skill.Transcendence do
        onSkillChange(player, i, player:getSkillLevel(i), player:getSkillLevelPercent(i))

        if i > Skill.Fishing then
            local ativedAdditionalSkills = hasAdditionalSkills
            if ativedAdditionalSkills then
                if g_game.getClientVersion() >= 1281 then
                    if i == Skill.LifeLeechAmount or i == Skill.ManaLeechAmount then
                        ativedAdditionalSkills = false
                    elseif g_game.getClientVersion() < 1332 and Skill.Transcendence then
                        ativedAdditionalSkills = false
                    elseif i >= Skill.Fatal and player:getSkillLevel(i) <= 0 then
                        ativedAdditionalSkills = false
                    end
                elseif g_game.getClientVersion() < 1281 and i >= Skill.Fatal then
                    ativedAdditionalSkills = false
                end
            end
            toggleSkill('skillId' .. i, ativedAdditionalSkills)
        end
    end
-- todo reload skills 14.12
    update()
    updateHeight()
    
    -- Hide offense, defense, and misc stats content for older client versions
    if g_game.getClientVersion() < 1412 then
        -- Hide offense stats
        local offenceStats = {
            'skillId7', 'skillId8', 'skillId9', 'skillId10', 'skillId11', 'skillId12', 
            'skillId13', 'skillId14', 'skillId15', 'skillId16'
        }
        for _, skillId in pairs(offenceStats) do
            local skill = skillsWindow:recursiveGetChildById(skillId)
            if skill then
                skill:hide()
            end
        end
        
        -- Hide defense stats
        local defenceStats = {
            'physicalResist', 'fireResist', 'earthResist', 'energyResist', 'IceResist', 
            'HolyResist', 'deathResist', 'HealingResist', 'drowResist', 'lifedrainResist', 
            'manadRainResist', 'defenceValue', 'armorValue', 'mitigation', 'dodge', 
            'damageReflection', 'separadorOnDefenseInfoChange'
        }
        for _, skillId in pairs(defenceStats) do
            local skill = skillsWindow:recursiveGetChildById(skillId)
            if skill then
                skill:hide()
            end
        end
        
        -- Hide misc stats
        local miscStats = {
            'momentum', 'transcendence', 'amplification', 'separadorOnForgeBonusesChange'
        }
        for _, skillId in pairs(miscStats) do
            local skill = skillsWindow:recursiveGetChildById(skillId)
            if skill then
                skill:hide()
            end
        end
        
        -- Hide additional separator elements that might be visible
        local additionalSeparators = {
            'criticalHit', 'damageHealing', 'attackValue', 'convertedDamage', 'convertedElement',
            'lifeLeech', 'manaLeech', 'criticalChance', 'criticalExtraDamage', 'onslaught'
        }
        for _, separatorId in pairs(additionalSeparators) do
            local separator = skillsWindow:recursiveGetChildById(separatorId)
            if separator then
                separator:hide()
            end
        end
        
        -- Hide unnamed horizontal separators in the skills window
        -- Search recursively for all horizontal separators and hide unnamed ones
        local function hideUnnamedSeparators(widget)
            if not widget then return end
            
            local children = widget:getChildren()
            for _, child in pairs(children) do
                if child:getClassName() == 'HorizontalSeparator' and (not child:getId() or child:getId() == '') then
                    child:hide()
                elseif child:getClassName() == 'UIWidget' and (not child:getId() or child:getId() == '') then
                    -- Additional check for widgets that might be separators
                    local childHeight = child:getHeight()
                    local childChildrenCount = #child:getChildren()
                    if childHeight <= 15 and childChildrenCount == 0 then
                        child:hide()
                    end
                end
                -- Recursively check children
                hideUnnamedSeparators(child)
            end
        end
        
        hideUnnamedSeparators(skillsWindow)
    end
    
    loadSkillsVisibilitySettings()
end

function loadSkillsVisibilitySettings()
    local char = g_game.getCharacterName()
    if not char or not skillSettings[char] then
        return
    end
    
    local settings = skillSettings[char]
    
    -- Load individual skill progress bar visibility settings (using existing format)
    local individualSkills = {
        'level', 'stamina', 'offlineTraining', 'magiclevel', 'skillId0', 'skillId1', 
        'skillId2', 'skillId3', 'skillId4', 'skillId5', 'skillId6'
    }
    
    for _, skillId in pairs(individualSkills) do
        if settings[skillId] ~= nil then
            local skill = skillsWindow:recursiveGetChildById(skillId)
            if skill then
                local percentBar = skill:getChildById('percent')
                local skillIcon = skill:getChildById('icon')
                
                if percentBar then
                    local shouldShow = settings[skillId] ~= 1  -- 1 = hidden, 0 = visible
                    percentBar:setVisible(shouldShow)
                    
                    -- Also set skill icon visibility if it exists
                    if skillIcon then
                        skillIcon:setVisible(shouldShow)
                    end
                    
                    -- Adjust skill button height
                    if shouldShow then
                        skill:setHeight(21) -- Show progress bar
                    else
                        skill:setHeight(15) -- Hide progress bar
                    end
                end
            end
        end
    end
    
    -- Load group visibility settings (these still control entire skill visibility)
    -- Skip loading these settings for older client versions
    if g_game.getClientVersion() >= 1412 then
        if settings['offenceStats_visible'] ~= nil then
            local offenceStats = {
                'skillId7', 'skillId8', 'skillId9', 'skillId10', 'skillId11', 'skillId12', 
                'skillId13', 'skillId14', 'skillId15', 'skillId16'
            }
            for _, skillId in pairs(offenceStats) do
                local skill = skillsWindow:recursiveGetChildById(skillId)
                if skill then
                    skill:setVisible(settings['offenceStats_visible'])
                end
            end
        end
        
        if settings['defenceStats_visible'] ~= nil then
            local defenceStats = {
                'physicalResist', 'fireResist', 'earthResist', 'energyResist', 'IceResist', 
                'HolyResist', 'deathResist', 'HealingResist', 'drowResist', 'lifedrainResist', 
                'manadRainResist', 'defenceValue', 'armorValue', 'mitigation', 'dodge', 
                'damageReflection', 'separadorOnDefenseInfoChange'
            }
            for _, skillId in pairs(defenceStats) do
                local skill = skillsWindow:recursiveGetChildById(skillId)
                if skill then
                    skill:setVisible(settings['defenceStats_visible'])
                end
            end
        end
        
        if settings['miscStats_visible'] ~= nil then
            local miscStats = {
                'momentum', 'transcendence', 'amplification', 'separadorOnForgeBonusesChange'
            }
            for _, skillId in pairs(miscStats) do
                local skill = skillsWindow:recursiveGetChildById(skillId)
                if skill then
                    skill:setVisible(settings['miscStats_visible'])
                end
            end
        end
    end
end

function updateHeight()
    local maximumHeight = 8 -- margin top and bottom
    local minimumHeight = 80 -- ensure minimum height is maintained

    if g_game.isOnline() then
        local char = g_game.getCharacterName()

        if not skillSettings[char] then
            skillSettings[char] = {}
        end

        local skillsButtons = skillsWindow:recursiveGetChildById('experience'):getParent():getChildren()

        for _, skillButton in pairs(skillsButtons) do
            local percentBar = skillButton:getChildById('percent')

            if skillButton:isVisible() then
                if percentBar then
                    showPercentBar(skillButton, skillSettings[char][skillButton:getId()] ~= 1)
                end
                maximumHeight = maximumHeight + skillButton:getHeight() + skillButton:getMarginBottom()
            end
        end
    else
        maximumHeight = 390
    end

    local contentsPanel = skillsWindow:getChildById('contentsPanel')
    skillsWindow:setContentMinimumHeight(math.max(minimumHeight, 44))
    skillsWindow:setContentMaximumHeight(maximumHeight)
end

function offline()
    skillsWindow:setParent(nil, true)
    if expSpeedEvent then
        expSpeedEvent:cancel()
        expSpeedEvent = nil
    end
    g_settings.setNode('skills-hide', skillSettings)
end

function toggle()
    if skillsButton:isOn() then
        skillsWindow:close()
        skillsButton:setOn(false)
    else
        if not skillsWindow:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(skillsWindow, skillsWindow:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(skillsWindow)
        end
        
        -- Hide toggleFilterButton and adjust contextmenuButton anchors
        local toggleFilterButton = skillsWindow:recursiveGetChildById('toggleFilterButton')
        if toggleFilterButton then
            toggleFilterButton:setVisible(false)
            toggleFilterButton:setOn(false)
        end
        
        local contextMenuButton = skillsWindow:recursiveGetChildById('contextMenuButton')
        local minimizeButton = skillsWindow:recursiveGetChildById('minimizeButton')
        if contextMenuButton and minimizeButton then
            contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
            contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
            contextMenuButton:setMarginRight(7)
        end
        
        -- Add onClick handler to newWindowButton to open Cyclopedia Character tab
        local newWindowButton = skillsWindow:recursiveGetChildById('newWindowButton')
        if newWindowButton then
            newWindowButton.onClick = function()
                if modules.game_cyclopedia then
                    modules.game_cyclopedia.show("character")
                end
            end
        end
        
        skillsWindow:open()
        skillsButton:setOn(true)
        updateHeight()
    end
end

function checkExpSpeed()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local currentExp = player:getExperience()
    local currentTime = g_clock.seconds()
    
    if player.lastExps == nil then
        player.lastExps = {}
    end
    
    -- Always add the current data point
    table.insert(player.lastExps, {currentExp, currentTime})
    if #player.lastExps > 30 then
        table.remove(player.lastExps, 1)
    end
    
    -- Calculate experience speed if we have enough data points
    if #player.lastExps >= 2 then
        local oldestEntry = player.lastExps[1]
        local expGained = currentExp - oldestEntry[1]
        local timeElapsed = currentTime - oldestEntry[2]
        
        if timeElapsed > 0 then
            player.expSpeed = expGained / timeElapsed
        else
            player.expSpeed = 0
        end
        
        onLevelChange(player, player:getLevel(), player:getLevelPercent())
        onExperienceChange(player, player:getExperience()) -- Update experience tooltip
    end
end

function onMiniWindowOpen()
    skillsButton:setOn(true)
end

function onMiniWindowClose()
    skillsButton:setOn(false)
end

function onSkillButtonClick(button)
    local percentBar = button:getChildById('percent')
    local skillIcon = button:getChildById('icon')
    if percentBar and skillIcon then
        showPercentBar(button, not percentBar:isVisible())
        skillIcon:setVisible(skillIcon:isVisible())

        local char = g_game.getCharacterName()
        if percentBar:isVisible() then
            skillsWindow:modifyMaximumHeight(6)
            skillSettings[char][button:getId()] = 0
        else
            skillsWindow:modifyMaximumHeight(-6)
            skillSettings[char][button:getId()] = 1
        end
    end
end

function showPercentBar(button, show)
    local percentBar = button:getChildById('percent')
    local skillIcon = button:getChildById('icon')
    if percentBar and skillIcon then
        percentBar:setVisible(show)
        skillIcon:setVisible(show)
        if show then
            button:setHeight(21)
        else
            button:setHeight(21 - 6)
        end
    end
end

function onExperienceChange(localPlayer, value)
    setSkillValue('experience', comma_value(value))
    
    -- Set tooltip with experience rate information when player is receiving experience
    if localPlayer.expSpeed ~= nil then
        local expPerHour = math.floor(localPlayer.expSpeed * 3600)
        
        -- Only show tooltip if we have a positive experience rate
        if expPerHour > 0 then
            local currentLevel = localPlayer:getLevel()
            local currentExp = localPlayer:getExperience()
            local nextLevelExp = expForLevel(currentLevel + 1)
            local expNeeded = nextLevelExp - currentExp
            
            -- Only show time calculation if we actually need more experience
            if expNeeded > 0 then
                local hoursLeft = expNeeded / expPerHour
                local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft)) * 60)
                hoursLeft = math.floor(hoursLeft)
                local expText = tr('%s of experience per hour', comma_value(expPerHour)) .. '\n' ..
                               tr('Next level in %d hours and %d minutes', hoursLeft, minutesLeft)
                setSkillTooltip('experience', expText)
            else
                -- Just show exp per hour if already at max level or calculation error
                local expText = tr('%s of experience per hour', comma_value(expPerHour))
                setSkillTooltip('experience', expText)
            end
        else
            -- Check if player is not in battle (no battle icons) before showing experience left
            local states = localPlayer:getStates()
            local isInBattle = bit.band(states, PlayerStates.Swords) > 0 or bit.band(states, PlayerStates.RedSwords) > 0
            
            if not isInBattle then
                -- Show experience left info when not receiving experience and not in battle
                local currentLevel = localPlayer:getLevel()
                local currentExp = localPlayer:getExperience()
                local nextLevelExp = expForLevel(currentLevel + 1)
                local expNeeded = nextLevelExp - currentExp
                
                if expNeeded > 0 then
                    local expText = tr('%s XP for next level', comma_value(expNeeded))
                    setSkillTooltip('experience', expText)
                else
                    -- Clear tooltip if at max level
                    setSkillTooltip('experience', nil)
                end
            else
                -- Clear tooltip if in battle
                setSkillTooltip('experience', nil)
            end
        end
    else
        -- Check if player is not in battle (no battle icons) before showing experience left
        local states = localPlayer:getStates()
        local isInBattle = bit.band(states, PlayerStates.Swords) > 0 or bit.band(states, PlayerStates.RedSwords) > 0
        
        if not isInBattle then
            -- Show experience left info when no experience speed data and not in battle
            local currentLevel = localPlayer:getLevel()
            local currentExp = localPlayer:getExperience()
            local nextLevelExp = expForLevel(currentLevel + 1)
            local expNeeded = nextLevelExp - currentExp
            
            if expNeeded > 0 then
                local expText = tr('%s XP for next level', comma_value(expNeeded))
                setSkillTooltip('experience', expText)
            else
                -- Clear tooltip if at max level
                setSkillTooltip('experience', nil)
            end
        else
            -- Clear tooltip if in battle
            setSkillTooltip('experience', nil)
        end
    end
end

function onLevelChange(localPlayer, value, percent)
    setSkillValue('level', comma_value(value))
    local text = tr('You have %s percent to go', 100 - percent)

    setSkillPercent('level', percent, text)
end

function onHealthChange(localPlayer, health, maxHealth)
    setSkillValue('health', comma_value(health))
    checkAlert('health', health, maxHealth, 30)
end

function onManaChange(localPlayer, mana, maxMana)
    setSkillValue('mana', comma_value(mana))
    checkAlert('mana', mana, maxMana, 30)
end

function onSoulChange(localPlayer, soul)
    setSkillValue('soul', soul)
end

function onFreeCapacityChange(localPlayer, freeCapacity)
    setSkillValue('capacity', comma_value(freeCapacity))
    checkAlert('capacity', freeCapacity, localPlayer:getTotalCapacity(), 20)
end

function onTotalCapacityChange(localPlayer, totalCapacity)
    checkAlert('capacity', localPlayer:getFreeCapacity(), totalCapacity, 20)
end

function onStaminaChange(localPlayer, stamina)
    local hours = math.floor(stamina / 60)
    local minutes = stamina % 60
    if minutes < 10 then
        minutes = '0' .. minutes
    end
    local percent = math.floor(100 * stamina / (42 * 60)) -- max is 42 hours --TODO not in all client versions

    setSkillValue('stamina', hours .. ':' .. minutes)

    -- TODO not all client versions have premium time
    if stamina > 2400 and g_game.getClientVersion() >= 1038 and localPlayer:isPremium() then
        local text = tr('You have %s hours and %s minutes left', hours, minutes) .. '\n' ..
                         tr('Now you will gain 50%% more experience')
        setSkillPercent('stamina', percent, text, 'green')
    elseif stamina > 2400 and g_game.getClientVersion() >= 1038 and not localPlayer:isPremium() then
        local text = tr('You have %s hours and %s minutes left', hours, minutes) .. '\n' .. tr(
                         'You will not gain 50%% more experience because you aren\'t premium player, now you receive only 1x experience points')
        setSkillPercent('stamina', percent, text, '#89F013')
    elseif stamina >= 2400 and g_game.getClientVersion() < 1038 then
        local text = tr('You have %s hours and %s minutes left', hours, minutes) .. '\n' ..
                         tr('If you are premium player, you will gain 50%% more experience')
        setSkillPercent('stamina', percent, text, 'green')
    elseif stamina < 2400 and stamina > 840 then
        setSkillPercent('stamina', percent, tr('You have %s hours and %s minutes left', hours, minutes), 'orange')
    elseif stamina <= 840 and stamina > 0 then
        local text = tr('You have %s hours and %s minutes left', hours, minutes) .. '\n' ..
                         tr('You gain only 50%% experience and you don\'t may gain loot from monsters')
        setSkillPercent('stamina', percent, text, 'red')
    elseif stamina == 0 then
        local text = tr('You have %s hours and %s minutes left', hours, minutes) .. '\n' ..
                         tr('You don\'t may receive experience and loot from monsters')
        setSkillPercent('stamina', percent, text, 'black')
    end
end

function onOfflineTrainingChange(localPlayer, offlineTrainingTime)
    if not g_game.getFeature(GameOfflineTrainingTime) then
        return
    end
    local hours = math.floor(offlineTrainingTime / 60)
    local minutes = offlineTrainingTime % 60
    if minutes < 10 then
        minutes = '0' .. minutes
    end
    local percent = 100 * offlineTrainingTime / (12 * 60) -- max is 12 hours

    setSkillValue('offlineTraining', hours .. ':' .. minutes)
    setSkillPercent('offlineTraining', percent, tr('You have %s percent', percent))
end

function onRegenerationChange(localPlayer, regenerationTime)
    if not g_game.getFeature(GamePlayerRegenerationTime) or regenerationTime < 0 then
        return
    end
    local hours = math.floor(regenerationTime / 3600)
    local minutes = math.floor(regenerationTime / 60)
    local seconds = regenerationTime % 60
    if seconds < 10 then
        seconds = '0' .. seconds
    end
    if minutes < 10 then
        minutes = '0' .. minutes
    end
    if hours < 10 then
        hours = '0' .. hours
    end
    local fmt = ""
    local alert = 300
    if g_game.getFeature(GameEnterGameShowAppearance) then
        fmt = string.format("%02d:%02d:%02d", hours, minutes, seconds)
        alert = 0
    else
        fmt = string.format("%02d:%02d", minutes, seconds)
    end
    setSkillValue('regenerationTime', fmt)
    checkAlert('regenerationTime', regenerationTime, false, alert)
    if g_game.getFeature(GameEnterGameShowAppearance) then
        modules.game_interface.StatsBar.onHungryChange(regenerationTime, alert)
    end
end

function onSpeedChange(localPlayer, speed)
    setSkillValue('speed', comma_value(speed))

    onBaseSpeedChange(localPlayer, localPlayer:getBaseSpeed())
end

function onBaseSpeedChange(localPlayer, baseSpeed)
    setSkillBase('speed', localPlayer:getSpeed(), baseSpeed)
end

function onMagicLevelChange(localPlayer, magiclevel, percent)
    setSkillValue('magiclevel', magiclevel)
    setSkillPercent('magiclevel', percent, tr('You have %s percent to go', 100 - percent))

    onBaseMagicLevelChange(localPlayer, localPlayer:getBaseMagicLevel())
end

function onBaseMagicLevelChange(localPlayer, baseMagicLevel)
    setSkillBase('magiclevel', localPlayer:getMagicLevel(), baseMagicLevel)
end

function onSkillChange(localPlayer, id, level, percent)
    setSkillValue('skillId' .. id, level)
    setSkillPercent('skillId' .. id, percent, tr('You have %s percent to go', 100 - percent))

    onBaseSkillChange(localPlayer, id, localPlayer:getSkillBaseLevel(id))

    if id > Skill.ManaLeechAmount then
	    toggleSkill('skillId' .. id, level > 0)
    end
end

function onBaseSkillChange(localPlayer, id, baseLevel)
    setSkillBase('skillId' .. id, localPlayer:getSkillLevel(id), baseLevel)
end

-- 14.12
local function updateExperienceRate(localPlayer)
    local baseRate = ExpRating[ExperienceRate.BASE] or 100
    local expRateTotal = baseRate

    for type, value in pairs(ExpRating) do
        if type ~= ExperienceRate.BASE and type ~= ExperienceRate.STAMINA_MULTIPLIER then
            expRateTotal = expRateTotal + (value or 0)
        end
    end

    local staminaMultiplier = ExpRating[ExperienceRate.STAMINA_MULTIPLIER] or 100
    expRateTotal = expRateTotal * staminaMultiplier / 100

    local xpgainrate = skillsWindow:recursiveGetChildById("xpGainRate")
    if not xpgainrate then
        return
    end

    local widget = xpgainrate:getChildById("value")
    if not widget then
        return
    end

    widget:setText(math.floor(expRateTotal) .. "%")

    local tooltip = string.format("Your current XP gain rate amounts to %d%%.", math.floor(expRateTotal))
    tooltip = tooltip ..
                  string.format("\nYour XP gain rate is calculated as follows:\n- Base XP gain rate %d%%", baseRate)

    if (ExpRating[ExperienceRate.VOUCHER] or 0) > 0 then
        tooltip = tooltip .. string.format("\n- Voucher: %d%%", ExpRating[ExperienceRate.VOUCHER])
    end

    if (ExpRating[ExperienceRate.XP_BOOST] or 0) > 0 then
        tooltip = tooltip .. string.format("\n- XP Boost: %d%% (%s h remaining)", ExpRating[ExperienceRate.XP_BOOST],
            formatTimeBySeconds(localPlayer:getStoreExpBoostTime()))
    end
    tooltip = tooltip .. string.format("\n- Stamina multiplier: x%.1f (%s h remaining)", staminaMultiplier / 100,
        formatTimeByMinutes(localPlayer:getStamina() - 2340))

    xpgainrate:setTooltip(tooltip)

    if expRateTotal == 0 then
        widget:setColor("#ff4a4a")
    elseif expRateTotal > 100 then
        widget:setColor("#00cc00")
    elseif expRateTotal < 100 then
        widget:setColor("#ff9429")
    else
        widget:setColor("#ffffff")
    end
end

function onExperienceRateChange(localPlayer, type, value)
    ExpRating[type] = value
    updateExperienceRate(localPlayer)
end

local function setSkillValueWithTooltips(id, value, tooltip, showPercentage, color)
    local skill = skillsWindow:recursiveGetChildById(id)
    if not skill then
        return
    end
    
    -- Check if this stat should be hidden for older client versions
    if g_game.getClientVersion() < 1412 then
        local statsToHide = {
            'skillId7', 'skillId8', 'skillId9', 'skillId10', 'skillId11', 'skillId12', 
            'skillId13', 'skillId14', 'skillId15', 'skillId16', -- offense stats
            'physicalResist', 'fireResist', 'earthResist', 'energyResist', 'IceResist', 
            'HolyResist', 'deathResist', 'HealingResist', 'drowResist', 'lifedrainResist', 
            'manadRainResist', 'defenceValue', 'armorValue', 'mitigation', 'dodge', 
            'damageReflection', -- defense stats
            'momentum', 'transcendence', 'amplification' -- misc stats
        }
        
        for _, statId in pairs(statsToHide) do
            if id == statId then
                skill:hide()
                return
            end
        end
    end
    
    if value and value ~= 0 then
        skill:show()
        local widget = skill:getChildById('value')
        if not widget then
            return
        end
        if color then
            widget:setColor(color)
        end
        if showPercentage then
            local percentValue = math.floor(value * 10000) / 100
            local sign = percentValue > 0 and "+ " or ""
            widget:setText(sign .. percentValue .. "%")
            if percentValue < 0 then
                widget:setColor("#FF9854")
            end
        else
            widget:setText(tostring(value))
        end
        if tooltip then
            skill:setTooltip(tooltip)
        end
    else
        skill:hide()
    end
end

function onFlatDamageHealingChange(localPlayer, flatBonus)
    -- Don't show flat damage/healing stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    local tooltips =
        "This flat bonus is the main source of your character's power, added \nto most of the damage and healing values you cause."
    setSkillValueWithTooltips('damageHealing', flatBonus, tooltips, false)
end

function onAttackInfoChange(localPlayer, attackValue, attackElement)
    -- Don't show attack info stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    local tooltips =
        "This is your character's basic attack power whenever you enter a \nfight with a weapon or your fists. It does not apply to any spells \nyou cast. The attack value is calculated from the weapon's attack\n value, the corresponding weapon skill, combat tactics, the bonus \nreceived from the Revelation Perks and the player's level. The \nvalue represents the average damage you would inflict on a\ncreature which had no kind of defence or protection."
    setSkillValueWithTooltips('attackValue', attackValue, tooltips, false)
    local skill = skillsWindow:recursiveGetChildById("attackValue")
    if skill then
        local element = clientCombat[attackElement]
        if element then
            skill:getChildById('icon'):setImageSource(element.path)
            skill:getChildById('icon'):setImageSize({
                width = 9,
                height = 9
            })
        end
    end
end

function onConvertedDamageChange(localPlayer, convertedDamage, convertedElement)
    -- Don't show converted damage stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    setSkillValueWithTooltips('convertedDamage', convertedDamage, false, true)
    setSkillValueWithTooltips('convertedElement', convertedElement, false, true)
end

function onImbuementsChange(localPlayer, lifeLeech, manaLeech, critChance, critDamage, onslaught)
    -- Don't show imbuement stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    local lifeLeechTooltips =
        "You have a +11.4% chance to trigger Onslaught, granting you 60% increased damage for all attacks."
    local manaLeechTooltips = "You have a +1% chance to cause +1% extra damage."
    local critChanceTooltips =
        "Critical Hits deal more damage than normal attacks. They have a chance to be \ntriggered during combat, inflicting additional damage beyond the standard amount."
    local critDamageTooltips = "You get +1% of the damage dealt as mana"
    local onslaughtTooltips = "You get +1% of the damage dealt as hit points"
    skillsWindow:recursiveGetChildById("criticalHit"):setVisible(true)
    setSkillValueWithTooltips('lifeLeech', lifeLeech, lifeLeechTooltips, true)
    setSkillValueWithTooltips('manaLeech', manaLeech, manaLeechTooltips, true)
    setSkillValueWithTooltips('criticalChance', critChance, critChanceTooltips, true)
    setSkillValueWithTooltips('criticalExtraDamage', critDamage, critDamageTooltips, true)
    setSkillValueWithTooltips('onslaught', onslaught, onslaughtTooltips, true)
end

local combatIdToWidgetId = {
    [0] = "physicalResist",
    [1] = "fireResist",
    [2] = "earthResist",
    [3] = "energyResist",
    [4] = "IceResist",
    [5] = "HolyResist",
    [6] = "deathResist",
    [7] = "HealingResist",
    [8] = "drowResist",
    [9] = "lifedrainResist",
    [10] = "manadRainResist"
}

function onCombatAbsorbValuesChange(localPlayer, absorbValues)
    -- Don't show combat absorb values for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    for id, widgetId in pairs(combatIdToWidgetId) do
        local skill = skillsWindow:recursiveGetChildById(widgetId)
        if skill then
            local value = absorbValues[id]
            if value then
                setSkillValueWithTooltips(widgetId, value, false, true, "#44AD25")
            else
                skill:hide()
            end
        end
    end
end
function onDefenseInfoChange(localPlayer, defense, armor, mitigation, dodge, damageReflection)
    -- Don't show defense stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    skillsWindow:recursiveGetChildById("separadorOnDefenseInfoChange"):setVisible(true)
    local defenseToolstip =
        "When attacked, you have a +9.6% chance to trigger Dodge, which \nwill fully mitigate the damage."
    local armorToolstip =
        "Mitigation reduces most of the damage you take and varies based\non your shielding skill, equipped weapon, chosen combat tactics \nand any mitigation multipliers acquired in your Wheel of Destiny."
    local mitigationToolstip = "This shows how well your armor protects you from all physical\nattacks."
    local dodgetToolstip =
        "This is your protection against all physical attacks in close combat \nas well as all distance physical attacks. The higher the defence value, the less damage you will take from melee physical hits. The defence\n value is calculated from your shield and/or weapon\n defence and the corresponding skill. Careful! \nYour defence value protects you only from hits of two creatures in a single round."
    setSkillValueWithTooltips('defenceValue', defense, defenseToolstip, false)
    setSkillValueWithTooltips('armorValue', armor, armorToolstip, false)
    setSkillValueWithTooltips('mitigation', mitigation, mitigationToolstip, true)
    setSkillValueWithTooltips('dodge', dodge, dodgetToolstip, true)
    setSkillValueWithTooltips('damageReflection', damageReflection, false, true)

end

function onForgeBonusesChange(localPlayer, momentum, transcendence, amplification)
    -- Don't show misc stats for older client versions
    if g_game.getClientVersion() < 1412 then
        return
    end
    
    skillsWindow:recursiveGetChildById("separadorOnForgeBonusesChange"):setVisible(true)
    local momentumTooltip = "During combat, you have a +" .. math.floor(momentum * 10000) / 100 ..
                                "% chance to trigger Momentum\n, which reduces all spell cooldowns by 2 seconds."

    local transcendenceTooltip = "During combat, you have a +" .. math.floor(transcendence * 10000) / 100 ..
                                     "% chance to trigger\nTranscendence, which transforms your character into a vocation-\nspecific avatar for 7 seconds. " ..
                                     "While in this form, you will benefit\nfrom a 15% damage reduction and guaranteed critical hits that \ndeal an additional 15% damage."

    local amplificationTooltip =
        "Effects of tiered items are amplified by +" .. math.floor(amplification * 10000) / 100 .. "%."

    setSkillValueWithTooltips('momentum', momentum, momentumTooltip, true)
    setSkillValueWithTooltips('transcendence', transcendence, transcendenceTooltip, true)
    setSkillValueWithTooltips('amplification', amplification, amplificationTooltip, true)
end
