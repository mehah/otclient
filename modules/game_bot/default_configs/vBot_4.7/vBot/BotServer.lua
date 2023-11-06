setDefaultTab("Main")

local panelName = "BOTserver"
local ui = setupUI([[
Panel
  height: 18
  Button
    id: botServer
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    height: 18
    !text: tr('BotServer')
]])
ui:setId(panelName)

if not storage[panelName] then
  storage[panelName] = {
  manaInfo = true,
  mwallInfo = true,
  vocation = true,
  outfit = false,
  broadcasts = true
}
end

local config = storage[panelName]

if not storage.BotServerChannel then
  math.randomseed(os.time())
  storage.BotServerChannel = tostring(math.random(1000000000000,9999999999999))
end

local channel = tostring(storage.BotServerChannel)
BotServer.init(name(), channel)

vBot.BotServerMembers = {}

rootWidget = g_ui.getRootWidget()
if rootWidget then
  botServerWindow = g_ui.createWidget('BotServerWindow', rootWidget)
  botServerWindow:hide()


  botServerWindow.Data.Channel:setText(storage.BotServerChannel)
  botServerWindow.Data.Channel.onTextChange = function(widget, text)
    storage.BotServerChannel = text
  end
  botServerWindow.Data.Random.onClick = function(widget)
    storage.BotServerChannel = tostring(math.random(1000000000000,9999999999999))
    botServerWindow.Data.Channel:setText(storage.BotServerChannel)
  end
  botServerWindow.Features.Feature1:setOn(config.manaInfo)
  botServerWindow.Features.Feature1.onClick = function(widget)
    config.manaInfo = not config.manaInfo
    widget:setOn(config.manaInfo)
  end
  botServerWindow.Features.Feature2:setOn(config.mwallInfo)
  botServerWindow.Features.Feature2.onClick = function(widget)
    config.mwallInfo = not config.mwallInfo
    widget:setOn(config.mwallInfo)
  end
  botServerWindow.Features.Feature3:setOn(config.vocation)
  botServerWindow.Features.Feature3.onClick = function(widget)
    config.vocation = not config.vocation
    if config.vocation then
      BotServer.send("voc", player:getVocation())
    end
    widget:setOn(config.vocation)
  end
  botServerWindow.Features.Feature4:setOn(config.outfit)
  botServerWindow.Features.Feature4.onClick = function(widget)
    config.outfit = not config.outfit
    widget:setOn(config.outfit)
  end
  botServerWindow.Features.Feature5:setOn(config.broadcasts)
  botServerWindow.Features.Feature5.onClick = function(widget)
    config.broadcasts = not config.broadcasts
    widget:setOn(config.broadcasts)
  end
  botServerWindow.Features.Broadcast.onClick = function(widget)
    if BotServer._websocket then
      BotServer.send("broadcast", botServerWindow.Features.broadcastText:getText())
    end
    botServerWindow.Features.broadcastText:setText('')
  end
end

function updateStatusText()
  if BotServer._websocket then 
    botServerWindow.Data.ServerStatus:setText("CONNECTED")
    if serverCount then
      botServerWindow.Data.Members:setText("Members: "..#serverCount)
      if ServerMembers then
        local text = ""
        local regex = [["([a-z 'A-z-]*)"*]]
        local re = regexMatch(ServerMembers, regex)
        --re[name][2]
        for i=1,#re do
          if i == 1 then
            text = re[i][2]
          else
            text = text .. "\n" .. re[i][2]
          end
        end
        botServerWindow.Data.Members:setTooltip(text) 
      end
    end
  else
    botServerWindow.Data.ServerStatus:setText("DISCONNECTED")
    botServerWindow.Data.Participants:setText("-")
  end
end

macro(2000, function()
  if BotServer._websocket then
    BotServer.send("list")
  end
  updateStatusText()
end)

local regex = [["(.*?)"]]
BotServer.listen("list", function(name, data)
  serverCount = regexMatch(json.encode(data), regex)  
  ServerMembers = json.encode(data)
end)

ui.botServer.onClick = function(widget)
    botServerWindow:show()
    botServerWindow:raise()
    botServerWindow:focus()
end

botServerWindow.closeButton.onClick = function(widget)
    botServerWindow:hide()
end

-- scripts

-- mwalls
config.mwalls = {}
BotServer.listen("mwall", function(name, message)
  if config.mwallInfo then
    if not config.mwalls[message["pos"]] or config.mwalls[message["pos"]] < now then
      config.mwalls[message["pos"]] = now + message["duration"] - 150 -- 150 is latency correction
    end
  end
end)

onAddThing(function(tile, thing)
  if config.mwallInfo then
    if thing:isItem() and thing:getId() == 2129 then
      local pos = tile:getPosition().x .. "," .. tile:getPosition().y .. "," .. tile:getPosition().z
      if not config.mwalls[pos] or config.mwalls[pos] < now then
        config.mwalls[pos] = now + 20000
        BotServer.send("mwall", {pos=pos, duration=20000})
      end
    end
  end
end)

-- mana
local lastMana = 0
macro(500, function()
  if config.manaInfo then
    if manapercent() ~= lastMana then
      lastMana = manapercent()
      BotServer.send("mana", {mana=lastMana})
    end
  end
end)

BotServer.listen("mana", function(name, message)
  if config.manaInfo then
    local creature = getPlayerByName(name)
    if creature then
      creature:setManaPercent(message["mana"])
    end
  end
end)

-- vocation
if config.vocation then
  BotServer.send("voc", player:getVocation())
  BotServer.send("voc", "yes")
end

BotServer.listen("voc", function(name, message)
  if message == "yes" and config.vocation then
    BotServer.send("voc", player:getVocation())
  else
    vBot.BotServerMembers[name] = message
  end
end)

-- broadcast
BotServer.listen("broadcast", function(name, message)
  if config.broadcasts then
    broadcastMessage(name..": "..message)
  end
end)

addSeparator()