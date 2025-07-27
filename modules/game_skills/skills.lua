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
        local widget = skill:getChildById('value')
        widget:setTooltip(value)
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
end

function online()
    skillsWindow:setupOnStart() -- load character window configuration
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

    update()
    updateHeight()
end

function updateHeight()
    local maximumHeight = 8 -- margin top and bottom

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
    skillsWindow:setContentMinimumHeight(44)
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
    if player.lastExps ~= nil then
        player.expSpeed = (currentExp - player.lastExps[1][1]) / (currentTime - player.lastExps[1][2])
        onLevelChange(player, player:getLevel(), player:getLevelPercent())
    else
        player.lastExps = {}
    end
    table.insert(player.lastExps, {currentExp, currentTime})
    if #player.lastExps > 30 then
        table.remove(player.lastExps, 1)
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
end

function onLevelChange(localPlayer, value, percent)
    setSkillValue('level', comma_value(value))
    local text = tr('You have %s percent to go', 100 - percent) .. '\n' ..
                     tr('%s of experience left', expToAdvance(localPlayer:getLevel(), localPlayer:getExperience()))

    if localPlayer.expSpeed ~= nil then
        local expPerHour = math.floor(localPlayer.expSpeed * 3600)
        if expPerHour > 0 then
            local nextLevelExp = expForLevel(localPlayer:getLevel() + 1)
            local hoursLeft = (nextLevelExp - localPlayer:getExperience()) / expPerHour
            local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft)) * 60)
            hoursLeft = math.floor(hoursLeft)
            text = text .. '\n' .. tr('%s of experience per hour', comma_value(expPerHour))
            text = text .. '\n' .. tr('Next level in %d hours and %d minutes', hoursLeft, minutesLeft)
        end
    end

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
local function updateExperienceRate()
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
    if not xpgainrate then return end
    
    local widget = xpgainrate:getChildById("value")
    if not widget then return end
    
    widget:setText(math.floor(expRateTotal) .. "%")
    
    local tooltip = string.format("Your current XP gain rate amounts to %d%%.", math.floor(expRateTotal))
    tooltip = tooltip .. string.format("\nYour XP gain rate is calculated as follows:\n- Base XP gain rate %d%%", baseRate)
    
    if (ExpRating[ExperienceRate.VOUCHER] or 0) > 0 then
        tooltip = tooltip .. string.format("\n- Voucher: %d%%", ExpRating[ExperienceRate.VOUCHER])
    end
    
    if (ExpRating[ExperienceRate.XP_BOOST] or 0) > 0 then
        tooltip = tooltip .. string.format("\n- XP Boost: %d%% (h remaining)", ExpRating[ExperienceRate.XP_BOOST])
    end
    
    tooltip = tooltip .. string.format("\n- Stamina multiplier: x%.1f (h remaining)", staminaMultiplier / 100)
    
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
    updateExperienceRate()
end

   
local function setSkillValueTest(id, value, tooltip, showPercentage, color)
    local skill = skillsWindow:recursiveGetChildById(id)
    if not skill then return end
    if value and value ~= 0 then
        skill:show()
        local widget = skill:getChildById('value')
        if not widget then return end
        if color then
            widget:setColor(color)
        end
        if showPercentage then
            local percentValue = math.floor(value * 10000) / 100
            local sign = percentValue > 0 and "+ " or ""
            widget:setText(sign .. percentValue .. "%")
            if percentValue < 0  then
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
    local tooltips = "This flat bonus is the main source of your character's power, added \nto most of the damage and healing values you cause."
    setSkillValueTest('damageHealing', flatBonus, tooltips, false)
end

function onAttackInfoChange(localPlayer , attackValue, attackElement)
    local  tooltips = "This is your character's basic attack power whenever you enter a \nfight with a weapon or your fists. It does not apply to any spells \nyou cast. The attack value is calculated from the weapon's attack\n value, the corresponding weapon skill, combat tactics, the bonus \nreceived from the Revelation Perks and the player's level. The \nvalue represents the average damage you would inflict on a\ncreature which had no kind of defence or protection."
    setSkillValueTest('attackValue', attackValue, tooltips, false)
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

function onConvertedDamageChange(localPlayer , convertedDamage, convertedElement)
    setSkillValueTest('convertedDamage', convertedDamage, false, true)
    setSkillValueTest('convertedElement', convertedElement, false, true) --unTest
end

