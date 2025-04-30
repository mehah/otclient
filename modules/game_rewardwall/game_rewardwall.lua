rewardWallController = Controller:new()
-- /*=============================================
-- =            To-do                  =
-- =============================================*/
-- - otui -> html/css g_ui.displayUI 
-- - Improve Ids footerGold2 , footerGold1
-- - fix displayErrorBox
-- - fix onhoverRewardType
-- - add windows warning: no sufficient Instant Reward Access 
-- - add windows confirmation of ussing instant reward access

local ServerPackets = {
    ShowDialog = 0xED,
    DailyRewardCollectionState = 0xDE,
    OpenRewardWall = 0xE2,
    CloseRewardWall = 0xE3,
    DailyRewardBasic = 0xE4,
    DailyRewardHistory = 0xE5
    -- RestingAreaState = 0xA9
}

local ClientPackets = {
    OpenRewardWall = 0xD8,
    OpenRewardHistory = 0xD9,
    SelectReward = 0xDA,
    CollectionResource = 0x14,
    JokerResource = 0x15
}

-- @ widget
local ButtonRewardWall = nil
local windowsPickWindow = nil
local displayGeneralBox2 = nil
local generalBox = nil
-- @ array
local bonuses = {}
local actualUsed = {}
-- @ variable
local bonusShrine = 0
-- @ const
local COLORS = {
    BASE_1 = "#484848",
    BASE_2 = "#414141"
}
local ZONE = {
    LAST_ZONE = -99,
    RESTING_AREA_ZONE = 1,
    ICON_ID = "condition_Rewards",
    NUMERIC_ICON_ID = 30
}

local bundleType = {
    ITEMS = 1,
    PREY = 2,
    XPBOOST = 3
}

local STATUS = {
    COLLECTED = 1,
    ACTIVE = 2,
    LOCKED = 3
}

local OPEN_WINDOWS = {
    BUTTON_WIDGET = 0,
    SHRINE = 1 -- itemClientId = 25802
}

local DailyRewardStatus = { -- sendDailyRewardCollectionState 0xDE ?
    DAILY_REWARD_COLLECTED = 0,
    DAILY_REWARD_NOTCOLLECTED = 1,
    DAILY_REWARD_NOTAVAILABLE = 2
}

local CONST_WINDOWS_BOX = {
    CREATE = 0,
    ALREADY = 1,
    RELEASE = 2,
    CONFIRMATION_IRA = 3,-- IRA = Instant Reward Access
    NO_IRA = 4
}
-- unuse
local RESOURCE_DAILYREWARD_JOKERS = 21
local DAILY_REWARD_SYSTEM_TYPE_ONE = 1
local DAILY_REWARD_SYSTEM_TYPE_TWO = 2



-- /*=============================================
-- =            Local function                  =
-- =============================================*/
local function premiumStatusWindwos(isPremium)
    rewardWallController.ui.premiumStatus.premiumMessage:setText(isPremium and
                                                                     "Great! You benefit from the best possible rewards and bonuses due to your premium status." or
                                                                     "With a Premium account, you would benefit from even better rewards and bonuses.")
    rewardWallController.ui.premiumStatus.premiumButton:setOn(not isPremium)
    rewardWallController.ui.infoPanel.free:setColor(isPremium and "#909090" or "#FFFFFF")
    rewardWallController.ui.infoPanel.premium:setColor(isPremium and "#FFFFFF" or "#909090")
    if isPremium then
        for i, widget in pairs(rewardWallController.ui.restingAreaPanel.bonusIcons:getChildren()) do
            if widget then
                widget:setOn(true)
            end
        end
    end
end

local function convert_timestamp(timestamp)
    return os.date("%Y-%m-%d, %H:%M:%S", timestamp)
end

local function getBonusStrings(bonuses)
    local result = {}
    for _, bonus in ipairs(bonuses) do
        table.insert(result, bonus["name"])
    end
    return table.concat(result, ", ")
end

local function visibleHistory(bool)
    for i, widget in ipairs(rewardWallController.ui:getChildren()) do
        if widget:getId() == "historyPanel" then
            widget:setVisible(bool)
        else
            widget:setVisible(not bool)
        end
        if i == 5 then -- foot
            break
        end
    end
end

