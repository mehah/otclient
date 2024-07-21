BlessingController = Controller:new()

function BlessingController:onInit()
end

function BlessingController:onTerminate()
    self:findWidget("#main"):destroy()
end

function BlessingController:onGameStart()
    g_ui.importStyle("style.otui")
    self:loadHtml('blessing.html')

    BlessingController:registerEvents(g_game, {
        onUpdateBlessDialog = onUpdateBlessDialog
    })
    BlessingController.ui:hide()
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
    ui.test:hide()
    ui.promotionStatus2:hide()
    ui.promotionStatus:hide()
    ui.blessingHistory:show()
    ui.historyButton:setText("Back")
end

function setBlessing()
    local ui = BlessingController.ui
    ui.test:show()
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

    BlessingController.ui.test:destroyChildren()

    for i, entry in ipairs(data.blesses) do
        local label = g_ui.createWidget("blessingTEST", BlessingController.ui.test)
        local totalCount = entry.playerBlessCount + entry.store
        label.text:setText(entry.playerBlessCount .. " (" .. entry.store .. ")")
        if totalCount >= 1 then
            label.enabled:setImageSource("images/" .. i .. "_on")
        end
    end

    if (data.promotion ~= 0) then
        BlessingController.ui.promotionStatus2.rank:setColoredText(
            "Your character is promoted and your account has Premium\nstatus. As a result, your XP loss is reduced by {30%, #f75f5f}.")
    else
        BlessingController.ui.promotionStatus2.rank:setColoredText(
            "Your character is promoted and your account has Premium\nstatus. As a result, your XP loss is reduced by {0%, #f75f5f}.")
    end

    BlessingController.ui.promotionStatus.fightRules:setColoredText(
        "- Depending on the fair fight rules, you will lose between {" .. data.pvpMinXpLoss .. ", #f75f5f} and {" ..
            data.pvpMaxXpLoss .. "%, #f75f5f} less XP and skill\npoints upon your next PvP death.")

    BlessingController.ui.promotionStatus.expLoss:setColoredText(
        "- You will lose {" .. data.pveExpLoss .. "%, #f75f5f}% less XP and skill points upon your next PvE death.")

    BlessingController.ui.promotionStatus.containerLoss:setColoredText(
        "- There is a {" .. data.equipPvpLoss ..
            "%, #f75f5f} chance that you will lose your equipped container on your next\ndeath.")

    BlessingController.ui.promotionStatus.equipmentLoss:setColoredText(
        "- There is a {" .. data.equipPveLoss .. "%, #f75f5f} chance that you will lose items upon your next death.")

    BlessingController.ui.blessingHistory.data:destroyChildren()

    for index, entry in ipairs(data.logs) do
        local row = g_ui.createWidget("historyData", BlessingController.ui.blessingHistory.data)
        local date = os.date("%Y-%m-%d, %H:%M:%S", entry.timestam)
        row:setBackgroundColor(index % 2 == 0 and "#ffffff12" or "#00000012")
        row.rank:setText(date)
        row.name:setText(entry.historyMessage)
    end

end
