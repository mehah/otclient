local shortcutsWindow
local shortcuts
local shortcutIcons

function init()
  if not g_platform.isMobile() then return end

  shortcutsWindow = g_ui.displayUI('shortcuts')
  shortcuts = shortcutsWindow.shortcuts
  shortcutIcons = shortcuts.shortcutIcons

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd 
  })
  
  setupShortcuts()
end

function terminate()
  if not g_platform.isMobile() then return end

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd 
  })

  shortcutsWindow:destroy()
  shortcutsWindow = nil
end

function onGameStart()
  shortcuts:show()
end

function onGameEnd()
  shortcuts:hide()
end

function hide()
  shortcutsWindow:hide()
end

function show()
  shortcutsWindow:show()
end

function setupShortcuts()
  if not g_platform.isMobile() then return end
  for _, widget in ipairs(shortcutIcons:getChildren()) do
    widget.image:setChecked(false)
    widget.lastClicked = 0
    widget.onClick = function()
      if widget.image:isChecked() then
        widget.image:setChecked(false)
        return
      end
      resetShortcuts()
      widget.image:setChecked(true)
      widget.lastClicked = g_clock.millis()
    end
  end
end

function resetShortcuts()
  for _, widget in ipairs(shortcutIcons:getChildren()) do
    widget.image:setChecked(false)
    widget.lastClicked = 0
  end
end

function getShortcut()
  for _, widget in ipairs(shortcutIcons:getChildren()) do
    if widget.image:isChecked() then
      return widget:getId()
    end
  end
  return ""
end

function getPanel()
  return shortcuts
end