local function updateDailyRewards(dayStreakDay, wasDailyRewardTaken)
    local dailyRewardsPanel = rewardWallController.ui.dailyRewardsPanel
    for i = 1, dayStreakDay do
        local rewardWidget = dailyRewardsPanel:getChildById("reward" .. i)
        local rewardArrow = dailyRewardsPanel:getChildById("arrow" .. i)
        if rewardWidget then
            local test = g_ui.createWidget("RewardButton", rewardWidget:getChildById("rewardGold" .. i))
            test:setOn(true)
            test:fill("parent")
            test:setPhantom(true)
            rewardArrow:setImageClip("5 0 5 7")
            rewardWidget:getChildById("rewardButton" .. i):setOn(true)
            rewardWidget:getChildById("rewardButton" .. i).ditherpattern:setVisible(true)
            rewardWidget:getChildById("rewardGold" .. i).status = 1
        end
    end

    local currentReward = dailyRewardsPanel:getChildById("reward" .. dayStreakDay + 1)
    if currentReward then
        local test = g_ui.createWidget("GoldLabel2", currentReward:getChildById("rewardGold" .. dayStreakDay + 1))
        test:setOn(true)
        test:fill("parent")
        test:setPhantom(true)
        test.text:setText(wasDailyRewardTaken)
        if wasDailyRewardTaken < g_game.getLocalPlayer():getResourceBalance(ResourceTypes.DAILYREWARD_STREAK) then
            test.text:setColor("white")
        else
            test.text:setColor("red")
        end
        test.gold:setImageSource("/game_rewardwall/images/icon-daily-reward-joker")
        test.gold:setImageSize("12 12")
        test.gold:setImageOffset("-20 0")
        currentReward:getChildById("rewardGold" .. dayStreakDay + 1).status = 2
        currentReward:setOn(false)
    end

    for i = dayStreakDay + 2, 7 do
        local rewardWidget = dailyRewardsPanel:getChildById("reward" .. i)
        if rewardWidget then
            local test = g_ui.createWidget("RewardButton", rewardWidget:getChildById("rewardGold" .. i))
            test:setOn(false)
            test:fill("parent")
            test:setPhantom(true)
            rewardWidget:getChildById("rewardButton" .. i):setOn(true)
            rewardWidget:getChildById("rewardButton" .. i).ditherpattern:setVisible(true)
            rewardWidget:getChildById("rewardGold" .. i).status = 3
        end
    end
end

local function getDayStreakIcon(dayStreakLevel)
    local IconConsecutiveDays = {
        [24] = "icon-rewardstreak-default",
        [49] = "icon-rewardstreak-bronze",
        [99] = "icon-rewardstreak-silver",
        [100] = "icon-rewardstreak-gold"
    }
    if dayStreakLevel <= 24 then
        return IconConsecutiveDays[24]
    elseif dayStreakLevel <= 49 then
        return IconConsecutiveDays[49]
    elseif dayStreakLevel <= 99 then
        return IconConsecutiveDays[99]
    else
        return IconConsecutiveDays[100]
    end
end

local function getBonusDescription(bonusName, streakCount, activeBonuses)
    local isPremium = g_game.getLocalPlayer():isPremium()

    return string.format(
        "Allow [color=#909090]%s[/color]%s\nThis bonus is active because you are [color=%s]Premium[/color] and reached a reward streak of at least [color=#44AD25]%d[/color].%s",
        bonusName, isPremium and "" or "[color=#ff0000](Locked)[/color]", isPremium and "#44AD25" or "#ff0000",
        streakCount, isPremium and ("\n\nActive bonuses: [color=#909090]%s[/color]."):format(activeBonuses) or "")
end

local function closeGeneralBoxError()
    if displayGeneralBox2 then
        displayGeneralBox2:destroy()
        displayGeneralBox2 = nil
    end
end

local function checkRewards(data)
    for index, reward in ipairs(data) do
        local hasSelectableItems = reward.selectableItems and next(reward.selectableItems) ~= nil
        local rewardButton = rewardWallController.ui.dailyRewardsPanel:getChildById("reward" .. index):getChildById(
            "rewardButton" .. index)
        local iconWidget = rewardWallController.ui.dailyRewardsPanel:getChildById("reward" .. index):getChildByIndex(1)

        if hasSelectableItems then
            iconWidget:setIcon("game_rewardwall/images/icon-reward-pickitems")
            rewardButton.bundleType = bundleType.ITEMS
            rewardButton.rewardItem = reward.selectableItems
            rewardButton.getMaxUsed = reward.itemsToSelect
        elseif reward.bundleItems[1].bundleType == 3 then
            iconWidget:setIcon("game_rewardwall/images/icon-reward-xpboost")
            rewardButton.bundleType = bundleType.XPBOOST
        else
            iconWidget:setIcon("game_rewardwall/images/icon-reward-fixeditems")
            rewardButton.bundleType = bundleType.PREY
        end
    end
