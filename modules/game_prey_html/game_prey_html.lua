PreyController = Controller:new()
PreyController.showEqualizerEffect = true

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
local PREY_ACTION_OPTION = 5
local PREY_OPTION_UNTOGGLE = 0
local PREY_OPTION_TOGGLE_AUTOREROLL = 1
local PREY_OPTION_TOGGLE_LOCK_PREY = 2

local SLOT_STATE_LOCKED = 0
local SLOT_STATE_INACTIVE = 1
local SLOT_STATE_ACTIVE = 2
local SLOT_STATE_SELECTION = 3
local SLOT_STATE_SELECTION_CHANGE_MONSTER = 4
local SLOT_STATE_LIST_SELECTION = 5

function PreyController:handleResources()
    g_game.preyRequest()

    local player = g_game.getLocalPlayer()
    if not player then return end
    self.rawPlayerGold = player:getTotalMoney() or 0
    self.playerGold = comma_value(self.rawPlayerGold)
    self.wildcards = player:getResourceBalance(ResourceTypes.PREY_WILDCARDS)
end

function show()
    PreyController:handleResources()
    PreyController:loadHtml('prey_html.html')
    PreyController.ui:show()
    PreyController.ui:raise()
    PreyController.ui:focus()
    PreyController:scheduleEvent(function()
        PreyController.ui:centerIn('parent')
    end, 1, "LazyHtml")
end

function toggle()
    g_logger.info("TOGGLE PREY DIALOG")
    if PreyController.ui and PreyController.ui:isVisible() then
        PreyController:hide()
    else
        show()
    end
end

function PreyController:hide()
    if PreyController.ui then
        PreyController:unloadHtml()
    end
end

PreyController.preyData = {
    { previewMonster = { raceId = nil, outfit = nil }, slotId = 0, monsterName = "Hydra", raceId = 34, rerollCost = "197 k", pickCost = "5", bonusCost = "1", autoRerollCost = "1", lockCost = "5", preyType = "/images/game/prey/prey_bigxp.png",     stars = 5 },
    { previewMonster = { raceId = nil, outfit = nil }, slotId = 1, monsterName = "Hydra", raceId = 34, rerollCost = "197 k", pickCost = "5", bonusCost = "1", autoRerollCost = "1", lockCost = "5", preyType = "/images/game/prey/prey_bigdamage.png", stars = 3 },
    { previewMonster = { raceId = nil, outfit = nil }, slotId = 2, monsterName = "Hydra", raceId = 34, rerollCost = "197 k", pickCost = "5", bonusCost = "1", autoRerollCost = "1", lockCost = "5", preyType = "/images/game/prey/prey_bigloot.png",   stars = 10 },
}
preyTrackerButton = nil
preyButton = nil

function PreyController:onHover(slotId, isHovered)
    g_logger.info("onHover: " .. slotId)
    -- if not isHovered then
    --     self.description = "-"
    --     return
    -- end
    self.description = PreyController.preyData[slotId + 1].description
end

function check()
    g_logger.info("check")
    if g_game.getFeature(GamePrey) then
        if not preyButton then
            g_logger.info("adding prey button")
            preyButton = modules.game_mainpanel.addToggleButton('preyButton', tr('Prey Dialog'),
                '/images/options/button_preydialog', toggle)
        end
        -- if not preyTrackerButton then
        --     preyTrackerButton = modules.game_mainpanel.addToggleButton('preyTrackerButton', tr('Prey Tracker'),
        --         '/images/options/button_prey', toggleTracker)
        -- end
    elseif preyButton then
        g_logger.info("removing prey button")
        preyButton:destroy()
        preyButton = nil
    end
end

function PreyController:init()
    g_logger.info("init")
    PreyController:handleResources()
    check()

    connect(g_game, {
        onPreyActive = onPreyActive,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyListSelection = onPreyListSelection,
        onPreySelection = onPreySelection,
        onPreyInactive = onPreyInactive,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
        onPreyLocked = onPreyLocked,
    })
end

local Helper = {}

