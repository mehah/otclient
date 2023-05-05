setDefaultTab("Cave")
local panelName = "supplies"
if not SuppliesConfig[panelName] or SuppliesConfig[panelName].item1 then
  SuppliesConfig[panelName] = {
    currentProfile = "Default",
    ["Default"] = {}
  }
end

local function convertOldConfig(config)
  if config and config.items then
    return config
  end -- config is new

  local newConfig = {
    items = {},
    capSwitch = config.capSwitch,
    SoftBoots = config.SoftBoots,
    imbues = config.imbues,
    staminaSwitch = config.staminaSwitch,
    capValue = config.capValue,
    staminaValue = config.staminaValue
  }

  local items = {
    config.item1,
    config.item2,
    config.item3,
    config.item4,
    config.item5,
    config.item6
  }
  local mins = {
    config.item1Min,
    config.item2Min,
    config.item3Min,
    config.item4Min,
    config.item5Min,
    config.item6Min
  }
  local maxes = {
    config.item1Max,
    config.item2Max,
    config.item3Max,
    config.item4Max,
    config.item5Max,
    config.item6Max
  }

  for i, item in ipairs(items) do
    if item > 100 then
      local min = mins[i]
      local max = maxes[i]
      newConfig.items[tostring(item)] = {
        min = min,
        max = max,
        avg = 0
      }
    end
  end

  return newConfig
end

-- convert old configs
for k, profile in pairs(SuppliesConfig[panelName]) do
  if type(profile) == 'table' then
    SuppliesConfig[panelName][k] = convertOldConfig(profile)
  end
end

local currentProfile = SuppliesConfig[panelName].currentProfile
local config = SuppliesConfig[panelName][currentProfile]

vBotConfigSave("supply")

if not config then
  for k, v in pairs(SuppliesConfig[panelName]) do
    if type(v) == "table" then
      SuppliesConfig[panelName].currentProfile = k
      config = SuppliesConfig[panelName][k]
      break
    end
  end
end

function getEmptyItemPanels()
  local panel = SuppliesWindow.items
  local count = 0

  for i, child in ipairs(panel:getChildren()) do
    count = child:getId() == "blank" and count + 1 or count
  end

  return count
end

function deleteFirstEmptyPanel()
  local panel = SuppliesWindow.items

  for i, child in ipairs(panel:getChildren()) do
    if child:getId() == "blank" then
      child:destroy()
      break
    end
  end
end

function clearEmptyPanels()
  local panel = SuppliesWindow.items

  if panel:getChildCount() > 1 then
    if getEmptyItemPanels() > 1 then
      deleteFirstEmptyPanel()
    end
  end
end

function addItemPanel()
  local parent = SuppliesWindow.items
  local childs = parent:getChildCount()
  local panel = UI.createWidget("ItemPanel", parent)
  local item = panel.id
  local min = panel.min
  local max = panel.max
  local avg = panel.avg

  panel:setId("blank")
  item:setShowCount(false)

  item.onItemChange = function(widget)
    local id = widget:getItemId()
    local panelId = panel:getId()

    -- empty, verify
    if id < 100 then
      config.items[panelId] = nil
      panel:setId("blank")
      clearEmptyPanels() -- clear empty panels if any
      return
    end

    -- itemId was not changed, ignore
    if tonumber(panelId) == id then
      return
    end

    -- check if isnt already added
    if config[tostring(id)] then
      warn("vBot[Drop Tracker]: Item already added!")
      widget:setItemId(0)
      return
    end

    -- new item id
    config.items[tostring(id)] = config.items[tostring(id)] or {} -- min, max, avg
    panel:setId(id)
    addItemPanel() -- add new panel
  end

  return panel
end

SuppliesWindow = UI.createWindow("SuppliesWindow")
SuppliesWindow:hide()

UI.Button(
  "Supply Settings",
  function()
    SuppliesWindow:setVisible(not SuppliesWindow:isVisible())
  end
)