end
-- /*=============================================
-- =            onParse                  =
-- =============================================*/
--[[
--  0xDE ??
local function onDailyRewardCollectionState(state)
    if not rewardWallController.ui:isVisible() then
        return
    end

    local text = {
        [DailyRewardStatus.DAILY_REWARD_COLLECTED] = "you did not claim your daily reward in time. too bad, you do not have enough Daily Reward Jokers.",
        [DailyRewardStatus.DAILY_REWARD_NOTCOLLECTED] = "You did not claim your daily reward in time. If you don't claim your reward now, your [color=#D33C3C]streak will be reset.[/color]",
        [DailyRewardStatus.DAILY_REWARD_NOTAVAILABLE] ="idk",
    }
    rewardWallController.ui.restingAreaPanel.streakWarning:parseColoredText(text[state],"#c0c0c0")
end 
]]

local function onRestingAreaState(zone, state, message)
    if ZONE.LAST_ZONE == zone then
        return
    end
    ZONE.LAST_ZONE = zone
    local gameInterface = modules.game_interface
    if zone == ZONE.RESTING_AREA_ZONE then
        gameInterface.processIcon(ZONE.NUMERIC_ICON_ID, function(icon)
            icon:setTooltip(message)
        end, true)
    else
        gameInterface.processIcon(ZONE.ICON_ID, function(icon)
            icon:destroy()
        end)
    end
end

local function onDailyReward(data)
    bonuses = data.bonuses
    checkRewards(g_game.getLocalPlayer():isPremium() and data.premiumRewards or data.freeRewards)
end

local function onServerError(code, error)
    closeGeneralBoxError()
    displayGeneralBox2 = displayGeneralBox(rewardWallController.ui:getText(), error, {
        {
            text = tr('ok'),
            callback = closeGeneralBoxError
        },
        anchor = 50
    }, closeGeneralBoxError, closeGeneralBoxError)
end

local function connectOnServerError()
    connect(g_game, {
        onServerError = onServerError
    })
end

local function disconnectOnServerError()
    disconnect(g_game, {
        onServerError = onServerError
    })
end

local function onOpenRewardWall(bonusShrine, nextRewardTime, dayStreakDay, wasDailyRewardTaken, errorMessage, tokens,
    timeLeft, dayStreakLevel)
    if bonusShrine == OPEN_WINDOWS.SHRINE then
        toggle()
    end
    bonusShrine = bonusShrine
    updateDailyRewards(dayStreakDay, wasDailyRewardTaken)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.rewardStreakIcon:setText(dayStreakLevel)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.timeLeft:setText(
        (timeLeft == 0 and "Expired") or (timeLeft == 90001 and "< 1 min") or timeLeft)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.restingAreaGold.text:setText(tokens)
    rewardWallController.ui.footerPanel.footerGold1.text:setText(tokens)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.rewardStreakIcon:setImageSource(
        "/game_rewardwall/images/" .. getDayStreakIcon(dayStreakLevel))

    rewardWallController.ui.footerPanel.footerGold2.text:setText(
        g_game.getLocalPlayer():getResourceBalance(ResourceTypes.DAILYREWARD_STREAK))
end

local function onRewardHistory(rewardHistory)
    local transferHistory = rewardWallController.ui.historyPanel.historyList.List
    transferHistory:destroyChildren()

    local headerRow = g_ui.createWidget("historyData2", transferHistory)
    headerRow:setBackgroundColor("#363636")
    headerRow:setBorderColor("#00000077")
    headerRow:setBorderWidth(1)
    headerRow.date:setText("Date")
    headerRow.Balance:setText("Streak")
    headerRow.Description:setText("Event")

    for i, data in ipairs(rewardHistory) do
        local row = g_ui.createWidget("historyData2", transferHistory)
        row:setHeight(30)
        row.date:setText(convert_timestamp(data[1]))
        row.Balance:setText(data[4])
        row.Description:setText(data[3])
        row.Description:setTextWrap(true)
        row:setBackgroundColor(i % 2 == 0 and "#ffffff12" or "#00000012")
    end
