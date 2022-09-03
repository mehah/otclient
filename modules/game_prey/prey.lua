-- sponsored by kivera-global.com
-- remade by Vithrax#5814
Prey = {}
preyWindow = nil
preyButton = nil
local preyTrackerButton
local msgWindow
local bankGold = 0
local inventoryGold = 0
local rerollPrice = 0
local bonusRerolls = 0

local PREY_BONUS_DAMAGE_BOOST = 0
local PREY_BONUS_DAMAGE_REDUCTION = 1
local PREY_BONUS_XP_BONUS = 2
local PREY_BONUS_IMPROVED_LOOT = 3
local PREY_BONUS_NONE = 4

local PREY_ACTION_LISTREROLL = 0
local PREY_ACTION_BONUSREROLL = 1
local PREY_ACTION_MONSTERSELECTION = 2
local PREY_ACTION_REQUEST_ALL_MONSTERS = 3
local PREY_ACTION_CHANGE_FROM_ALL = 4
local PREY_ACTION_LOCK_PREY = 5

local preyDescription = {}

function bonusDescription(bonusType, bonusValue, bonusGrade)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'Damage bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'Damage reduction bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'XP bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Loot bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_DAMAGE_BOOST then
        return '-'
    end
    return 'Unknown bonus'
end

function timeleftTranslation(timeleft, forPreyTimeleft) -- in seconds
    if timeleft == 0 then
        if forPreyTimeleft then
            return tr('infinite bonus')
        end
        return tr('Free')
    end
    local hours = string.format('%02.f', math.floor(timeleft / 3600))
    local mins = string.format('%02.f', math.floor(timeleft / 60 - (hours * 60)))
    return hours .. ':' .. mins
end

function init()
    connect(g_game, {
        onGameStart = check,
        onGameEnd = hide,
        onResourcesBalanceChange = Prey.onResourcesBalanceChange,
        onPreyFreeRerolls = onPreyFreeRerolls,
        onPreyTimeLeft = onPreyTimeLeft,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyLocked = onPreyLocked,
        onPreyInactive = onPreyInactive,
        onPreyActive = onPreyActive,
        onPreySelection = onPreySelection,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
        onPreyListSelection = onPreyListSelection,
        onPreyWildcardSelection = onPreyWildcardSelection
    })

    preyWindow = g_ui.displayUI('prey')
    preyWindow:hide()
    preyTracker = g_ui.createWidget('PreyTracker', modules.game_interface.getRightPanel())
    preyTracker:setup()
    preyTracker:setContentMaximumHeight(100)
    preyTracker:setContentMinimumHeight(47)
    preyTracker:hide()
    if g_game.isOnline() then
        check()
    end
    setUnsupportedSettings()
end

local descriptionTable = {
    ['shopPermButton'] = 'Go to the Store to purchase the Permanent Prey Slot. Once you have completed the purchase, you can activate a prey here, no matter if your character is on a free or a Premium account.',
    ['shopTempButton'] = 'You can activate this prey whenever your account has Premium Status.',
    ['preyWindow'] = '',
    ['noBonusIcon'] = 'This prey is not available for your character yet.\nCheck the large blue button(s) to learn how to unlock this prey slot',
    ['selectPrey'] = 'Click here to get a bonus with a higher value. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot. Your prey will be active for 2 hours hunting time again. Your prey creature will stay the same.',
    ['pickSpecificPrey'] = 'Available only for protocols 12+',
    ['rerollButton'] = 'If you like to select another prey crature, click here to get a new list with 9 creatures to choose from.\nThe newly selected prey will be active for 2 hours hunting time again.',
    ['preyCandidate'] = 'Select a new prey creature for the next 2 hours hunting time.',
    ['choosePreyButton'] = 'Click on this button to confirm selected monsters as your prey creature for the next 2 hours hunting time.'
}

