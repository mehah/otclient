setDefaultTab("Tools")

local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Dropper')

  Button
    id: edit
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Edit
]])

local edit = setupUI([[
Panel
  height: 150
    
  Label
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    text-align: center
    text: Trash:

  BotContainer
    id: TrashItems
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32

  Label
    anchors.top: prev.bottom
    margin-top: 5
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    text: Use:

  BotContainer
    id: UseItems
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32

  Label
    anchors.top: prev.bottom
    margin-top: 5
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    text: Drop if below 150 cap:

  BotContainer
    id: CapItems
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32   
]])
edit:hide()

if not storage.dropper then
    storage.dropper = {
      enabled = false,
      trashItems = { 283, 284, 285 },
      useItems = { 21203, 14758 },
      capItems = { 21175 }
    }
end

local config = storage.dropper

local showEdit = false
ui.edit.onClick = function(widget)
  showEdit = not showEdit
  if showEdit then
    edit:show()
  else
    edit:hide()
  end
end

ui.title:setOn(config.enabled)
ui.title.onClick = function(widget)
  config.enabled = not config.enabled
  ui.title:setOn(config.enabled)
end

UI.Container(function()
    config.trashItems = edit.TrashItems:getItems()
    end, true, nil, edit.TrashItems) 
edit.TrashItems:setItems(config.trashItems)

UI.Container(function()
    config.useItems = edit.UseItems:getItems()
    end, true, nil, edit.UseItems) 
edit.UseItems:setItems(config.useItems)

UI.Container(function()
    config.capItems = edit.CapItems:getItems()
    end, true, nil, edit.CapItems) 
edit.CapItems:setItems(config.capItems)

local function properTable(t)
    local r = {}
  
    for _, entry in pairs(t) do
      table.insert(r, entry.id)
    end
    return r
end

macro(200, function()
    if not config.enabled then return end
    local tables = {properTable(config.capItems), properTable(config.useItems), properTable(config.trashItems)}

    local containers = getContainers()
    for i=1,3 do
        for _, container in pairs(containers) do
            for __, item in ipairs(container:getItems()) do
                for ___, userItem in ipairs(tables[i]) do
                    if item:getId() == userItem then
                        return i == 1 and freecap() < 150 and dropItem(item) or
                               i == 2 and use(item) or
                               i == 3 and dropItem(item)
                    end
                end
            end
        end
    end

end)