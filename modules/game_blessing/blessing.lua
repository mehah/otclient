BlessingController = Controller:new()

function BlessingController:onInit()
end

function BlessingController:onTerminate()
  --  BlessingController:findWidget("#main"):destroy()
end

function BlessingController:onGameStart()
    g_ui.importStyle("style.otui")
    BlessingController:loadHtml('blessing.html')
    BlessingController.ui:centerIn('parent')

    BlessingController:registerEvents(g_game, {
        onUpdateBlessDialog = onUpdateBlessDialog
    })
    BlessingController.ui:hide()
    BlessingController.ui.minipanel1:setText("Record of Blessings") -- Temp fix html/css system
end

function BlessingController:onGameEnd()
    if BlessingController.ui:isVisible() then
        BlessingController.ui:hide()
    end
end

function BlessingController:close()
    hide()
end

function BlessingController:showHistory()
    if BlessingController.ui.blessingHistory:isVisible() then
        setBlessing()
    else
        setHistory()
    end
end

function setHistory()
    local ui = BlessingController.ui
    ui.minipanel1:hide()
    ui.promotionStatus2:hide()
    ui.promotionStatus:hide()
    ui.blessingHistory:show()
    ui.historyButton:setText("Back")
end

function setBlessing()
    local ui = BlessingController.ui
    ui.minipanel1:show()
    ui.promotionStatus2:show()
    ui.promotionStatus:show()
    ui.blessingHistory:hide()
    ui.historyButton:setText("History")
end

function toggle()
    if not BlessingController.ui then
        return
    end

    if BlessingController.ui:isVisible() then
        return hide()
    end
    show()
end

function hide()
    if not BlessingController.ui then
        return
    end
    BlessingController.ui:hide()
end

function show()
    if not BlessingController.ui then
        return
    end
    g_game.requestBless()
    BlessingController.ui:show()
    BlessingController.ui:raise()
    BlessingController.ui:focus()
    setBlessing()
end

function onUpdateBlessDialog(data)
    BlessingController.ui.minipanel1:destroyChildren()
    for i, entry in ipairs(data.blesses) do
        local label = g_ui.createWidget("blessingTEST", BlessingController.ui.minipanel1)
        local totalCount = entry.playerBlessCount + entry.store
        label.text:setText(entry.playerBlessCount .. " (" .. entry.store .. ")")
        if totalCount >= 1 then
            label.enabled:setImageSource("images/" .. i .. "_on")
        else
            label.enabled:setImageSource("images/" .. i)
        end
    end

    if (data.promotion ~= 0) then
        BlessingController.ui.promotionStatus2.premium_only:setOn(true)
        BlessingController.ui.promotionStatus2.rank:setColoredText(
            "Your character is promoted and your account has Premium\nstatus. As a result, your XP loss is reduced by {30%, #f75f5f}.")
    else
        BlessingController.ui.promotionStatus2.rank:setColoredText(
            "Your character is promoted and your account has Premium\nstatus. As a result, your XP loss is reduced by {0%, #f75f5f}.")
            BlessingController.ui.promotionStatus2.premium_only:setOn(false)
    end

    BlessingController.ui.promotionStatus.fightRules:setColoredText(
        "- Depending on the fair fight rules, you will lose between {" .. data.pvpMinXpLoss .. ", #f75f5f} and {" ..
            data.pvpMaxXpLoss .. "%, #f75f5f} less XP and skill points \nupon your next PvP death.")

    BlessingController.ui.promotionStatus.expLoss:setColoredText(
        "- You will lose {" .. data.pveExpLoss .. "%, #f75f5f}% less XP and skill points upon your next PvE death.")

    BlessingController.ui.promotionStatus.containerLoss:setColoredText(
        "- There is a {" .. data.equipPvpLoss ..
            "%, #f75f5f} chance that you will lose your equipped container on your next death.")

    BlessingController.ui.promotionStatus.equipmentLoss:setColoredText(
        "- There is a {" .. data.equipPveLoss .. "%, #f75f5f} chance that you will lose items upon your next death.")

    BlessingController.ui.blessingHistory:getChildByIndex(1):destroyChildren()
    local row2 = g_ui.createWidget("historyData", BlessingController.ui.blessingHistory:getChildByIndex(1))
    row2:setBackgroundColor("#363636")
    row2.rank:setText("date")
    row2.name:setText("Event")
    row2.rank:setColor("#c0c0c0")
    row2.name:setColor("#c0c0c0")
    row2:setBorderColor("#00000077")
    row2:setBorderWidth(1)

    for index, entry in ipairs(data.logs) do
        local row = g_ui.createWidget("historyData", BlessingController.ui.blessingHistory:getChildByIndex(1))
        local date = os.date("%Y-%m-%d, %H:%M:%S", entry.timestamp)
        row:setBackgroundColor(index % 2 == 0 and "#ffffff12" or "#00000012")
        row.rank:setText(date)
        row.name:setText(entry.historyMessage)
    end
end
