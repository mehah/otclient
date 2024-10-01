if not UIMiniWindow then
    dofile 'uiminiwindow'
end

-- @docclass
UIMessageBox = extends(UIMiniWindow, 'UIMessageBox')

-- messagebox cannot be created from otui files
function UIMessageBox.create(title, okCallback, cancelCallback)
    local calendar = UIMessageBox.internalCreate()
    return calendar
end

function UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback)
    local staticSizes = {
        width = {
            max = 916,
            min = 116
        },
        height = {
            min = 56,
            max = 616
        }
    }
    local currentSizes = {
        width = 0,
        height = 0
    }

    local messageBox = g_ui.createWidget('MessageBoxWindow', rootWidget)
    messageBox.title = messageBox:getChildById('title')
    messageBox.title:setText(title)

    messageBox.content = messageBox:getChildById('content')
    messageBox.content:setText(message)
    messageBox.content:resizeToText()
    messageBox.content:resize(messageBox.content:getWidth(), messageBox.content:getHeight())
    currentSizes.width = currentSizes.width + messageBox.content:getWidth() + 32
    currentSizes.height = currentSizes.height + messageBox.content:getHeight() + 20

    messageBox.holder = messageBox:getChildById('holder')

    currentSizes.height = currentSizes.height + 22
    for i = 1, #buttons do
        local button = messageBox:addButton(buttons[i].text, buttons[i].callback)
        button:addAnchor(AnchorTop, 'parent', AnchorTop)
        if i == 1 then
            button:addAnchor(AnchorRight, 'parent', AnchorRight)
            currentSizes.height = currentSizes.height + button:getHeight() + 22
        else
            button:addAnchor(AnchorRight, 'prev', AnchorLeft)
            button:setMarginRight(10)
        end
    end

    messageBox:setWidth(math.min(staticSizes.width.max, math.max(staticSizes.width.min, currentSizes.width)))
    messageBox:setHeight(math.min(staticSizes.height.max, math.max(staticSizes.height.min, currentSizes.height)))

    if onEnterCallback then
        connect(messageBox, {
            onEnter = onEnterCallback
        })
    end
    if onEscapeCallback then
        connect(messageBox, {
            onEscape = onEscapeCallback
        })
    end

    return messageBox
end

function displayInfoBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:ok()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Ok',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayErrorBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:ok()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Ok',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayCancelBox(title, message)
    local messageBox
    local defaultCallback = function()
        messageBox:cancel()
    end
    messageBox = UIMessageBox.display(title, message, {{
        text = 'Cancel',
        callback = defaultCallback
    }}, defaultCallback, defaultCallback)
    return messageBox
end

function displayGeneralBox(title, message, buttons, onEnterCallback, onEscapeCallback)
    return UIMessageBox.display(title, message, buttons, onEnterCallback, onEscapeCallback)
end

function displayGeneralSHOPBox(title, message,description, buttons, onEnterCallback, onEscapeCallback)
    return UIMessageBox.displaySHOP(title, message,description, buttons, onEnterCallback, onEscapeCallback)
end

function UIMessageBox:addButton(text, callback)
    local holder = self:getChildById('holder')
    local button = g_ui.createWidget('QtButton', holder)
    button:setWidth(math.max(48, 10 + (string.len(text) * 8)))
    button:setHeight(20)
    button:setText(text)
    connect(button, {
        onClick = callback
    })
    return button
end

function UIMessageBox:ok()
    signalcall(self.onOk, self)
    self.onOk = nil
    self:destroy()
end

function UIMessageBox:cancel()
    signalcall(self.onCancel, self)
    self.onCancel = nil
    self:destroy()
end

function UIMessageBox.displaySHOP(title, message,description,data, buttons, onEnterCallback, onEscapeCallback)
    local staticSizes = {
        width = {
            max = 380,
            min = 380
        },
        height = {
            min = 200,
            max = 200
        }
    }
    local currentSizes = {
        width = 380,
        height = 200
    }

    local messageBox = g_ui.createWidget('MessageBoxShopWindow', rootWidget)
    messageBox.title = messageBox:getChildById('title')
    messageBox.title:setText(title)

    messageBox.content = messageBox:getChildById('content')
    messageBox.content:setText(message)
    messageBox.additionalLabel:setText(description)

    if data then
        local VALOR = data.VALOR
        local ID = data.ID
        if VALOR == "item" then
            local itemWidget = g_ui.createWidget('Item', messageBox.Box)
            itemWidget:setId(ID)
            itemWidget:setItemId(ID)
        
        elseif VALOR == "icon" then
            local widget = g_ui.createWidget('UIWidget', messageBox.Box)
            widget:setImageSource("/game_store/images/64/" .. ID)
        elseif VALOR == "mountId" or VALOR == "outfitId" or VALOR == "maleOutfitId" or VALOR == "outfitId" then
            local creature = g_ui.createWidget('Creature', messageBox.Box)
            creature:setOutfit({ type = ID })
            creature:getCreature():setStaticWalking(1000)
        end
    end

    messageBox.content:resize(messageBox.content:getWidth(), messageBox.content:getHeight())
    currentSizes.width = currentSizes.width + messageBox.content:getWidth() + 32
    currentSizes.height = currentSizes.height + messageBox.content:getHeight() + 20

    messageBox.holder = messageBox:getChildById('holder')

    currentSizes.height = currentSizes.height + 22
    for i = 1, #buttons do
        local button = messageBox:addButton(buttons[i].text, buttons[i].callback)
        button:addAnchor(AnchorTop, 'parent', AnchorTop)
        if i == 1 then
            button:addAnchor(AnchorRight, 'parent', AnchorRight)
            currentSizes.height = currentSizes.height + button:getHeight() + 22
            button:setImageSource('/images/options/blue_large')
            button:setImageClip("0 0 108 20")
        else
            button:addAnchor(AnchorRight, 'prev', AnchorLeft)
            
            button:setMarginRight(10)
        end
    end

    messageBox:setWidth(math.min(staticSizes.width.max, math.max(staticSizes.width.min, currentSizes.width)))
    messageBox:setHeight(math.min(staticSizes.height.max, math.max(staticSizes.height.min, currentSizes.height)))

    if onEnterCallback then
        connect(messageBox, {
            onEnter = onEnterCallback
        })
    end
    if onEscapeCallback then
        connect(messageBox, {
            onEscape = onEscapeCallback
        })
    end

    return messageBox
end