function onHover(widget)
    if type(widget) == 'string' then
        return preyWindow.description:setText(descriptionTable[widget])
    elseif type(widget) == 'number' then
        local slot = 'slot' .. (widget + 1)
        local tracker = preyTracker.contentsPanel[slot]
        local desc = tracker.time:getTooltip()
        desc = desc:sub(1, desc:len() - 46)
        return preyWindow.description:setText(desc)
    end
    if widget:isVisible() then
        local id = widget:getId()
        local desc = descriptionTable[id]
        if desc then
            preyWindow.description:setText(desc)
        end
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = check,
        onGameEnd = hide,
        onResourcesBalanceChange = Prey.onResourcesBalanceChange,
        onPreyFreeRerolls = onPreyFreeRerolls,
        onPreyTimeLeft = onPreyTimeLeft,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyLocked = onPreyLocked,
        onPreyInactive = onPreyInactive,
        onPreyActive = onPreyActive,
        onPreySelection = onPreySelection,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
        onPreyListSelection = onPreyListSelection,
        onPreyWildcardSelection = onPreyWildcardSelection
    })

    if preyButton then
        preyButton:destroy()
    end
    if preyTrackerButton then
        preyTrackerButton:destroy()
    end
    preyWindow:destroy()
    preyTracker:destroy()
    if msgWindow then
        msgWindow:destroy()
        msgWindow = nil
    end
end

local n = 0
function setUnsupportedSettings()
    local t = {'slot1', 'slot2', 'slot3'}
    for i, slot in pairs(t) do
        local panel = preyWindow[slot]
        for j, state in pairs({panel.active, panel.inactive}) do
            state.select.price.text:setText('-------')
        end
        panel.active.autoRerollPrice.text:setText('-')
        panel.active.lockPreyPrice.text:setText('-')
        panel.active.choose.price.text:setText(1)
        panel.active.autoReroll.autoRerollCheck:disable()
        panel.active.lockPrey.lockPreyCheck:disable()
    end
end

function check()
    if g_game.getFeature(GamePrey) then
        if not preyButton then
            preyButton = modules.client_topmenu.addRightGameToggleButton('preyButton', tr('Prey Dialog'),
                                                                         '/images/topbuttons/prey_window', toggle)
        end
        if not preyTrackerButton then
            preyTrackerButton = modules.client_topmenu.addRightGameToggleButton('preyTrackerButton', tr('Prey Tracker'),
                                                                                '/images/topbuttons/prey', toggleTracker)
        end
    elseif preyButton then
        preyButton:destroy()
        preyButton = nil
    end
end

function toggleTracker()
    if preyTracker:isVisible() then
        preyTracker:hide()
    else
        preyTracker:show()
    end
end

function hide()
    preyWindow:hide()
    if msgWindow then
        msgWindow:destroy()
        msgWindow = nil
    end
end

function show()
    if not g_game.getFeature(GamePrey) then
        return hide()
    end
    preyWindow:show()
    preyWindow:raise()
    preyWindow:focus()
    g_game.preyRequest() -- update preys, it's for tibia 12
end

function toggle()
    if preyWindow:isVisible() then
        return hide()
    end
    show()
end

function onPreyFreeRerolls(slot, timeleft)
    local prey = preyWindow['slot' .. (slot + 1)]
    local percent = (timeleft / (20 * 60)) * 100
    local desc = timeleftTranslation(timeleft * 60)
    if not prey then
        return
    end
    for i, panel in pairs({prey.active, prey.inactive}) do
        local progressBar = panel.reroll.button.time
        local price = panel.reroll.price.text
        progressBar:setPercent(percent)
        progressBar:setText(desc)
        if timeleft == 0 then
            price:setText('0')
        end
    end
end

function onPreyTimeLeft(slot, timeLeft)
    -- description
    preyDescription[slot] = preyDescription[slot] or {
        one = '',
        two = ''
    }
    local text = preyDescription[slot].one .. timeleftTranslation(timeLeft, true) .. preyDescription[slot].two
    -- tracker
    local percent = (timeLeft / (2 * 60 * 60)) * 100
    slot = 'slot' .. (slot + 1)
    local tracker = preyTracker.contentsPanel[slot]
    tracker.time:setPercent(percent)
    tracker.time:setTooltip(text)
    for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
        element:setTooltip(text)
        element.onClick = function()
            show()
        end
    end
    -- main window
    local prey = preyWindow[slot]
    if not prey then
        return
    end
    local progressbar = prey.active.creatureAndBonus.timeLeft
    local desc = timeleftTranslation(timeLeft, true)
    progressbar:setPercent(percent)
    progressbar:setText(desc)
end