end

-- /*=============================================
-- =            Windows                  =
-- =============================================*/
local function show()
    if not rewardWallController.ui then
        return
    end
    g_game.sendOpenRewardWall()
    rewardWallController.ui:show()
    rewardWallController.ui:raise()
    rewardWallController.ui:focus()
    connectOnServerError()
    premiumStatusWindwos(g_game.getLocalPlayer():isPremium())
end

local function hide()
    if not rewardWallController.ui then
        return
    end
    rewardWallController.ui:hide()
    if not windowsPickWindow then
        disconnectOnServerError()
    end
end

function toggle()
    if not rewardWallController.ui then
        return
    end
    if rewardWallController.ui:isVisible() then

        return hide()
    end
    show()
end

local function fixCssIncompatibility() -- temp
    rewardWallController.ui:centerIn('parent') -- mainWindows to the center of the screen
    rewardWallController.ui.historyPanel.historyList:fill('parent')

    -- note: I don't know how to edit children in css
    local restingAreaGold = rewardWallController.ui.restingAreaPanel.restingAreaInfo.restingAreaGold
    restingAreaGold.gold:setImageSource("/game_rewardwall/images/icon-daily-reward-joker")
    restingAreaGold.gold:setImageSize("12 12")
    restingAreaGold.gold:setImageOffset("-30 0")

    local footerGold1 = rewardWallController.ui.footerPanel.footerGold1
    footerGold1.gold:setImageSource("/game_rewardwall/images/icon-daily-reward-joker")
    footerGold1.gold:setImageSize("11 11")
    footerGold1.gold:setImageOffset("-3 0")
    footerGold1.text:setTextAlign(AlignRightCenter)

    local footerGold2 = rewardWallController.ui.footerPanel.footerGold2
    footerGold2.gold:setImageSource("/game_rewardwall/images/instant-reward-access-icon")
    footerGold2.gold:setImageSize("12 12")
    footerGold2.gold:setImageOffset("-5 0")
end
-- /*=============================================
-- =            Controller                  =
-- =============================================*/
function rewardWallController:onInit()
    g_ui.importStyle("styles/style.otui")
    rewardWallController:loadHtml('game_rewardwall.html')
    rewardWallController.ui:hide()

    rewardWallController:registerEvents(g_game, {
        onOpenRewardWall = onOpenRewardWall,
        onDailyReward = onDailyReward,
        onRewardHistory = onRewardHistory,
        onRestingAreaState = onRestingAreaState
        -- onDailyRewardCollectionState
    })
    fixCssIncompatibility()
end

function rewardWallController:onTerminate()
    if ButtonRewardWall then
        ButtonRewardWall:destroy()
        ButtonRewardWall = nil
    end
    if windowsPickWindow then
        windowsPickWindow:destroy()
        windowsPickWindow = nil
    end
    if generalBox then
        generalBox:destroy()
        generalBox = nil
    end
    closeGeneralBoxError()
end

function rewardWallController:onGameStart()
    if g_game.getClientVersion() > 1140 then -- Summer Update 2017
        ButtonRewardWall = modules.game_mainpanel.addToggleButton("rewardWall", tr("Open rewardWall"),
            "/images/options/rewardwall", toggle, false, 20)
    end
end

function rewardWallController:onGameEnd()
    if rewardWallController.ui:isVisible() then
        rewardWallController.ui:hide()
    end
    if windowsPickWindow then
        windowsPickWindow:destroy()
        windowsPickWindow = nil
    end
    if generalBox then
        generalBox:destroy()
        generalBox = nil
    end
    closeGeneralBoxError()
end
-- /*=============================================
-- =            Call css onClick                =
-- =============================================*/
function rewardWallController:onClickshowHistory()
    visibleHistory(not rewardWallController.ui.historyPanel:isVisible())
    g_game.requestOpenRewardHistory()
end

function rewardWallController:onClickToggle()
    toggle()
end

function rewardWallController:onClickSendStoreRewardWall()
    modules.game_store.toggle()
    g_game.sendRequestStorePremiumBoost()
end

function rewardWallController:onClickbuyInstantRewardAccess()
    modules.game_store.toggle()
    g_game.sendRequestUsefulThings(StoreConst.InstantRewardAccess)
end