function onImbuementsChange(localPlayer, lifeLeech, manaLeech, critChance, critDamage, onslaught)
    local lifeLeechTooltips =
        "You have a +11.4% chance to trigger Onslaught, granting you 60% increased damage for all attacks."
    local manaLeechTooltips = "You have a +1% chance to cause +1% extra damage."
    local critChanceTooltips =
        "Critical Hits deal more damage than normal attacks. They have a chance to be \ntriggered during combat, inflicting additional damage beyond the standard amount."
    local critDamageTooltips = "You get +1% of the damage dealt as mana"
    local onslaughtTooltips = "You get +1% of the damage dealt as hit points"
    skillsWindow:recursiveGetChildById("criticalHit"):setVisible(true)
    setSkillValueTest('lifeLeech', lifeLeech, lifeLeechTooltips, true)
    setSkillValueTest('manaLeech', manaLeech, manaLeechTooltips, true)
    setSkillValueTest('criticalChance', critChance, critChanceTooltips, true)
    setSkillValueTest('criticalExtraDamage', critDamage, critDamageTooltips, true)
    setSkillValueTest('onslaught', onslaught, onslaughtTooltips, true)


end


local combatIdToWidgetId = {
    [0] = "physicalResist", [1] = "fireResist", [2] = "earthResist",
    [3] = "energyResist",   [4] = "IceResist",  [5] = "HolyResist",
    [6] = "deathResist",    [7] = "HealingResist", [8] = "drowResist",
    [9] = "lifedrainResist",[10] = "manadRainResist"
  }
  
  function onCombatAbsorbValuesChange(localPlayer, absorbValues)
    for id, widgetId in pairs(combatIdToWidgetId) do
      local skill = skillsWindow:recursiveGetChildById(widgetId)
      if skill then
        local value = absorbValues[id]
        if value then
          setSkillValueTest(widgetId, value, false, true,"#44AD25")
        else
          skill:hide()
        end
      end
    end
  end
function onDefenseInfoChange(localPlayer , defense, armor, mitigation, dodge, damageReflection)
    skillsWindow:recursiveGetChildById("separadorOnDefenseInfoChange"):setVisible(true)
    local defenseToolstip = "When attacked, you have a +9.6% chance to trigger Dodge, which \nwill fully mitigate the damage."
    local armorToolstip = "Mitigation reduces most of the damage you take and varies based\non your shielding skill, equipped weapon, chosen combat tactics \nand any mitigation multipliers acquired in your Wheel of Destiny."
    local mitigationToolstip = "This shows how well your armor protects you from all physical\nattacks."
    local dodgetToolstip = "This is your protection against all physical attacks in close combat \nas well as all distance physical attacks. The higher the defence value, the less damage you will take from melee physical hits. The defence\n value is calculated from your shield and/or weapon\n defence and the corresponding skill. Careful! \nYour defence value protects you only from hits of two creatures in a single round."
    setSkillValueTest('defenceValue', defense,defenseToolstip, false)
    setSkillValueTest('armorValue', armor,armorToolstip, false)
    setSkillValueTest('mitigation', mitigation,mitigationToolstip, true)
    setSkillValueTest('dodge', dodge,dodgetToolstip, true)
    setSkillValueTest('damageReflection', damageReflection,false, true)
    

end
function onForgeBonusesChange(localPlayer, momentum, transcendence, amplification)
    print(1)
    skillsWindow:recursiveGetChildById("separadorOnForgeBonusesChange"):setVisible(true)
    local momentumTooltip = "During combat, you have a +" .. math.floor(momentum * 10000) / 100 .. 
                           "% chance to trigger Momentum\n, which reduces all spell cooldowns by 2 seconds."
    
    local transcendenceTooltip = "During combat, you have a +" .. math.floor(transcendence * 10000) / 100 .. 
                                "% chance to trigger\nTranscendence, which transforms your character into a vocation-\nspecific avatar for 7 seconds. " ..
                                "While in this form, you will benefit\nfrom a 15% damage reduction and guaranteed critical hits that \ndeal an additional 15% damage."
    
    local amplificationTooltip = "Effects of tiered items are amplified by +" .. math.floor(amplification * 10000) / 100 .. "%."
    

    setSkillValueTest('momentum', momentum, momentumTooltip, true)
    setSkillValueTest('transcendence', transcendence, transcendenceTooltip, true)
    setSkillValueTest('amplification', amplification, amplificationTooltip, true) 
end
