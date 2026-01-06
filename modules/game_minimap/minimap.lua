-- Minimap Module
minimapWidget = nil
minimapWindow = nil

local otmm = true
local fullmapView = false
local oldZoom = nil
local oldPos = nil

-- Store original/default panel for minimap restoration
local defaultMinimapPanel = nil
local defaultMinimapIndex = nil

-- Helper function to calculate time display position
local function checkXByHour(x)
  local y0 = 62
  local incremento = y0 / 12
  local result = math.floor(y0 + (x * incremento))
  if result > 124 then
    result = result - 124
  end
  return result
end

-- Update floor indicator image
local function updateFloorImage(posZ)
  if minimapWindow and minimapWindow.floorPosition then
    minimapWindow.floorPosition:setImageClip((posZ) * 14 .. " 0 14 67")
  end
end

-- Position change callback
local function onPositionChange(creature, newPos, oldPos)
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  local pos = player:getPosition()
  if not pos then
    return
  end

  if not minimapWidget or minimapWidget:isDragging() then
    return
  end

  if not fullmapView then
    minimapWidget:setCameraPosition(pos)
  end

  minimapWidget:setCrossPosition(pos)

  if newPos and oldPos and newPos.z ~= oldPos.z then
    updateFloorImage(pos.z)
  end
end

-- Server time callback
local function onServerTime(hours, minutes)
  if not minimapWindow or not minimapWindow.centerMap then
    return
  end
  minimapWindow.centerMap:setImageClip(checkXByHour(hours) .. " 0 31 31")
end

-- Controller setup
mapController = Controller:new()
mapController:setUI('minimap', modules.game_interface.getMainRightPanel())

function mapController:onInit()
  minimapWindow = self.ui
  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  -- Allow minimap to be placed in main right panel (and other panels)
  minimapWindow.allowInMainRightPanel = true

  -- Hide built-in minimap buttons (we use custom ones from OTUI)
  local floorUpButton = minimapWidget:getChildById('floorUpButton')
  local floorDownButton = minimapWidget:getChildById('floorDownButton')
  local zoomInButton = minimapWidget:getChildById('zoomInButton')
  local zoomOutButton = minimapWidget:getChildById('zoomOutButton')
  local resetButton = minimapWidget:getChildById('resetButton')

  if floorUpButton then floorUpButton:hide() end
  if floorDownButton then floorDownButton:hide() end
  if zoomInButton then zoomInButton:hide() end
  if zoomOutButton then zoomOutButton:hide() end
  if resetButton then resetButton:hide() end

  -- Setup minimap window (skip if no close/minimize buttons)
  local closeButton = self.ui:getChildById('closeButton')
  local minimizeButton = self.ui:getChildById('minimizeButton')
  if closeButton and minimizeButton then
    self.ui:setup()
  end

  -- Setup mouse wheel on floor position widget for floor change
  if minimapWindow.floorPosition then
    minimapWindow.floorPosition.onMouseWheel = function(widget, mousePos, direction)
      if direction == MouseWheelUp then
        minimapWidget:floorUp(1)
      elseif direction == MouseWheelDown then
        minimapWidget:floorDown(1)
      end
      updateFloorImage(minimapWidget:getCameraPosition().z)
      return true
    end
  end

  -- Save default position after UI is initialized
  addEvent(function()
    saveMinimapDefaultPosition()
  end, 100)
end

function mapController:onGameStart()
  mapController:registerEvents(g_game, {
    onServerTime = onServerTime
  })

  mapController:registerEvents(LocalPlayer, {
    onPositionChange = onPositionChange
  }):execute()

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

  minimapWidget:load()
end

function mapController:onGameEnd()
  -- Save Map
  if otmm then
    g_minimap.saveOtmm('/minimap.otmm')
  else
    g_map.saveOtcm('/minimap_' .. g_game.getClientVersion() .. '.otcm')
  end

  minimapWidget:save()
end

function mapController:onTerminate()
  -- Cleanup if needed
end

-- Public functions called from OTUI

function zoom(zoomIn)
  if not minimapWidget then return end
  if zoomIn then
    minimapWidget:zoomIn()
  else
    minimapWidget:zoomOut()
  end