function rewardWallController:onClickDisplayWindowsPickRewardWindow(event)
    if event.target:isOn() then
        return
    end

    if event.target.bundleType == bundleType.ITEMS then
        if not windowsPickWindow then
            windowsPickWindow = g_ui.displayUI('styles/pickreward')
            windowsPickWindow:show()
            windowsPickWindow:getChildById('capacity'):setText("Free capacity: " ..
                                                                   g_game:getLocalPlayer():getFreeCapacity() .. " oz")

            local text = string.format("You have selected [color=#D33C3C]0[/color] of %d reward items",
                event.target.getMaxUsed)
            windowsPickWindow:getChildById('rewardLabel'):parseColoredText(text, "#c0c0c0")

            for i, item in pairs(event.target.rewardItem) do
                local getItem = g_ui.createWidget('ItemReward', windowsPickWindow:getChildById('rewardList'))
                getItem:getChildById('item'):setItemId(item.itemId)
                getItem:getChildById('title'):setText(item.name)
                getItem:setBackgroundColor((i % 2 == 0) and COLORS.BASE_1 or COLORS.BASE_2)
                getItem.totalWeight = item.weight
                getItem.getMaxUsed = event.target.getMaxUsed
            end
            actualUsed = {}
            toggle()
        else
            windowsPickWindow:show()
            windowsPickWindow:raise()
            windowsPickWindow:focus()
        end

    elseif event.target.bundleType == bundleType.XPBOOST or event.target.bundleType == bundleType.PREY then
        managerMessageBoxWindow(0)
    end
end

-- /*=============================================
-- =            Call onHover css                  =
-- =============================================*/

function rewardWallController:onhoverBonus(event)
    if not event.value then
        rewardWallController.ui.infoPanel:setText("")
        return
    end

    local id = event.target:getId()
    local index = tonumber(id:match("%d+"))
    local bonus = bonuses[index]

    if not bonus then
        rewardWallController.ui.infoPanel:setText("Unknown bonus.")
        return
    end

    local isPremium = g_game.getLocalPlayer():isPremium()
    local bonusText = string.format(
        "Allow [color=#909090]%s[/color]%s\nThis bonus is active because you are [color=%s]Premium[/color] and reached a reward streak of at least [color=#44AD25]%d[/color].%s",
        bonus.name, isPremium and "" or "[color=#ff0000](Locked)[/color]", isPremium and "#44AD25" or "#ff0000",
        bonus.id,
        isPremium and ("\n\nActive bonuses: [color=#909090]%s[/color]."):format(getBonusStrings(bonuses)) or "")

    rewardWallController.ui.infoPanel:parseColoredText(bonusText)
end

function rewardWallController:onhoverStatusPlayer(event)
    if not event.value then
        rewardWallController.ui.infoPanel:setText("")
        return
    end

    local playerStatus = {
        rewardStreakIcon = "This explains the reward streak system. You need to claim your daily reward between regular server saves to maintain your streak. At a streak of 2+, your character gets resting area bonuses. Free accounts can reach a maximum bonus at streak level 3, while premium players can reach higher levels. Characters on the same account share the streak.",
        timeLeft = "This is an urgent notification to claim your daily reward within one minute (before the next server save) to raise your reward streak by 1. It mentions that 3 Daily Reward Jokers will be used to prevent resetting your streak. It also encourages raising your streak to benefit from bonuses in resting areas.",
        restingAreaGold = "This explains how Daily Reward Jokers work. They help you maintain your streak on days when you can't claim your daily reward. Each character receives one Daily Reward Joker on the first day of each month. The message recommends collecting rewards daily to stay safe."
    }

    local DEFAULT_MESSAGE = "Unknown bonus."

    local id = event.target:getId()
    local info = playerStatus[id]
    rewardWallController.ui.infoPanel:parseColoredText(info or DEFAULT_MESSAGE)
end