function Helper.handleFormatPrice(price)
    local priceText = "Free"
    if price > 0 then
        if price >= 1000000 then
            local millions = math.floor(price / 1000000)
            local remainder = price % 1000000
            if remainder >= 500000 then
                priceText = string.format('%d.5 M', millions)
            elseif remainder >= 100000 then
                priceText = string.format('%d M', millions)
            else
                priceText = string.format('%d M', math.max(1, millions))
            end
        elseif price >= 100000 then
            local thousands = math.floor(price / 1000)
            local remainder = price % 1000
            if remainder >= 500 then
                priceText = string.format('%d.5 k', thousands)
            elseif remainder >= 100 then
                priceText = string.format('%d k', thousands)
            else
                priceText = string.format('%d k', math.max(1, thousands))
            end
        else
            priceText = tostring(price)
        end
    end

    return priceText
end

local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function round(x) return math.floor(x + 0.5) end
Helper.freeRerollBarWidth = 60
Helper.freeRerollHours = 20
Helper.activePreyBarWidth = 205
Helper.activePreyHours = 2
function Helper.getProgress(timeleft, hours, maxWidth)
    if timeleft == 0 then return 0 end
    local total = hours * 60 * 60
    timeleft = timeleft > total and 0 or timeleft
    local width = clamp((timeleft / total) * maxWidth, 0, maxWidth)

    return round(width)
end

function onPreyLocked(slot, unlockState, timeUntilFreeReroll, wildcards)
    local slotId = slot + 1
    PreyController.preyData[slotId].type = SLOT_STATE_LOCKED
    PreyController.preyData[slotId].stars = 0
    PreyController.preyData[slotId].monsterName = "Locked"
    PreyController.preyData[slotId].preyType = getBigIconPath(nil, true)
end

function Helper.fillTinyMonsterList(slotId, names, outfits)
    local raceList = {}

    for i = 1, 9 do
        table.insert(raceList, {
            name = names[i],
            outfit = outfits[i],
            raceId = outfits[i].type,
            slotId = slotId,
            index = i,
        })
    end

    return raceList
end

