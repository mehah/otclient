setDefaultTab("Cave")
local panelName = "specialDeposit"
local depositerPanel

UI.Button("Stashing Settings", function()  
    depositerPanel:show()
    depositerPanel:raise()
    depositerPanel:focus()
end)

if not storage[panelName] then
    storage[panelName] = {
        items = {},
        height = 380
    }
end

local config = storage[panelName]

depositerPanel = UI.createWindow('DepositerPanel', rootWidget)
depositerPanel:hide()
-- basic one
depositerPanel.CloseButton.onClick = function()
    depositerPanel:hide()
end

depositerPanel:setHeight(config.height or 380)
depositerPanel.onGeometryChange = function(widget, old, new)
    if old.height == 0 then return end  
    config.height = new.height
end

function arabicToRoman(n)
    local t = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XI", "XII", "XIV", "XV", "XVI", "XVII"}
    return t[n]
end

local function refreshEntries()
    depositerPanel.DepositerList:destroyChildren()
    for _, entry in ipairs(config.items) do
      local panel = g_ui.createWidget("StashItem", depositerPanel.DepositerList)
      panel.name:setText(Item.create(entry.id):getMarketData().name)
      for i, child in ipairs(panel:getChildren()) do
          if child:getId() ~= "slot" then
            child:setTooltip("Clear item or double click to remove entry.")
            child.onDoubleClick = function(widget)
              table.remove(config.items, table.find(entry))
              panel:destroy()
            end
          end
      end
      panel.item:setItemId(entry.id)
      if entry.id > 0 then
        panel.item:setImageSource('')
      end
      panel.item.onItemChange = function(widget)
        local id = widget:getItemId()
        if id < 100 then
            table.remove(config.items, table.find(entry))
            panel:destroy()
        else
            for i, data in ipairs(config.items) do
                if data.id == id then
                    warn("[Depositer Panel] Item already added!")
                    return
                end
            end
            entry.id = id
            panel.item:setImageSource('')
            panel.name:setText(Item.create(entry.id):getMarketData().name)
            if entry.index == 0 then
                local window = modules.client_textedit.show(panel.slot, {
                    title = "Set depot for "..panel.name:getText(), 
                    description = "Select depot to which item should be stashed, choose between 3 and 17",
                    validation = [[^([3-9]|1[0-7])$]]
                })
                window.text:setText(entry.index)
                schedule(50, function() 
                  window:raise()
                  window:focus() 
                end)
            end
        end
      end
      if entry.id > 0 then
        panel.slot:setText("Stash to depot: ".. entry.index)
      end
      panel.slot:setTooltip("Click to set stashing destination.")
      panel.slot.onClick = function(widget)
        local window = modules.client_textedit.show(widget, {
            title = "Set depot for "..panel.name:getText(), 
            description = "Select depot to which item should be stashed, choose between 3 and 17",
            validation = [[^([3-9]|1[0-7])$]]
        })
        window.text:setText(entry.index)
        schedule(50, function() 
          window:raise()
          window:focus() 
        end)
      end
      panel.slot.onTextChange = function(widget, text)
        local n = tonumber(text)
        if n then
            entry.index = n
            widget:setText("Stash to depot: "..entry.index)
        end
      end
    end
end
refreshEntries()

depositerPanel.title.onDoubleClick = function(widget)
    table.insert(config.items, {id=0, index=0})
    refreshEntries()
end

function getStashingIndex(id)
    for _, v in pairs(config.items) do
        if v.id == id then
            return v.index - 1
        end
    end
end

UI.Separator()
UI.Label("Sell Exeptions")

if type(storage.cavebotSell) ~= "table" then
  storage.cavebotSell = {23544, 3081}
end

local sellContainer = UI.Container(function(widget, items)
  storage.cavebotSell = items
end, true)
sellContainer:setHeight(35)
sellContainer:setItems(storage.cavebotSell)