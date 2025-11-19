controllerModal = Controller:new()

local MINIMUM_WIDTH_QT = 380
local MINIMUM_WIDTH_OLD = 245
local MAXIMUM_WIDTH = 600
local MINIMUM_CHOICES = 4
local MAXIMUM_CHOICES = 10
local BASE_HEIGHT = 40
local MAX_CHOICE_TEXT = 28

function controllerModal:onInit()
    controllerModal:registerEvents(g_game, {
        onModalDialog = onModalDialog
    })
end

function controllerModal:onTerminate()
end

function controllerModal:onGameEnd()
    local ui = controllerModal.ui
    if ui and ui:isVisible() then
        controllerModal:unloadHtml()
    end
end

local function createButtonHandler(id, buttonId, choiceList)
    return function()
        local choice = (choiceList and choiceList.selectedChoice) or 0xFF
        g_game.answerModalDialog(id, buttonId, choice)
        controllerModal:unloadHtml()
    end
end

local function shortText(text, maxLen)
    return #text <= maxLen and text or text:sub(1, maxLen)
end

local function calculateAndSetWidth(ui, messageLabel, buttonsWidth, message)
    local horizontalPadding = ui:getPaddingLeft() + ui:getPaddingRight()
    local totalButtonsWidth = buttonsWidth + horizontalPadding
    local calculatedWidth = math.max(totalButtonsWidth, g_game.getFeature(GameEnterGameShowAppearance) and
        MINIMUM_WIDTH_OLD or MINIMUM_WIDTH_QT)
    if calculatedWidth > MAXIMUM_WIDTH then
        calculatedWidth = MAXIMUM_WIDTH
    end
    local contentWidth = calculatedWidth - horizontalPadding
    ui:setWidth(contentWidth)
    messageLabel:setWidth(contentWidth)
    messageLabel:setTextWrap(true)
    return calculatedWidth
end

local function calculateChoicesHeight(choiceList, choices, labelHeight)
    if #choices == 0 or not labelHeight then
        return 0
    end
    local visibleChoices = math.min(MAXIMUM_CHOICES, math.max(MINIMUM_CHOICES, #choices))
    local additionalHeight = visibleChoices * labelHeight + choiceList:getPaddingTop() + choiceList:getPaddingBottom()
    choiceList:setHeight(additionalHeight)
    return additionalHeight
end

local function applyFinalHeight(ui, messageLabel, additionalHeight)
    local finalHeight = BASE_HEIGHT + additionalHeight + messageLabel:getHeight()
    ui:setHeight(finalHeight)
    controllerModal:findWidget('#choiceList'):setWidth(ui:getWidth() * 0.9) -- html not work "Width:100%"
end

function onModalDialog(id, title, message, buttons, enterButton, escapeButton, choices, priority)
    if controllerModal.ui then
        controllerModal:unloadHtml()
    end
    local MINIMUM_WIDTH = g_game.getFeature(GameEnterGameShowAppearance) and MINIMUM_WIDTH_OLD or MINIMUM_WIDTH_QT
    controllerModal:loadHtml('modaldialog.html')
    local ui = controllerModal.ui
    ui:hide()
    local messageLabel = controllerModal:findWidget('#messageLabel')
    local choiceList = controllerModal:findWidget('#choiceList')
    local buttonsPanel = controllerModal:findWidget('#buttonsPanel')
    ui:setTitle(title)
    messageLabel:html(message)
    local labelHeight = nil
    local buttonsWidth = 0
    local choicesCount = #choices
    if choicesCount > 0 then
        choiceList:setVisible(true)
        for i = 1, choicesCount do
            local choiceId = choices[i][1]
            local choiceName = choices[i][2]
            local displayName = shortText(choiceName, MAX_CHOICE_TEXT)
            local choiceHtml = string.format('<div class="choice-item" style="width: %d;" data-choice-id="%d">%s</div>',
                MINIMUM_WIDTH, choiceId, displayName)
            local choiceWidget = controllerModal:createWidgetFromHTML(choiceHtml, choiceList)
            if choiceWidget then
                choiceWidget.choiceId = choiceId
                choiceWidget.choiceIndex = i
                if #choiceName > MAX_CHOICE_TEXT then
                    choiceWidget:setTooltip(choiceName)
                end
                if not labelHeight then
                    labelHeight = choiceWidget:getHeight()
                end
                choiceWidget.onClick = function()
                    choiceList.selectedChoice = choiceId
                    choiceList.selectedChoiceIndex = i
                end
            end
        end
        local firstChild = choiceList:getChildByIndex(1)
        if firstChild then
            firstChild:onClick()
            firstChild:focus()
        end
        g_keyboard.bindKeyPress('Up', function()
            choiceList:focusPreviousChild(KeyboardFocusReason)
            choiceList:ensureChildVisible(choiceList:getFocusedChild())
        end, choiceList)
        g_keyboard.bindKeyPress('Down', function()
            choiceList:focusNextChild(KeyboardFocusReason)
            choiceList:ensureChildVisible(choiceList:getFocusedChild())
        end, choiceList)
    else
        choiceList:setVisible(false)
    end
    for i = #buttons, 1, -1 do
        local buttonId = buttons[i][1]
        local buttonText = buttons[i][2]
        local buttonHtml = string.format('<button class="modal-button">%s</button>', buttonText)
        local button = controllerModal:createWidgetFromHTML(buttonHtml, buttonsPanel)

        if button then
            button.onClick = createButtonHandler(id, buttonId, choiceList)
            buttonsWidth = buttonsWidth + button:getWidth() + button:getMarginLeft() + button:getMarginRight()
        end
    end
    ui.onEnter = createButtonHandler(id, enterButton, choiceList)
    ui.onEscape = createButtonHandler(id, escapeButton, choiceList)
    if choiceList then
        choiceList.onDoubleClick = createButtonHandler(id, enterButton, choiceList)
    end
    calculateAndSetWidth(ui, messageLabel, buttonsWidth, message)
    local additionalHeight = calculateChoicesHeight(choiceList, choices, labelHeight)
    controllerModal:scheduleEvent(function()
        applyFinalHeight(ui, messageLabel, additionalHeight)
        ui:show()
    end, 222, "lazyHeightHtml")
end