function onPreySelectionChangeMonster(slot, names, outfits, bonusType, bonusValue, bonusGrade, timeUntilFreeReroll,
                                      wildcards, option)
    g_logger.info(("SLOT_STATE_SELECTION_CHANGE_MONSTER > Slot %d, timeUntilFreeReroll %d, wildcards %d, monsterNames %d, monsterLookTypes %d")
        :format(slot, timeUntilFreeReroll,
            wildcards, #names, #outfits))

    -- slot, monsterNames, monsterLooktypes, nextFreeReroll, wildcards


    local slotId = slot + 1
    PreyController.preyData[slotId].raceList = Helper.fillTinyMonsterList(slot, names, outfits)

    -- local description = ("Creature %s\nDuration %s\nValue: %d/10\nType: %s\n%s\n\nClick in this window to open the prey dialog.")
    --     :format(
    --         currentHolderName,
    --         timeleft,
    --         bonusGrade,
    --         getBonusDescription(bonusType),
    --         getTooltipBonusDescription(bonusType, bonusValue)
    --     )


    PreyController.preyData[slotId].slotId = slot
    PreyController.preyData[slotId].monsterName = "Select your prey creature"
    PreyController.preyData[slotId].type = SLOT_STATE_SELECTION_CHANGE_MONSTER
    timeUntilFreeReroll = timeUntilFreeReroll > 720000 and 0 or timeUntilFreeReroll
    PreyController.preyData[slotId].percentFreeReroll = Helper.getProgress(timeUntilFreeReroll, Helper.freeRerollHours,
        Helper.freeRerollBarWidth)
    PreyController.preyData[slotId].timeUntilFreeReroll = timeleftTranslation(timeUntilFreeReroll)
    PreyController.preyData[slotId].isFreeReroll = timeUntilFreeReroll == 0
    PreyController.preyData[slotId].disableFreeReroll = PreyController.rawRerollGoldPrice > PreyController.rawPlayerGold
end

function onPreyInactive(slot, timeUntilFreeReroll, wildcards)
    g_logger.info("SLOT_STATE_INACTIVE > Slot " ..
        slot .. ", timeUntilFreeReroll " .. timeUntilFreeReroll .. ", wildcards " .. wildcards)
end

function onPreyRerollPrice(rerollGoldPrice, rerollBonusPrice, pickSpecificPrice)
    rerollGoldPrice = rerollGoldPrice or 0
    pickSpecificPrice = pickSpecificPrice or 5
    PreyController.rawRerollGoldPrice = rerollGoldPrice or 0
    PreyController.rerollGoldPrice = Helper.handleFormatPrice(rerollGoldPrice)
    PreyController.rerollBonusPrice = rerollBonusPrice or 1
    PreyController.pickSpecificPrice = pickSpecificPrice
    PreyController.lockPreyPrice = pickSpecificPrice
end

local function buildRaceEntry(raceId, slotId, index)
    local raceData = g_things.getRaceData(raceId)
    local name = raceData and raceData.name or nil

    if name and name ~= '' then
        name = capitalFormatStr(name)
    else
        name = string.format('Unknown Creature (%d)', raceId)
    end

    local outfit = raceData and raceData.outfit or nil
    local realSize

    if outfit and outfit.type then
        local creatureType = g_things.getThingType(outfit.type, ThingCategoryCreature)
        realSize = creatureType and creatureType:getRealSize() or nil
    end

    return {
        raceId = raceId,
        name = name,
        searchName = name:lower(),
        outfit = outfit,
        realSize = realSize,
        slotId = slotId,
        index = index,
        selected = false,
    }
end

function PreyController:handleSelect(slot, race)
    PreyController.preyData[slot + 1].previewMonster = {
        raceId = race.raceId,
        outfit = race.outfit,
        name = race.name,
        index = race.index
    }
    self.preyData[slot + 1].monsterName = ("Selected: %s"):format(race.name)

    for i = 1, #self.preyData[slot + 1].raceList do
        if self.preyData[slot + 1].raceList[i].raceId == race.raceId then
            self.preyData[slot + 1].raceList[i].selected = true
        else
            self.preyData[slot + 1].raceList[i].selected = false
        end
    end
end

-- a unique table for all debounce timers in the module
PreyController._debounceTimers = PreyController._debounceTimers or {}

-- simple key-based debounce utility
function PreyController:debounce(key, waitMs, fn)
    waitMs = waitMs or 300
    local t = self._debounceTimers[key]
    if t then removeEvent(t) end
    self._debounceTimers[key] = scheduleEvent(function()
        self._debounceTimers[key] = nil
        fn()
    end, waitMs)
end

-- clear timers on terminate to prevent leaks
function PreyController:terminate()
    disconnect(g_game, {
        onPreyActive = onPreyActive,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyListSelection = onPreyListSelection,
        onPreySelection = onPreySelection,
        onPreyInactive = onPreyInactive,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
    })

    if self._debounceTimers then
        for _, ev in pairs(self._debounceTimers) do
            if ev then removeEvent(ev) end
        end
        self._debounceTimers = {}
    end

    if preyButton then
        preyButton:destroy()
        preyButton = nil
    end
    if preyTrackerButton then
        preyTrackerButton:destroy()
        preyTrackerButton = nil -- to be safely garbage collected
    end

    if self.ui then
        self:unloadHtml()
    end
end

function PreyController:onSearchMonster(value, slot)
    value = value or ''
    g_logger.info("onSearchMonster: " .. slot .. " value: " .. value .. ' length: ' .. #value)

    if true then return end
    PreyController.preyData[slot + 1].previewMonster = {
        raceId = nil, outfit = nil
    }
    self.preyData[slot + 1].monsterName = "Select your prey creature"
    local raceListOriginal = self.preyData[slot + 1].raceListOriginal

    if #value <= 0 then
        self.preyData[slot + 1].searchValue = false
        local k = 'search:' .. tostring(slot)
        local t = self._debounceTimers[k]
        if t then
            removeEvent(t); self._debounceTimers[k] = nil
        end

        local out = {}
        for i = 1, math.min(50, #raceListOriginal) do
            table.insert(out, raceListOriginal[i])
        end
        self.preyData[slot + 1].raceList = out
        self.preyData[slot + 1].clearButton = false
        return
    end
    self.preyData[slot + 1].searchValue = true
    self:debounce('search:' .. tostring(slot), 300, function()
        local searchValue = value:lower()
        local filtered = {}
        for _, race in ipairs(raceListOriginal) do
            local name = (race.name or ''):lower()
            if name:find(searchValue, 1, true) then
                table.insert(filtered, race)
            end
        end
        self.preyData[slot + 1].raceList = filtered
    end)
end

function onPreyListSelection(slot, raceList, nextFreeReroll, wildcards)
    g_logger.info(("SLOT_STATE_LIST_SELECTION > Slot %d, nextFreeReroll %d, wildcards %d"):format(slot, nextFreeReroll,
        wildcards))

    local slotId = slot + 1
    PreyController.preyData[slotId].raceList = {}
    PreyController.preyData[slotId].raceListOriginal = {}
    for i, raceId in ipairs(raceList) do
        local race = buildRaceEntry(raceId, slot, i)
        table.insert(PreyController.preyData[slotId].raceListOriginal, race)
    end

    table.sort(PreyController.preyData[slotId].raceListOriginal, function(a, b)
        return a.name < b.name
    end)

    for i = 1, #PreyController.preyData[slotId].raceListOriginal do
        local data = PreyController.preyData[slotId].raceListOriginal[i]
        data.index = i
        if i <= 50 then -- show only first 50 initially to not LAG UI
            table.insert(PreyController.preyData[slotId].raceList, data)
        end
    end

    PreyController.preyData[slotId].slotId = slot
    PreyController.preyData[slotId].monsterName = "Select your prey creature"
    PreyController.preyData[slotId].type = SLOT_STATE_LIST_SELECTION
    PreyController:handleResources()
end

function onPreySelection(slot, names, outfits, timeUntilFreeReroll, wildcards)
    g_logger.info(("SLOT_STATE_SELECTION > Slot %d, nextFreeReroll %d, wildcards %d, monsterNames %d, monsterLookTypes %d")
        :format(slot, timeUntilFreeReroll,
            wildcards, #names, #outfits))
    local slotId = slot + 1


    -- local description = ("Creature %s\nDuration %s\nValue: %d/10\nType: %s\n%s\n\nClick in this window to open the prey dialog.")
    --     :format(
    --         currentHolderName,
    --         timeleft,
    --         bonusGrade,
    --         getBonusDescription(bonusType),
    --         getTooltipBonusDescription(bonusType, bonusValue)
    --     )

    timeUntilFreeReroll = timeUntilFreeReroll > 720000 and 0 or timeUntilFreeReroll
    PreyController.preyData[slotId].raceList = Helper.fillTinyMonsterList(slot, names, outfits)
    PreyController.preyData[slotId].monsterName = "Select your prey creature"
    PreyController.preyData[slotId].slotId = slot
    PreyController.preyData[slotId].percentFreeReroll = Helper.getProgress(timeUntilFreeReroll, Helper.freeRerollHours,
        Helper.freeRerollBarWidth)
    PreyController.preyData[slotId].timeUntilFreeReroll = timeleftTranslation(timeUntilFreeReroll)
    PreyController.preyData[slotId].type = SLOT_STATE_SELECTION
    PreyController.preyData[slotId].monsterName = "Select your prey creature"
    PreyController.preyData[slotId].isFreeReroll = timeUntilFreeReroll == 0
    PreyController.preyData[slotId].disableFreeReroll = PreyController.rawRerollGoldPrice > PreyController.rawPlayerGold
end

function PreyController:onGameStart()
    if g_game.getClientVersion() >= 1149 then
        check()
    else
        PreyController:scheduleEvent(function()
            g_modules.getModule("game_prey_html"):unload()
        end, 100, "unloadModule")
    end
    g_logger.info("onGameStart")
end

function capitalFormatStr(str)
    local formatted = ''
    str = string.split(str, ' ')
    for i, word in ipairs(str) do
        formatted = formatted .. ' ' .. (string.gsub(word, '^%l', string.upper))
    end
    return formatted:trim()
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

function timeleftTranslation(timeleft)
    if timeleft == 0 then
        return "Free"
    end
    local hours = string.format('%02.f', math.floor(timeleft / 3600))
    local mins = string.format('%02.f', math.floor(timeleft / 60 - (hours * 60)))
    return hours .. ':' .. mins
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

PreyController.description = "-"

function getBigIconPath(bonusType, locked)
    local path = '/images/game/prey/'

    if locked then
        return path .. 'prey_bignobonus'
    end

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

function onPreyActive(slot, currentHolderName, currentHolderOutfit, bonusType, bonusValue, bonusGrade, rawTimeleft,
                      rawTimeUntilFreeReroll, wildcards, option)
    local slotId = slot + 1
    local timeleft = timeleftTranslation(rawTimeleft)
    rawTimeUntilFreeReroll = rawTimeUntilFreeReroll > 720000 and 0 or rawTimeUntilFreeReroll

    local description = ("Creature %s\nDuration %s\nValue: %d/10\nType: %s\n%s\n\nClick in this window to open the prey dialog.")
        :format(
            currentHolderName,
            timeleft,
            bonusGrade,
            getBonusDescription(bonusType),
            getTooltipBonusDescription(bonusType, bonusValue)
        )

    PreyController.preyData[slotId].slotId = slot
    PreyController.preyData[slotId].monsterName = capitalFormatStr(currentHolderName)
    PreyController.preyData[slotId].raceId = currentHolderOutfit.type
    PreyController.preyData[slotId].outfit = currentHolderOutfit
    PreyController.preyData[slotId].autoReroll = option == 1
    PreyController.preyData[slotId].lockPrey = option == 2
    PreyController.preyData[slotId].description = description
    PreyController.preyData[slotId].stars = bonusGrade
    PreyController.preyData[slotId].percent = Helper.getProgress(rawTimeleft, Helper.activePreyHours,
        Helper.activePreyBarWidth)
    PreyController.preyData[slotId].percentFreeReroll = Helper.getProgress(rawTimeUntilFreeReroll, Helper
        .freeRerollHours,
        Helper.freeRerollBarWidth)
    PreyController.preyData[slotId].timeleft = timeleft
    PreyController.preyData[slotId].type = SLOT_STATE_ACTIVE
    PreyController.preyData[slotId].preyType = getBigIconPath(bonusType)
    PreyController.preyData[slotId].timeUntilFreeReroll = timeleftTranslation(rawTimeUntilFreeReroll)
    PreyController:handleResources()
    PreyController.preyData[slotId].isFreeReroll = rawTimeUntilFreeReroll == 0
    PreyController.preyData[slotId].disableFreeReroll = PreyController.rawRerollGoldPrice >
        PreyController.rawPlayerGold
end

local lastOnMouseWheel = 0
function PreyController:onMouseWheel(slotId)
    if self.preyData[slotId + 1].searchValue then return end
    if os.clock() < lastOnMouseWheel then return end
    lastOnMouseWheel = os.clock() + 0.5


    local currentRaceList = PreyController.preyData[slotId + 1].raceList
    local originalRaceList = PreyController.preyData[slotId + 1].raceListOriginal

    if #currentRaceList >= #originalRaceList then return end
    -- every time the scroll happens, add + 5
    local currentCount = #currentRaceList
    local toAdd = 5
    for i = currentCount + 1, math.min(currentCount + toAdd, #originalRaceList) do
        local data = originalRaceList[i]
        data.index = i
        table.insert(currentRaceList, data)
    end
end

local confirmWindow
local function showPreyConfirmationWindow(title, description, confirmAction, afterCloseAction, cancelAction)
    -- toggle()


    local function closeWindow()
        if cancelAction and type(cancelAction) == "function" then
            cancelAction()
        end
        if confirmWindow then
            confirmWindow:destroy()
            confirmWindow = nil
            PreyController:handleResources()
            -- toggle()
            if afterCloseAction then
                afterCloseAction()
                afterCloseAction = nil
            end
        end
    end
    if confirmWindow then
        closeWindow()
    end

    local function confirm()
        if confirmAction then
            confirmAction()
        end
        closeWindow()
    end

    confirmWindow = displayGeneralBox(tr(title), description, {
        {
            text = tr('No'),
            callback = closeWindow
        },
        {
            text = tr('Yes'),
            callback = confirm
        },
    }, confirm, closeWindow)

    if confirmWindow then
        confirmWindow.onDestroy = function()
            PreyController:handleResources()
            if afterCloseAction then
                afterCloseAction()
                afterCloseAction = nil
            end
        end
    else
        -- toggle()
        PreyController:handleResources()
        if afterCloseAction then
            afterCloseAction()
            afterCloseAction = nil
        end
    end
end

function PreyController:handleRerollBonus(slotId)
    local description = tr(string.format(
        'Are you sure you want to use %s of your remaining %s Prey Wildcards?',
        self.rerollBonusPrice, self.wildcards
    ))

    local shouldRestoreWindow = self.ui and self.ui:isVisible()
    if shouldRestoreWindow then
        self:hide()
    end

    local function restorePreyWindow()
        if shouldRestoreWindow then
            show()
        end
    end

    showPreyConfirmationWindow('Confirmation of Using Prey Wildcards', description, function()
        g_game.preyAction(slotId, PREY_ACTION_BONUSREROLL, 0)
    end, restorePreyWindow)
end

function PreyController:handlePickSpecific(slotId)
    local description = tr(string.format(
        'Are you sure you want to use %s of your remaining %s Prey Wildcards?',
        self.pickSpecificPrice, self.wildcards
    ))

    local shouldRestoreWindow = self.ui and self.ui:isVisible()
    if shouldRestoreWindow then
        self:hide()
    end

    local function restorePreyWindow()
        if shouldRestoreWindow then
            show()
        end
    end

    showPreyConfirmationWindow('Confirmation of Using Prey Wildcards', description, function()
        g_game.preyAction(slotId, PREY_ACTION_REQUEST_ALL_MONSTERS, 0)
    end, restorePreyWindow)
end

function PreyController:openStore(offerId)
    if self.ui and self.ui:isVisible() then
        self:hide()
    end

    -- offerId = 0 > Permanent slot
    -- offerId = 1 > wildcards

    modules.game_mainpanel.toggleStore()
    PreyController:scheduleEvent(function()
        g_game.sendRequestUsefulThings(offerId)
    end, 25, "LazyHtml")
end

function PreyController:onChooseMonster(slotId)
    local slot = self.preyData[slotId + 1]
    local previewMonster = slot.previewMonster
    if not previewMonster or not previewMonster.raceId then return end

    if slot.type == SLOT_STATE_LIST_SELECTION then
        g_game.preyAction(slotId, PREY_ACTION_CHANGE_FROM_ALL, previewMonster.raceId)
    elseif slot.type == SLOT_STATE_SELECTION or slot.type == SLOT_STATE_SELECTION_CHANGE_MONSTER then
        g_game.preyAction(slotId, PREY_ACTION_MONSTERSELECTION, previewMonster.index - 1)
    end
end

function PreyController:listReroll(slotId)
    local slot = self.preyData[slotId + 1]

    local description = ""

    if slot.timeUntilFreeReroll == "Free" then
        description = "Are you sure you want to use the Free List Reroll?"
    else
        description = string.format(
            "Do you want to spend %s gold for a List Reroll?\nYou currently have %s gold available for the purchase.",
            comma_value(self.rawRerollGoldPrice),
            self.playerGold
        )
    end

    local shouldRestoreWindow = self.ui and self.ui:isVisible()
    if shouldRestoreWindow then
        self:hide()
    end

    local function restorePreyWindow()
        if shouldRestoreWindow then
            show()
        end
    end

    showPreyConfirmationWindow('Confirmation of Using List Reroll', description, function()
        g_game.preyAction(slotId, PREY_ACTION_LISTREROLL, 0)
    end, restorePreyWindow)
end

function PreyController:autoOptions(slotId, option)
    local field = ""
    if option == PREY_OPTION_TOGGLE_AUTOREROLL then
        field = "autoReroll"
    else
        field = "lockPrey"
    end

    if self.preyData[slotId + 1][field] then
        self.preyData[slotId + 1][field] = false
        g_game.preyAction(slotId, PREY_ACTION_OPTION, PREY_OPTION_UNTOGGLE)
        return
    end

    local description = ""

    if option == PREY_OPTION_TOGGLE_AUTOREROLL then
        description = string.format(
            "Do you want to enable the Automatic Bonus Reroll?\nEach time the Automatic Bonus Reroll is triggered, %d of your Prey Wildcards will be consumed.",
            self.rerollBonusPrice, self.wildcards)
    elseif option == PREY_OPTION_TOGGLE_LOCK_PREY then
        description = string.format(
            "Do you want to enable the Lock Prey?\nEach time the Lock Prey is triggered, %d of your Prey Wildcards will be consumed.",
            self.lockPreyPrice, self.wildcards)
    end

    local shouldRestoreWindow = self.ui and self.ui:isVisible()
    if shouldRestoreWindow then
        self:hide()
    end

    local function restorePreyWindow()
        if shouldRestoreWindow then
            show()
        end
    end

    showPreyConfirmationWindow('Confirmation of Using List Reroll', description, function()
        self.preyData[slotId + 1][field] = not self.preyData[slotId + 1][field]

        if self.preyData[slotId + 1][field] then
            if field == "autoReroll" then
                self.preyData[slotId + 1]["lockPrey"] = false
            else
                self.preyData[slotId + 1]["autoReroll"] = false
            end
        end
        g_game.preyAction(slotId, PREY_ACTION_OPTION, option)
    end, restorePreyWindow, function()
        self.preyData[slotId + 1][field] = self.preyData[slotId + 1][field]
    end)
end
