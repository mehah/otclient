controller = Controller:new()

if not g_gameConfig.isDrawingInformationByWidget() then
    return
end

g_logger.warning("Creature Information By Widget is enabled. (performance may be depreciated)");

local debug = false
local COVERED_COLOR = '#606060'
local NPC_COLOR = '#66CCFF'

local function onCreate(creature)
    local widget = g_ui.loadUI('creatureinformation')

    if debug then
        widget:setBorderColor('red')
        widget:setBorderWidth(2)
    end

    -- Fix rendering order
    widget.lifeBar:setImageDrawOrder(2)
    widget.manaBar:setImageDrawOrder(2)

    widget:setMarginLeft(-widget:getWidth() / 1.5)
    widget:setMarginTop(-widget:getHeight() / 2)

    if creature:isLocalPlayer() then
        widget.manaBar:setVisible(true)
    end

    creature:setWidgetInformation(widget)
end

local function onHealthPercentChange(creature, healthPercent, oldHealthPercent)
    local widget = creature:getWidgetInformation()
    local color = nil

    if healthPercent > 92 then
        color = '#00BC00';
    elseif healthPercent > 60 then
        color = '#50A150';
    elseif healthPercent > 30 then
        color = '#A1A100';
    elseif healthPercent > 8 then
        color = '#BF0A0A';
    elseif healthPercent > 3 then
        color = '#910F0F';
    else
        color = '#850C0F'
    end

    widget.name:setColor(color)
    widget.lifeBar:setPercent(healthPercent)
    widget.lifeBar:setBackgroundColor(color)
end

local function onManaChange(player, mana, maxMana, oldMana, oldMaxMana)
    local widget = player:getWidgetInformation()
    if player:getMaxMana() > 1 then
        widget.manaBar:setPercent((mana / maxMana) * 100)
    else
        widget.manaBar:setPercent(1)
    end
end

local function onChangeName(creature, name, oldName)
    local infoWidget = creature:getWidgetInformation()

    infoWidget.name:setText(name)

    if g_game.getFeature(GameBlueNpcNameColor) and creature:isNpc() and creature:isFullHealth() then
        infoWidget.name:setColor(NPC_COLOR)
    else
        --widget.name:setColor(NPC_COLOR)
    end
end

local function onOutfitChange(creature, outfit, oldOutfit)
    local infoWidget = creature:getWidgetInformation()
    if not infoWidget then
        return
    end

    local cropSize = 0

    if g_gameConfig.isAdjustCreatureInformationBasedCropSize() then
        cropSize = creature:getExactSize()
    end

    infoWidget:setMarginTop(-cropSize)
end

local function setIcon(creature, id, getIconPath)
    local path, blink = getIconPath(id)

    local infoWidget = creature:getWidgetInformation()
    local icon = g_ui.createWidget('IconInformation', infoWidget)
    icon:setId('icon' .. infoWidget:getChildCount())
    icon:setImageSource(path)
end

local function onTypeChange(creature, id)
    setIcon(creature, id, getTypeImagePath)
end

local function onIconChange(creature, id)
    setIcon(creature, id, getIconImagePath)
end

local function onSkullChange(creature, id)
    setIcon(creature, id, getSkullImagePath)
end

local function onShieldChange(creature, id)
    setIcon(creature, id, getShieldImagePathAndBlink)
end

local function onEmblemChange(creature, id)
    setIcon(creature, id, getEmblemImagePath)
end

controller = Controller:new()

function controller:onGameStart()
    --[[local player = g_game.getLocalPlayer()
    onCreate(player)
    onHealthPercentChange(player, player:getHealthPercent(), player:getHealthPercent())
    onChangeName(player, player:getName())
    onManaChange(player, player:getMana(), player:getMaxMana(), player:getMana(), player:getMaxMana())
    onTypeChange(player, 3)
    onIconChange(player, 1)
    onSkullChange(player, 1)
    onShieldChange(player, 1)
    onEmblemChange(player, 1)]]
end

controller:addEvent(LocalPlayer, {
    onManaChange = onManaChange
})

controller:addEvent(Creature, {
    onCreate = onCreate,
    onOutfitChange = onOutfitChange,
    onHealthPercentChange = onHealthPercentChange,
    onChangeName = onChangeName,
    onTypeChange = onTypeChange,
    onIconChange = onIconChange,
    onSkullChange = onSkullChange,
    onShieldChange = onShieldChange,
    onEmblemChange = onEmblemChange,
})
