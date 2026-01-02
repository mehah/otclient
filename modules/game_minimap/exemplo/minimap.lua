minimapWidget = nil
minimapButton = nil
minimapWindow = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil

function init()
  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getLeftPanel())
  minimapWindow:setContentMinimumHeight(64)

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)

  minimapWindow:setup()

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  if g_game.isOnline() then
    online()
  end

  local resizeBorder = minimapWindow:getChildById('resizeBorder')
  resizeBorder.onMousePress = function(self, mousePos, mouseButton)
    local parent = minimapWindow:getParent()
    if parent and parent:getClassName() == 'UIMiniWindowContainer' then
      local pos = minimapWindow:getPosition()
      local size = minimapWindow:getSize()
      
      -- Create placeholder to keep space in sidebar
      local placeholder = g_ui.createWidget('UIWidget')
      placeholder:setHeight(size.height)
      placeholder:setWidth(size.width)
      placeholder:setId('minimapPlaceholder')
      placeholder.save = true
      placeholder.close = function() end
      placeholder.saveParentIndex = function() end
      placeholder.saveParentPosition = function() end
      
      local index = parent:getChildIndex(minimapWindow)
      parent:insertChild(index, placeholder)
      minimapWindow.placeholder = placeholder

      -- Create placeholder for the second sidebar (LeftExtraPanel) if visible
      local leftExtraPanel = modules.game_interface.getLeftExtraPanel()
      if leftExtraPanel and leftExtraPanel:isVisible() then
        local placeholderExtra = g_ui.createWidget('UIWidget')
        placeholderExtra:setHeight(size.height)
        placeholderExtra:setWidth(leftExtraPanel:getWidth() - leftExtraPanel:getPaddingLeft() - leftExtraPanel:getPaddingRight())
        placeholderExtra:setId('minimapPlaceholderExtra')
        placeholderExtra.save = true
        placeholderExtra.close = function() end
        placeholderExtra.saveParentIndex = function() end
        placeholderExtra.saveParentPosition = function() end
        leftExtraPanel:insertChild(1, placeholderExtra)
        minimapWindow.placeholderExtra = placeholderExtra
      end
      
      minimapWindow:setParent(modules.game_interface.getRootPanel())
      minimapWindow:setPosition(pos)
      minimapWindow:setSize(size)
    end
  end

  local originalResizeRelease = resizeBorder.onMouseRelease
  resizeBorder.onMouseRelease = function(self, mousePos, mouseButton)
    if originalResizeRelease then originalResizeRelease(self, mousePos, mouseButton) end
    
    if minimapWindow:getWidth() < 180 then
      if minimapWindow.placeholder then
        local parent = minimapWindow.placeholder:getParent()
        minimapWindow:setParent(parent)
        local index = parent:getChildIndex(minimapWindow.placeholder)
        parent:insertChild(index, minimapWindow)
        
        minimapWindow.placeholder:destroy()
        minimapWindow.placeholder = nil
        
        if minimapWindow.placeholderExtra then
          minimapWindow.placeholderExtra:destroy()
          minimapWindow.placeholderExtra = nil
        end
        
        minimapWindow:setWidth(parent:getWidth() - parent:getPaddingLeft() - parent:getPaddingRight())
      else
        -- Fallback
        local leftPanel = modules.game_interface.getLeftPanel()
        minimapWindow:setParent(leftPanel)
        minimapWindow:setWidth(leftPanel:getWidth() - leftPanel:getPaddingLeft() - leftPanel:getPaddingRight())
      end
    end
  end

  local originalOnHeightChange = minimapWindow.onHeightChange
  minimapWindow.onHeightChange = function(self, height)
    if originalOnHeightChange then originalOnHeightChange(self, height) end
    if self.placeholder then
      self.placeholder:setHeight(height)
      local parent = self.placeholder:getParent()
      if parent and parent.fitAll then parent:fitAll(self.placeholder) end
    end
    if self.placeholderExtra then
      self.placeholderExtra:setHeight(height)
      local parent = self.placeholderExtra:getParent()
      if parent and parent.fitAll then parent:fitAll(self.placeholderExtra) end
    end
  end
end