function onPreyRerollPrice(price)
    rerollPrice = price
    local t = {'slot1', 'slot2', 'slot3'}
    for i, slot in pairs(t) do
        local panel = preyWindow[slot]
        for j, state in pairs({panel.active, panel.inactive}) do
            local price = state.reroll.price.text
            local progressBar = state.reroll.button.time
            if progressBar:getText() ~= 'Free' then
                price:setText(comma_value(rerollPrice))
            else
                price:setText('0')
                progressBar:setPercent(0)
            end
        end
    end
end

function setTimeUntilFreeReroll(slot, timeUntilFreeReroll) -- minutes
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    local percent = (timeUntilFreeReroll / (20 * 60)) * 100
    local desc = timeleftTranslation(timeUntilFreeReroll * 60)
    for i, panel in pairs({prey.active, prey.inactive}) do
        local reroll = panel.reroll.button.time
        reroll:setPercent(percent)
        reroll:setText(desc)
        local price = panel.reroll.price.text
        if timeUntilFreeReroll > 0 then
            price:setText(comma_value(rerollPrice))
        else
            price:setText('Free')
        end
    end
end

function onPreyLocked(slot, unlockState, timeUntilFreeReroll, wildcards)
    -- tracker
    slot = 'slot' .. (slot + 1)
    local tracker = preyTracker.contentsPanel[slot]
    if tracker then
        tracker:hide()
        preyTracker:setContentMaximumHeight(preyTracker:getHeight() - 20)
    end
    -- main window
    local prey = preyWindow[slot]
    if not prey then
        return
    end
    prey.title:setText('Locked')
    prey.inactive:hide()
    prey.active:hide()
    prey.locked:show()
end

function onPreyInactive(slot, timeUntilFreeReroll, wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton:setImageSource('/images/game/prey/prey_reroll_blocked')
    rerollButton:disable()
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
end

function setBonusGradeStars(slot, grade)
    local prey = preyWindow['slot' .. (slot + 1)]
    local gradePanel = prey.active.creatureAndBonus.bonus.grade

    gradePanel:destroyChildren()
    for i = 1, 10 do
        if i <= grade then
            local widget = g_ui.createWidget('Star', gradePanel)
            widget.onHoverChange = function(widget, hovered)
                onHover(slot)
            end
        else
            local widget = g_ui.createWidget('NoStar', gradePanel)
            widget.onHoverChange = function(widget, hovered)
                onHover(slot)
            end
        end
    end
end

function getBigIconPath(bonusType)
    local path = '/images/game/prey/'
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return path .. 'prey_bigdamage'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return path .. 'prey_bigdefense'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return path .. 'prey_bigxp'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return path .. 'prey_bigloot'
    end
end

function getSmallIconPath(bonusType)
    local path = '/images/game/prey/'
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return path .. 'prey_damage'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return path .. 'prey_defense'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return path .. 'prey_xp'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return path .. 'prey_loot'
    end
end

function getBonusDescription(bonusType)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'Damage Boost'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'Damage Reduction'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'XP Bonus'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Improved Loot'
    end
end

function getTooltipBonusDescription(bonusType, bonusValue)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'You deal +' .. bonusValue .. '% extra damage against your prey creature.'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'You take ' .. bonusValue .. '% less damage from your prey creature.'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'Killing your prey creature rewards +' .. bonusValue .. '% extra XP.'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Your creature has a +' .. bonusValue .. '% chance to drop additional loot.'
    end
end

function capitalFormatStr(str)
    local formatted = ''
    str = string.split(str, ' ')
    for i, word in ipairs(str) do
        formatted = formatted .. ' ' .. (string.gsub(word, '^%l', string.upper))
    end
    return formatted:trim()
end

function onItemBoxChecked(widget)

    for i, slot in pairs({'slot1', 'slot2', 'slot3'}) do
        local list = preyWindow[slot].inactive.list:getChildren()
        if table.find(list, widget) then
            for i, child in pairs(list) do
                if child ~= widget then
                    child:setChecked(false)
                end
            end
        end
    end
    widget:setChecked(true)
end

function onPreyActive(slot, currentHolderName, currentHolderOutfit, bonusType, bonusValue, bonusGrade, timeLeft,
                      timeUntilFreeReroll, wildcards) -- locktype always 0 for protocols <12
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    currentHolderName = capitalFormatStr(currentHolderName)
    local percent = (timeLeft / (2 * 60 * 60)) * 100
    if tracker then
        tracker.creature:show()
        tracker.noCreature:hide()
        tracker.creatureName:setText(currentHolderName)
        tracker.creature:setOutfit(currentHolderOutfit)
        tracker.preyType:setImageSource(getSmallIconPath(bonusType))
        tracker.time:setPercent(percent)
        preyDescription[slot] = preyDescription[slot] or {}
        preyDescription[slot].one = 'Creature: ' .. currentHolderName .. '\nDuration: '
        preyDescription[slot].two =
            '\nValue: ' .. bonusGrade .. '/10' .. '\nType: ' .. getBonusDescription(bonusType) .. '\n' ..
                getTooltipBonusDescription(bonusType, bonusValue) .. '\n\nClick in this window to open the prey dialog.'
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip(preyDescription[slot].one .. timeleftTranslation(timeLeft, true) ..
                                   preyDescription[slot].two)
            element.onClick = function()
                show()
            end
        end
    end
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    prey.inactive:hide()
    prey.locked:hide()
    prey.active:show()
    prey.title:setText(currentHolderName)
    local creatureAndBonus = prey.active.creatureAndBonus
    creatureAndBonus.creature:setOutfit(currentHolderOutfit)
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    creatureAndBonus.bonus.icon:setImageSource(getBigIconPath(bonusType))
    creatureAndBonus.bonus.icon.onHoverChange = function(widget, hovered)
        onHover(slot)
    end
    setBonusGradeStars(slot, bonusGrade)
    creatureAndBonus.timeLeft:setPercent(percent)
    creatureAndBonus.timeLeft:setText(timeleftTranslation(timeLeft))
    -- bonus reroll
    prey.active.choose.selectPrey.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_BONUSREROLL, 0)
    end
    -- creature reroll
    prey.active.reroll.button.rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