-- load settings
local function loadSettings()
  -- panels
  SuppliesWindow.items:destroyChildren()

  for id, data in pairs(config.items) do
    local widget = addItemPanel()
    widget:setId(id)
    widget.id:setItemId(tonumber(id))
    widget.min:setText(data.min)
    widget.max:setText(data.max)
    widget.avg:setText(data.avg)
  end
  addItemPanel() -- add empty panel

  -- switches and values
  SuppliesWindow.capSwitch:setOn(config.capSwitch)
  SuppliesWindow.SoftBoots:setOn(config.SoftBoots)
  SuppliesWindow.imbues:setOn(config.imbues)
  SuppliesWindow.staminaSwitch:setOn(config.staminaSwitch)
  SuppliesWindow.capValue:setText(config.capValue or 0)
  SuppliesWindow.staminaValue:setText(config.staminaValue or 0)
end
loadSettings()

-- save settings
SuppliesWindow.onVisibilityChange = function(widget, visible)
  if not visible then
    local currentProfile = SuppliesConfig[panelName].currentProfile
    SuppliesConfig[panelName][currentProfile].items = {}
    local parent = SuppliesWindow.items

    -- items
    for i, panel in ipairs(parent:getChildren()) do
      if panel.id:getItemId() > 100 then
        local id = tostring(panel.id:getItemId())
        local min = panel.min:getValue()
        local max = panel.max:getValue()
        local avg = panel.avg:getValue()

        SuppliesConfig[panelName][currentProfile].items[id] = {
          min = min,
          max = max,
          avg = avg
        }
      end
    end

    vBotConfigSave("supply")
  end
end

local function refreshProfileList()
  local profiles = SuppliesConfig[panelName]

  SuppliesWindow.profiles:destroyChildren()
  for k, v in pairs(profiles) do
    if type(v) == "table" then
      local label = UI.createWidget("ProfileLabel", SuppliesWindow.profiles)
      label:setText(k)
      label:setTooltip("Click to load this profile. \nDouble click to change the name.")
      label.remove.onClick = function()
        local childs = SuppliesWindow.profiles:getChildCount()
        if childs == 1 then
          return info("vBot[Supplies] You need at least one profile!")
        end
        profiles[k] = nil
        label:destroy()
        vBotConfigSave("supply")
      end
      label.onDoubleClick = function(widget)
        local window =
          modules.client_textedit.show(
          widget,
          {title = "Set Profile Name", description = "Enter a new name for selected profile"}
        )
        schedule(
          50,
          function()
            window:raise()
            window:focus()
          end
        )
      end
      label.onClick = function()
        SuppliesConfig[panelName].currentProfile = label:getText()
        config = SuppliesConfig[panelName][label:getText()]
        loadSettings()
        vBotConfigSave("supply")
      end
      label.onTextChange = function(widget, text)
        currentProfile = text
        SuppliesConfig[panelName].currentProfile = text
        profiles[text] = profiles[k]
        profiles[k] = nil
        vBotConfigSave("supply")
      end
    end
  end
end
refreshProfileList()

local function setProfileFocus()
  for i, v in ipairs(SuppliesWindow.profiles:getChildren()) do
    local name = v:getText()
    if name == SuppliesConfig[panelName].currentProfile then
      return v:focus()
    end
  end
end
setProfileFocus()

SuppliesWindow.newProfile.onClick = function()
  local n = SuppliesWindow.profiles:getChildCount()
  if n > 6 then
    return info("vBot[Supplies] - max profile count reached!")
  end
  local name = "Profile #" .. n + 1
  SuppliesConfig[panelName][name] = {items = {}}
  refreshProfileList()
  setProfileFocus()
  vBotConfigSave("supply")
end

SuppliesWindow.capSwitch.onClick = function(widget)
  config.capSwitch = not config.capSwitch
  widget:setOn(config.capSwitch)
end

SuppliesWindow.SoftBoots.onClick = function(widget)
  config.SoftBoots = not config.SoftBoots
  widget:setOn(config.SoftBoots)
end

SuppliesWindow.imbues.onClick = function(widget)
  config.imbues = not config.imbues
  widget:setOn(config.imbues)