function terminate()
  if g_game.isOnline() then
    saveConfig()
    saveMap()
  end

  if minimapWindow.placeholder then
    local parent = minimapWindow.placeholder:getParent()
    minimapWindow:setParent(parent)
    local index = parent:getChildIndex(minimapWindow.placeholder)
    parent:insertChild(index, minimapWindow)
    minimapWindow.placeholder:destroy()
    minimapWindow.placeholder = nil
  end

  if minimapWindow.placeholderExtra then
    minimapWindow.placeholderExtra:destroy()
    minimapWindow.placeholderExtra = nil
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')

  minimapWindow:destroy()
  if minimapButton then
    minimapButton:destroy()
  end
end

function toggle()
  if not minimapButton then return end
  if minimapButton:isOn() then
    minimapWindow:close()
    minimapButton:setOn(false)
  else
    minimapWindow:open()
    minimapButton:setOn(true)
  end
end

function onMiniWindowClose()
  if minimapButton then
    minimapButton:setOn(false)
  end
end

function online()
  loadMap()
  updateCameraPosition()
  loadConfig()
end

function offline()
  saveConfig()
  saveMap()
end

function saveConfig()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local char = player:getName()
  
  local settings = {}
  settings.detached = (minimapWindow:getParent() == modules.game_interface.getRootPanel())
  settings.width = minimapWindow:getWidth()
  settings.height = minimapWindow:getHeight()
  local pos = minimapWindow:getPosition()
  settings.pos = {x = pos.x, y = pos.y}
  
  g_settings.setNode('Minimap_Expansion_' .. char, settings)
end

function loadConfig()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local char = player:getName()
  
  local settings = g_settings.getNode('Minimap_Expansion_' .. char)
  if settings and settings.detached then
    local parent = minimapWindow:getParent()
    if parent and parent:getClassName() == 'UIMiniWindowContainer' then
       local size = {width = settings.width, height = settings.height}
       local pos = {x = settings.pos.x, y = settings.pos.y}
       
       local placeholder = g_ui.createWidget('UIWidget')
       placeholder:setHeight(size.height)
       placeholder:setWidth(size.width)
       placeholder:setId('minimapPlaceholder')
       placeholder.save = true
       placeholder.close = function() end
       placeholder.saveParentIndex = function() end
       placeholder.saveParentPosition = function() end
       
       local index = parent:getChildIndex(minimapWindow)
       parent:insertChild(index, placeholder)
       minimapWindow.placeholder = placeholder
       
       -- Restore placeholder for second sidebar if needed
       local leftExtraPanel = modules.game_interface.getLeftExtraPanel()
       if leftExtraPanel and leftExtraPanel:isVisible() then
         local placeholderExtra = g_ui.createWidget('UIWidget')
         placeholderExtra:setHeight(size.height)
         placeholderExtra:setWidth(leftExtraPanel:getWidth() - leftExtraPanel:getPaddingLeft() - leftExtraPanel:getPaddingRight())
         placeholderExtra:setId('minimapPlaceholderExtra')
         placeholderExtra.save = true
         placeholderExtra.close = function() end
         placeholderExtra.saveParentIndex = function() end
         placeholderExtra.saveParentPosition = function() end
         leftExtraPanel:insertChild(1, placeholderExtra)
         minimapWindow.placeholderExtra = placeholderExtra
       end

       minimapWindow:setParent(modules.game_interface.getRootPanel())
       minimapWindow:setPosition(pos)
       minimapWindow:setSize(size)
    end
  end
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  g_minimap.clean()
  loaded = false

  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  if g_resources.fileExists(dataMinimapFile) then
    loaded = g_minimap.loadOtmm(dataMinimapFile)
  end
  if not loaded and g_resources.fileExists(versionedMinimapFile) then
    loaded = g_minimap.loadOtmm(versionedMinimapFile)
  end
  if not loaded and g_resources.fileExists(minimapFile) then
    loaded = g_minimap.loadOtmm(minimapFile)
  end
  if not loaded then
    print("Minimap couldn't be loaded, file missing?")
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm' 
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
  end
end

function toggleFullMap()
  if not fullmapView then
    fullmapView = true
    minimapWindow:hide()
    minimapWidget:setParent(modules.game_interface.getRootPanel())
    minimapWidget:fill('parent')
    minimapWidget:setAlternativeWidgetsVisible(true)
  else
    fullmapView = false
    minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
    minimapWidget:fill('parent')
    minimapWindow:show()
    minimapWidget:setAlternativeWidgetsVisible(false)
  end

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)
end