end

function onPreySelection(slot, names, outfits, timeUntilFreeReroll, wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    local prey = preyWindow['slot' .. (slot + 1)]
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    prey.title:setText(tr('Select monster'))
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
    local list = prey.inactive.list
    list:destroyChildren()
    for i, name in ipairs(names) do
        local box = g_ui.createWidget('PreyCreatureBox', list)
        name = capitalFormatStr(name)
        box:setTooltip(name)
        box.creature:setOutfit(outfits[i])
    end
    prey.inactive.choose.choosePreyButton.onClick = function()
        for i, child in pairs(list:getChildren()) do
            if child:isChecked() then
                return g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, i - 1)
            end
        end
        return showMessage(tr('Error'), tr('Select monster to proceed.'))
    end
end

function onPreySelectionChangeMonster(slot, names, outfits, bonusType, bonusValue, bonusGrade, timeUntilFreeReroll,
                                      wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    local prey = preyWindow['slot' .. (slot + 1)]
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    prey.title:setText(tr('Select monster'))
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
    local list = prey.inactive.list
    list:destroyChildren()
    for i, name in ipairs(names) do
        local box = g_ui.createWidget('PreyCreatureBox', list)
        name = capitalFormatStr(name)
        box:setTooltip(name)
        box.creature:setOutfit(outfits[i])
    end
    prey.inactive.choose.choosePreyButton.onClick = function()
        for i, child in pairs(list:getChildren()) do
            if child:isChecked() then
                return g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, i - 1)
            end
        end
        return showMessage(tr('Error'), tr('Select monster to proceed.'))
    end
end

function onPreyListSelection(slot, races, nextFreeReroll, wildcards)
end

function onPreyWildcardSelection(slot, races, nextFreeReroll, wildcards)
end

function Prey.onResourcesBalanceChange(balance, oldBalance, type)
    if type == ResourceTypes.BANK_BALANCE then -- bank gold
        bankGold = balance
    elseif type == ResourceTypes.GOLD_EQUIPPED then -- inventory gold
        inventoryGold = balance
    elseif type == ResourceTypes.PREY_WILDCARDS then -- bonus rerolls
        bonusRerolls = balance
    end
    local player = g_game.getLocalPlayer()
    g_logger.debug('' .. tostring(type) .. ', ' .. tostring(balance))
    if player then
        preyWindow.wildCards:setText(tostring(player:getResourceBalance(ResourceTypes.PREY_WILDCARDS)))
        preyWindow.gold:setText(comma_value(player:getTotalMoney()))
    end
end

function showMessage(title, message)
    if msgWindow then
        msgWindow:destroy()
    end

    msgWindow = displayInfoBox(title, message)
    msgWindow:show()
    msgWindow:raise()
    msgWindow:focus()
end