end

SuppliesWindow.staminaSwitch.onClick = function(widget)
  config.staminaSwitch = not config.staminaSwitch
  widget:setOn(config.staminaSwitch)
end

SuppliesWindow.capValue.onTextChange = function(widget, text)
  local value = tonumber(SuppliesWindow.capValue:getText())
  if not value then
    SuppliesWindow.capValue:setText(0)
    config.capValue = 0
  else
    text = text:match("0*(%d+)")
    config.capValue = text
  end
end

SuppliesWindow.staminaValue.onTextChange = function(widget, text)
  local value = tonumber(SuppliesWindow.staminaValue:getText())
  if not value then
    SuppliesWindow.staminaValue:setText(0)
    config.staminaValue = 0
  else
    text = text:match("0*(%d+)")
    config.staminaValue = text
  end
end

SuppliesWindow.increment.onClick = function(widget)
  for i, panel in ipairs(SuppliesWindow.items:getChildren()) do
    if panel.id:getItemId() > 100 then
      local max = panel.max:getValue()
      local avg = panel.avg:getValue()

      if avg > 0 then
        panel.max:setText(max + avg)
      end
    end
  end
end

SuppliesWindow.decrement.onClick = function(widget)
  for i, panel in ipairs(SuppliesWindow.items:getChildren()) do
    if panel.id:getItemId() > 100 then
      local max = panel.max:getValue()
      local avg = panel.avg:getValue()

      if avg > 0 then
        panel.max:setText(math.max(0, max - avg)) -- dont go below 0
      end
    end
  end
end

SuppliesWindow.increment.onMouseWheel = function(widget, mousePos, dir)
  if dir == 1 then
    SuppliesWindow.increment.onClick()
  elseif dir == 2 then
    SuppliesWindow.decrement.onClick()
  end
end

SuppliesWindow.decrement.onMouseWheel = SuppliesWindow.increment.onMouseWheel

Supplies = {} -- public functions
Supplies.show = function()
  SuppliesWindow:show()
  SuppliesWindow:raise()
  SuppliesWindow:focus()
end

Supplies.getItemsData = function()
  local t = {}
  -- items
  for i, panel in ipairs(SuppliesWindow.items:getChildren()) do
    if panel.id:getItemId() > 100 then
      local id = tostring(panel.id:getItemId())
      local min = panel.min:getValue()
      local max = panel.max:getValue()
      local avg = panel.avg:getValue()

      t[id] = {
        min = min,
        max = max,
        avg = avg
      }
    end
  end

  return t
end

Supplies.isSupplyItem = function(id)
  local data = Supplies.getItemsData()
  id = tostring(id)

  if data[id] then
    return data[id]
  else
    return false
  end
end

Supplies.hasEnough = function()
  local data = Supplies.getItemsData()

  for id, values in pairs(data) do
    id = tonumber(id)
    local minimum = values.min
    local current = player:getItemsCount(id) or 0

    if current < minimum then
      return {id=id, amount=current}
    end
  end

  return true
end

hasSupplies = Supplies.hasEnough

Supplies.setAverageValues = function(data)
  for id, amount in pairs(data) do
    local widget = SuppliesWindow.items[id]

    if widget then
      widget.avg:setText(amount)
    end
  end
end

Supplies.addSupplyItem = function(id, min, max, avg)
  if not id then
    return
  end

  local widget = addItemPanel()
  widget:setId(id)
  widget.id:setItemId(tonumber(id))
  widget.min:setText(min or 0)
  widget.max:setText(max or 0)
  widget.avg:setText(avg or 0)
end

Supplies.getAdditionalData = function()
  local data = {
    stamina = {enabled = config.staminaSwitch, value = config.staminaValue},
    capacity = {enabled = config.capSwitch, value = config.capValue},
    softBoots = {enabled = config.SoftBoots},
    imbues = {enabled = config.imbues}
  }
  return data
end

Supplies.getFullData = function()
  local data = {
    items = Supplies.getItemsData(),
    additional = Supplies.getAdditionalData()
  }

  return data
end