function rewardWallController:onhoverRewardType(event)
    if not event.value then
        rewardWallController.ui.infoPanel.free:setText("")
        rewardWallController.ui.infoPanel.premium:setText("")
        return
    end
    -- TODO fix this
    local test = event.target.getMaxUsed or 1
    local rewardTexts = {
        [bundleType.ITEMS] = {
            free = string.format(
                "Reward for Free Accounts:\nPick %d items from the list. Among\nother items it contains: health\npotion, a fire bomb rune, a\nthundestorm rune",
                tonumber(test / 2)),
            premium = string.format(
                "Reward for Premium Accounts:\nPick %d items from the list. Among\nother items it contains: health\npotion, a fire bomb rune, a\nthundestorm rune.",
                tonumber(test))
        },
        [bundleType.PREY] = {
            free = "Reward for Free Accounts:\n * 1x Prey Wildcard",
            premium = "Reward for Premium Accounts:\n * 2x Prey Wildcard"
        },
        [bundleType.XPBOOST] = {
            free = "Reward for Free Accounts:\n * 10 minutes 50% XP Boost",
            premium = "Reward for Premium Accounts:\n * 30 minutes 50% XP Boost"
        }
    }

    local targetBundle = rewardTexts[event.target.bundleType]
    if targetBundle then
        rewardWallController.ui.infoPanel.free:setText(targetBundle.free)
        rewardWallController.ui.infoPanel.premium:setText(targetBundle.premium)
    else
        rewardWallController.ui.infoPanel.free:setText("")
        rewardWallController.ui.infoPanel.premium:setText("")
    end
end

function rewardWallController:onhoverStatusReward(event)
    local statusReward = {
        [STATUS.COLLECTED] = "You have already collected this daily reward.\nThe daily rewards follow a specific cycle where each day you claim it, you get another reward. The cycle repeats after 7 claimed rewards. You will be able to claim this daily reward again as soon as you have reached this postion in the next cycle.",
        [STATUS.ACTIVE] = "The daily reward can be claimed now.\nIf you claim this reward now, it will cost you one Instant Reward Access.\nGet your daily reward for free by visiting a reward shrine.\nYou did not claim your daily reward in time.\nToo bad, you do not have enough Daily Reward Jokers.",
        [STATUS.LOCKED] = "This daily reward is still locked.\nFirst collect the previous daily rewards of this cycle."
    }
    if not event.value then
        rewardWallController.ui.infoPanel:setText("")
        return
    end
    rewardWallController.ui.infoPanel:setText(statusReward[event.target.status])
end

-- /*=============================================
-- =            Auxiliar Windows pickReward      =
-- =============================================*/

function onClickBtnOk()
    if table.empty(actualUsed) then
        return
    end
    g_game.requestGetRewardDaily(bonusShrine, actualUsed)
end

function destroyPickReward()
    if windowsPickWindow then
        windowsPickWindow:destroy()
        windowsPickWindow = nil
    end
    toggle()
end

function onTextChangeChangeNumber(getPanel)
    if not getPanel.getMaxUsed then
        return
    end

    local alreadyUsed = 0
    local itemId = getPanel:getChildById('item'):getItemId()
    local thisPanelUsed = actualUsed[itemId] or 0

    for _, count in pairs(actualUsed) do
        alreadyUsed = alreadyUsed + (count or 0)
    end

    local numberField = getPanel:getChildById('number')
    local currentValue = tonumber(numberField:getText()) or 0
    local maxAllowed = getPanel.getMaxUsed - (alreadyUsed - thisPanelUsed)

    if currentValue > maxAllowed then
        numberField:setText(maxAllowed)
    end
    actualUsed[itemId] = tonumber(numberField:getText()) or 0
    alreadyUsed = 0
    for _, count in pairs(actualUsed) do
        alreadyUsed = alreadyUsed + (count or 0)
    end
    local color = alreadyUsed == 0 and "#D33C3C" or "#00FF00"
    windowsPickWindow:getChildById('btnOk'):setEnabled(alreadyUsed > 0)

    local text = string.format("You have selected [color=%s]%d[/color] of %d reward items", color, alreadyUsed,
        getPanel.getMaxUsed)
    windowsPickWindow:getChildById('rewardLabel'):parseColoredText(text)
end

-- /*=============================================
-- =            Auxiliar GeneralBox             =
-- =============================================*/

