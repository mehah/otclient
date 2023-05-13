local otmm = true
local oldPos = nil
local minimapButton = nil

local function updateCameraPosition()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local pos = player:getPosition()
    if not pos then
        return
    end

    local minimapWidget = controller.ui.contentsPanel.minimap
    if minimapWidget:isDragging() then
        return
    end

    if not minimapWidget.fullMapView then
        minimapWidget:setCameraPosition(pos)
    end

    minimapWidget:setCrossPosition(pos)
end

local function toggle()
    if minimapButton:isOn() then
        controller.ui:close()
    else
        controller.ui:open()
    end
end

local function toggleFullMap()
    local minimapWidget = controller.ui.contentsPanel.minimap
    local zoom;

    if minimapWidget.fullMapView then
        minimapWidget:setParent(controller.ui.contentsPanel)
        minimapWidget:fill('parent')
        controller.ui:show(true)
        zoom = minimapWidget.zoomMinimap
    else
        controller.ui:hide(true)
        minimapWidget:setParent(modules.game_interface.getRootPanel())
        minimapWidget:fill('parent')
        zoom = minimapWidget.zoomFullmap
    end

    minimapWidget.fullMapView = not minimapWidget.fullMapView
    -- minimapWidget:setAlternativeWidgetsVisible(fullmapView)

    local pos = oldPos or minimapWidget:getCameraPosition()
    oldPos = minimapWidget:getCameraPosition()
    minimapWidget:setZoom(zoom)
    minimapWidget:setCameraPosition(pos)
end

local localPlayerEvent = EventController:new(LocalPlayer, {
    onPositionChange = updateCameraPosition
})

controller = Controller:new()
controller:setUI('minimap')
controller:attachExternalEvent(localPlayerEvent)

function controller:onInit()
    minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', tr('Minimap') .. ' (Ctrl+M)',
        '/images/topbuttons/minimap', toggle)
    minimapButton:setOn(true)

    local minimapWidget = self.ui.contentsPanel.minimap

    local gameRootPanel = modules.game_interface.getRootPanel()
    self:bindKeyPress('Alt+Left', function()
        minimapWidget:move(1, 0)
    end, gameRootPanel)
    self:bindKeyPress('Alt+Right', function()
        minimapWidget:move(-1, 0)
    end, gameRootPanel)
    self:bindKeyPress('Alt+Up', function()
        minimapWidget:move(0, 1)
    end, gameRootPanel)
    self:bindKeyPress('Alt+Down', function()
        minimapWidget:move(0, -1)
    end, gameRootPanel)

    self:bindKeyDown('Ctrl+M', toggle)
    self:bindKeyDown('Ctrl+Shift+M', toggleFullMap)

    self.ui:setVisible(false)
    self.ui:setContentMinimumHeight(80)
    self.ui:setup()
end

function controller:onGameStart()
    self.ui:setupOnStart() -- load character window configuration

    -- Load Map
    g_minimap.clean()

    local minimapFile = '/minimap'
    local loadFnc = nil

    if otmm then
        minimapFile = minimapFile .. '.otmm'
        loadFnc = g_minimap.loadOtmm
    else
        minimapFile = minimapFile .. '_' .. g_game.getClientVersion() .. '.otcm'
        loadFnc = g_map.loadOtcm
    end

    if g_resources.fileExists(minimapFile) then
        loadFnc(minimapFile)
    end

    self.ui.contentsPanel.minimap:load()
end

function controller:onGameEnd()
    self.ui:setParent(nil, true)

    -- Save Map
    if otmm then
        g_minimap.saveOtmm('/minimap.otmm')
    else
        g_map.saveOtcm('/minimap_' .. g_game.getClientVersion() .. '.otcm')
    end

    self.ui.contentsPanel.minimap:save()
end

function controller:onTerminate()
    minimapButton:destroy()
    minimapButton = nil
end

function onMiniWindowOpen()
    minimapButton:setOn(true)
    localPlayerEvent:connect()
    localPlayerEvent:execute('onPositionChange')
end

function onMiniWindowClose()
    minimapButton:setOn(false)
    localPlayerEvent:disconnect()
end