end

function floor(floorUp)
  if not minimapWidget then return end
  if floorUp then
    minimapWidget:floorUp(1)
  else
    minimapWidget:floorDown(1)
  end
  updateFloorImage(minimapWidget:getCameraPosition().z)
end

function center()
  if not minimapWidget then return end
  minimapWidget:reset()
end

function compassMove(direction)
  if not minimapWidget then return end

  local moveAmount = 10
  if direction == 'north' then
    minimapWidget:move(0, moveAmount)
  elseif direction == 'south' then
    minimapWidget:move(0, -moveAmount)
  elseif direction == 'east' then
    minimapWidget:move(-moveAmount, 0)
  elseif direction == 'west' then
    minimapWidget:move(moveAmount, 0)
  elseif direction == 'northeast' then
    minimapWidget:move(-moveAmount, moveAmount)
  elseif direction == 'northwest' then
    minimapWidget:move(moveAmount, moveAmount)
  elseif direction == 'southeast' then
    minimapWidget:move(-moveAmount, -moveAmount)
  elseif direction == 'southwest' then
    minimapWidget:move(moveAmount, -moveAmount)
  end
end

function onClose()
  -- Called when minimap window is closed
end

-- Accessor functions

function getMiniMapUi()
  return minimapWidget
end

function getMinimapWindow()
  return minimapWindow
end

-- Panel management functions

function restoreMinimapToDefault()
  if not minimapWindow then
    return false
  end

  local targetPanel = defaultMinimapPanel or modules.game_interface.getMainRightPanel()
  if not targetPanel then
    return false
  end

  local currentParent = minimapWindow:getParent()
  if currentParent == targetPanel then
    return true
  end

  if currentParent then
    currentParent:removeChild(minimapWindow)

    local currentParentId = currentParent:getId()
    if currentParentId == "horizontalLeftPanel" or currentParentId == "horizontalRightPanel" then
      if currentParent:getChildCount() == 0 then
        currentParent:setPhantom(true)
      end
    end

    -- Auto-fit old parent height
    if currentParent.fitAllChildren then
      currentParent:fitAllChildren()
    end
  end

  minimapWindow:setWidth(minimapWindow.defaultWidth or 178)
  minimapWindow:setHeight(minimapWindow.defaultHeight or 178)

  local insertIndex = defaultMinimapIndex or 1
  targetPanel:insertChild(insertIndex, minimapWindow)

  return true
end

function saveMinimapDefaultPosition()
  if not minimapWindow then
    return
  end

  local parent = minimapWindow:getParent()
  if parent and parent:getClassName() == 'UIMiniWindowContainer' then
    defaultMinimapPanel = parent
    defaultMinimapIndex = parent:getChildIndex(minimapWindow)
  end
end

function moveMinimapToPanel(panel, height, index)
  if not minimapWindow or not panel then
    return nil
  end

  local oldParent = minimapWindow:getParent()
  local panelId = panel:getId()

  if string.find(panelId, "horizontal") then
    addEvent(function()
      minimapWindow:setParent(panel)
      if height then
        minimapWindow:setHeight(height)
      end
      expandMinimapForHorizontalPanel(panel)

      -- Auto-fit old parent height
      if oldParent and oldParent.fitAllChildren then
        oldParent:fitAllChildren()
      end
    end)
  else
    minimapWindow:setParent(panel)
    if height then
      minimapWindow:setHeight(height)
    end

    -- Auto-fit old parent height
    if oldParent and oldParent.fitAllChildren then
      oldParent:fitAllChildren()
    end
  end

  minimapWindow:open()

  return minimapWindow
end

function expandMinimapForHorizontalPanel(panel)
  if not minimapWindow or not panel then
    return
  end

  -- Use addEvent to ensure the resize happens after the widget is fully placed
  addEvent(function()
    if not minimapWindow or not panel then
      return
    end

    local panelWidth = panel:getWidth()
    local panelHeight = panel:getHeight()

    -- Use 100% of available width and height
    minimapWindow:setWidth(panelWidth)
    minimapWindow:setHeight(panelHeight)

    panel:setPhantom(false)
  end)
end