function displayGeneralBox(title, message, buttons, onEnterCallback, onEscapeCallback)
    if not generalBox then
        generalBox = g_ui.createWidget('MessageBoxWindow', rootWidget)
    else
        local holder = generalBox:getChildById('holder')
        if holder then
            holder:destroyChildren()
        end
    end
    local titleWidget = generalBox:getChildById('title')
    if titleWidget then
        titleWidget:setText(title)
    end
    local content = generalBox:getChildById('content')
    if content then
        content:setText(message)
        content:resizeToText()
    end
    local holder = generalBox:getChildById('holder')
    if holder then
        for i = 1, #buttons do
            local button = g_ui.createWidget('Button', holder)
            button:setId(buttons[i].text:lower():gsub(" ", "_"))
            button:setText(buttons[i].text)
            button:setWidth(math.max(86, 10 + (string.len(buttons[i].text) * 8)))
            button:setHeight(20)

            if i == 1 then
                button:addAnchor(AnchorTop, 'parent', AnchorTop)
                button:addAnchor(AnchorRight, 'parent', AnchorRight)
            else
                button:addAnchor(AnchorTop, 'parent', AnchorTop)
                button:addAnchor(AnchorRight, 'prev', AnchorLeft)
                button:setMarginRight(5)
            end
            button.onClick = buttons[i].callback
        end
    end
    if onEnterCallback then
        generalBox.onEnter = onEnterCallback
    end
    if onEscapeCallback then
        generalBox.onEscape = onEscapeCallback
    end
    local contentWidth = content:getWidth() + 32
    local contentHeight = content:getHeight() + 42 + holder:getHeight()
    generalBox:setWidth(math.min(916, math.max(116, contentWidth)))
    generalBox:setHeight(math.min(616, math.max(56, contentHeight)))
    generalBox.setContent = function(self, newMessage)
        content:setText(newMessage)
        content:resizeToText()
        local contentWidth = content:getWidth() + 32
        local contentHeight = content:getHeight() + 42 + holder:getHeight()
        self:setWidth(math.min(916, math.max(116, contentWidth)))
        self:setHeight(math.min(616, math.max(56, contentHeight)))
    end
    generalBox.setTitle = function(self, newTitle)
        titleWidget:setText(newTitle)
    end
    generalBox.modifyButton = function(self, buttonId, newText, newCallback)
        local button = holder:getChildById(buttonId)
        if button then
            if newText then
                button:setText(newText)
                button:setWidth(math.max(86, 10 + (string.len(newText) * 8)))
            end
            if newCallback then
                disconnect(button, {
                    onClick = button.onClick
                })
                connect(button, {
                    onClick = newCallback
                })
                button.onClick = newCallback
            end
        end
        return button
    end
    generalBox:show()
    generalBox:raise()
    generalBox:focus()
    return generalBox
end

function managerMessageBoxWindow(id)
    if id == CONST_WINDOWS_BOX.CREATE then
        generalBox = displayGeneralBox("test", "¿test?", {{
            text = "ok",
            callback = function()
                print("test1")
            end
        }, {
            text = "cancel",
            callback = function()
                print("test2")
            end
        }})
    elseif id == CONST_WINDOWS_BOX.ALREADY then
        generalBox:setTitle("Warning")
        generalBox:setContent("Sorry, you have already taken you daily reward or you are unable to collect it")
        generalBox:modifyButton("ok", "ok", function()
            print("test3")
            generalBox:destroy()
        end)
        generalBox:modifyButton("cancel", "cancel", function()
            print("test4")
            generalBox:destroy()
        end)
    elseif id == CONST_WINDOWS_BOX.RELEASE then
        generalBox:setTitle("Info")
        generalBox:setContent("You have already collected your daily reward. ")
        generalBox:modifyButton("ok", "ok", function()
            print("test5")
            generalBox:destroy()
        end)
        generalBox:modifyButton("cancel", "cancel", function()
            print("test6")
            generalBox:destroy()
        end)
    elseif id == CONST_WINDOWS_BOX.CONFIRMATION_IRA then
        generalBox:setTitle("Confirmation of using Instant Reward Access")
        generalBox:setContent(
            "Remember! You can always collect your daily reward for free by visition a reward shrine!\n You Currently own 3x Instant Reward Access. Do you really want to use one to claim your daily reward now? ")
        generalBox:modifyButton("ok", "ok", function()
            print("test7")
            generalBox:destroy()
        end)
        generalBox:modifyButton("cancel", "cancel", function()
            print("test8")
            generalBox:destroy()
        end)
    elseif id == CONST_WINDOWS_BOX.NO_IRA then
        generalBox:setTitle("Warning: No Sufficient Instant Reward Access")
        generalBox:setContent(
            "Remember! you can always collect your daily reward for free by visiting a reward shrine!\nyou do not have an instant Reward Access. \nvisit the store to buy more! ")
        generalBox:modifyButton("ok", "ok", function()
            print("test9")
            generalBox:destroy()
        end)
        generalBox:modifyButton("cancel", "cancel", function()
            print("test10")
            generalBox:destroy()
        end)
    end
end
