rewardWallController = Controller:new()
-- /*=============================================
-- =            To-do                  =
-- =============================================*/
-- - Button
-- - Windows reward potions
-- - store medalla
-- - buy premium
-- - cpp : SelectReward
-- - improve Ids

local ServerPackets = {
    ShowDialog = 0xED, -- universal
    DailyRewardCollectionState = 0xDE, -- undone
    OpenRewardWall = 0xE2, -- Done
    CloseRewardWall = 0xE3, -- is it necessary?
    DailyRewardBasic = 0xE4, -- Done
    DailyRewardHistory = 0xE5 -- Done
    -- RestingAreaState = 0xA9 -- Moved to cpp
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
-- @ array
local bonuses = {}
-- @ variable
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
local RESOURCE_DAILYREWARD_STREAK = 20
local RESOURCE_DAILYREWARD_JOKERS = 21

local DAILY_REWARD_SYSTEM_TYPE_ONE = 1
local DAILY_REWARD_SYSTEM_TYPE_TWO = 2

-- /*=============================================
-- =            Local function                  =
-- =============================================*/
local function premiumStatusWindwos(isPremium)
    rewardWallController.ui.premiumStatus.premiumButton:setOn(not isPremium)
    rewardWallController.ui.info.free:setColor(isPremium and "#909090" or "#FFFFFF") 
    rewardWallController.ui.info.premium:setColor(isPremium and "#FFFFFF" or "#909090")
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
        if widget:getId() == "History" then
            widget:setVisible(bool)
        else
            widget:setVisible(not bool)
        end
        if i == 5 then
            break
        end
    end
end

local function updateDailyRewards(dayStreakDay)
    local dailyRewardsPanels = rewardWallController.ui.dailyRewardsPanels

    for i = 1, dayStreakDay do
        local rewardWidget = dailyRewardsPanels:getChildById("reward" .. i)
        local rewardArrow = dailyRewardsPanels:getChildById("arrow" .. i)
        if rewardWidget then
            local test = g_ui.createWidget("RewardButton", rewardWidget:getChildById("rewardGold" .. i))
            test:setOn(true)
            test:fill("parent")
            test:setPhantom(true)

            rewardArrow:setImageClip("5 0 5 7")
            rewardWidget:getChildById("rewardButton" .. i):setOn(false)
            rewardWidget:getChildById("rewardButton" .. i).ditherpattern:setVisible(true)
            rewardWidget:getChildById("rewardGold" .. i).status = 1
        end
    end

    local currentReward = dailyRewardsPanels:getChildById("reward" .. dayStreakDay + 1)
    if currentReward then
        local test = g_ui.createWidget("GoldLabel2", currentReward:getChildById("rewardGold" .. dayStreakDay + 1))
        test:setOn(true)
        test:fill("parent")
        test:setPhantom(true)
        test.text:setText("-99")
        test.text:setColor("red")
        test.gold:setImageSource("/game_rewardwall/images/icon-daily-reward-joker")
        test.gold:setImageSize("12 12")
        test.gold:setImageOffset("-20 0")
        currentReward:getChildById("rewardGold" .. dayStreakDay + 1).status = 2
        currentReward:setOn(false)
    end

    for i = dayStreakDay + 2, 7 do
        local rewardWidget = dailyRewardsPanels:getChildById("reward" .. i)
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

-- /*=============================================
-- =            onParse                  =
-- =============================================*/
local function onOpenRewardWall(bonusShrine, nextRewardTime, dayStreakDay, wasDailyRewardTaken, errorMessage, tokens,
    timeLeft, dayStreakLevel)

    updateDailyRewards(dayStreakDay)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.rewardStreakIcon:setText(dayStreakLevel)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.timeLeft:setText((timeLeft == 0 and "Expired") or (timeLeft == 90001 and "< 1 min") or timeLeft)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.restingAreaGold.text:setText(tokens)
    rewardWallController.ui.footerPanel.footerGold1.text:setText(dayStreakLevel)
    rewardWallController.ui.restingAreaPanel.restingAreaInfo.rewardStreakIcon:setImageSource(
        "/game_rewardwall/images/" .. getDayStreakIcon(dayStreakLevel))
end

local function checkRewards(data)
    for index, reward in ipairs(data) do
        local hasSelectableItems = reward.selectableItems and next(reward.selectableItems) ~= nil
        local rewardButton = rewardWallController.ui.dailyRewardsPanels:getChildById("reward" .. index):getChildById(
            "rewardButton" .. index)
        local iconWidget = rewardWallController.ui.dailyRewardsPanels:getChildById("reward" .. index):getChildByIndex(1)

        if hasSelectableItems then
            iconWidget:setIcon("game_rewardwall/images/icon-reward-pickitems")
            rewardButton.bundleType = bundleType.ITEMS
        elseif reward.bundleItems[1].bundleType == 3 then
            iconWidget:setIcon("game_rewardwall/images/icon-reward-xpboost")
            rewardButton.bundleType = bundleType.XPBOOST
        else
            iconWidget:setIcon("game_rewardwall/images/icon-reward-fixeditems")
            rewardButton.bundleType = bundleType.PREY
        end
    end
end

local function onDailyReward(data)
    bonuses = data.bonuses
    checkRewards(g_game.getLocalPlayer():isPremium() and data.freeRewards or data.premiumRewards)
end

local function onRewardHistory(rewardHistory)
    local transferHistory = rewardWallController.ui.History.History
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
end

local function hide()
    if not rewardWallController.ui then
        return
    end
    rewardWallController.ui:hide()
end

local function toggle()
    if not rewardWallController.ui then
        return
    end
    if rewardWallController.ui:isVisible() then
        return hide()
    end
    premiumStatusWindwos(g_game.getLocalPlayer():isPremium())
    show()
end

local function fixCssIncompatibility() -- temp
    rewardWallController.ui:centerIn('parent') -- mainWindows to the center of the screen
    rewardWallController.ui.History.History:fill('parent')

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

    -- no parseColoredText in css/otui
    rewardWallController.ui.restingAreaPanel.streakWarning:parseColoredText(
        "You did not claim your daily reward in time. If you don't claim your reward now, your [color=#D33C3C]streak will be reset.[/color]",
        "#c0c0c0")

end
-- /*=============================================
-- =            Controller                  =
-- =============================================*/
function rewardWallController:onInit()
    g_ui.importStyle("style.otui")
    rewardWallController:loadHtml('game_rewardwall.html')
    rewardWallController.ui:hide()

    rewardWallController:registerEvents(g_game, {
        onOpenRewardWall = onOpenRewardWall,
        onDailyReward = onDailyReward,
        onRewardHistory = onRewardHistory
    })
    fixCssIncompatibility()
end

function rewardWallController:onTerminate()
    if ButtonRewardWall then
        ButtonRewardWall:destroy()
        ButtonRewardWall = nil
    end
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
end
-- /*=============================================
-- =            Call css onClick                =
-- =============================================*/
function rewardWallController:onClickshowHistory()
    visibleHistory(not rewardWallController.ui.History:isVisible())
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
-- /*=============================================
-- =            Call onHover css                  =
-- =============================================*/

local function getBonusDescription(bonusName, streakCount, activeBonuses)
    local isPremium = g_game.getLocalPlayer():isPremium()

    return string.format(
        "Allow [color=#909090]%s[/color]%s\nThis bonus is active because you are [color=%s]Premium[/color] and reached a reward streak of at least [color=#44AD25]%d[/color].%s",
        bonusName,
        isPremium and "" or "[color=#ff0000](Locked)[/color]",
        isPremium and "#44AD25" or "#ff0000",
        streakCount,
        isPremium and ("\n\nActive bonuses: [color=#909090]%s[/color]."):format(activeBonuses) or ""
    )
end

function rewardWallController:onhoverBonus(event)
    if not event.value then
        rewardWallController.ui.info:setText("")
        return
    end

    local id = event.target:getId()
    local index = tonumber(id:match("%d+"))
    local bonus = bonuses[index]

    if not bonus then
        rewardWallController.ui.info:setText("Unknown bonus.")
        return
    end

    local isPremium = g_game.getLocalPlayer():isPremium()
    local bonusText = string.format(
        "Allow [color=#909090]%s[/color]%s\nThis bonus is active because you are [color=%s]Premium[/color] and reached a reward streak of at least [color=#44AD25]%d[/color].%s",
        bonus.name,
        isPremium and "" or "[color=#ff0000](Locked)[/color]",
        isPremium and "#44AD25" or "#ff0000",
        bonus.id,
        isPremium and ("\n\nActive bonuses: [color=#909090]%s[/color]."):format(getBonusStrings(bonuses)) or ""
    )

    rewardWallController.ui.info:parseColoredText(bonusText)
end


function rewardWallController:onhoverStatusPlayer(event)
    if not event.value then
        rewardWallController.ui.info:setText("")
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
    rewardWallController.ui.info:parseColoredText(info or DEFAULT_MESSAGE)
end

function rewardWallController:onhoverRewardType(event)
    if not event.value then
        rewardWallController.ui.info.free:setText("")
        rewardWallController.ui.info.premium:setText("")
        return
    end

    local rewardTexts = {
        [bundleType.ITEMS] = {
            free = "Reward for Free Accounts:\nPick 5 items from the list. Among\nother items it contains: health\npotion, a fire bomb rune, a\nthundestorm rune",
            premium = "Reward for Premium Accounts:\nPick 10 items from the list. Among\nother items it contains: health\npotion, a fire bomb rune, a\nthundestorm rune."
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
        rewardWallController.ui.info.free:setText(targetBundle.free)
        rewardWallController.ui.info.premium:setText(targetBundle.premium)
    else
        rewardWallController.ui.info.free:setText("")
        rewardWallController.ui.info.premium:setText("")
    end
end

function rewardWallController:onhoverStatusReward(event)
    local statusReward = {
        [STATUS.COLLECTED] = "You have already collected this daily reward.\nThe daily rewards follow a specific cycle where each day you claim it, you get another reward. The cycle repeats after 7 claimed rewards. You will be able to claim this daily reward again as soon as you have reached this postion in the next cycle.",
        [STATUS.ACTIVE] = "The daily reward can be claimed now.\nIf you claim this reward now, it will cost you one Instant Reward Access.\nGet your daily reward for free by visiting a reward shrine.\nYou did not claim your daily reward in time.\nToo bad, you do not have enough Daily Reward Jokers.",
        [STATUS.LOCKED] = "This daily reward is still locked.\nFirst collect the previous daily rewards of this cycle."
    }
    if not event.value then
        rewardWallController.ui.info:setText("")
        return
    end
    rewardWallController.ui.info:setText(statusReward[event.target.status])
end
