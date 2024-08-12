local context = G.botContext

context.BotServer = {}
context.BotServer.url = "ws://arm.skalski.pro:8000/"
context.BotServer.timeout = 3
context.BotServer.ping = 0
context.BotServer._callbacks = {}
context.BotServer._lastMessageId = 0
context.BotServer._wasConnected = true -- show first warning

context.BotServer.stopReconnect = false
context.BotServer.reconnectAttempts = 0
context.BotServer.maxReconnectAttempts = 10
context.BotServer.reconnectDelay = 2000

local function tryReconnect(name, channel)
  if not context.BotServer.stopReconnect and context.BotServer.reconnectAttempts < context.BotServer.maxReconnectAttempts then
    context.BotServer.reconnectAttempts = context.BotServer.reconnectAttempts + 1
    local cappedAttempts = math.min(context.BotServer.reconnectAttempts, 5)
    local delay = context.BotServer.reconnectDelay * (2 ^ (cappedAttempts  - 1))
    scheduleEvent(function()
      context.BotServer.init(name, channel)
    end, delay)
  else
    context.BotServer.stopReconnect = false
    context.BotServer.reconnectAttempts = 0
  end
end

context.BotServer.init = function(name, channel)
  if not channel or not name or channel:len() < 1 or name:len() < 1 then
    return context.error("Invalid params for BotServer.init")
  end
  if context.BotServer._websocket then
    return context.error("BotServer is already initialized")
  end
  context.BotServer._websocket = HTTP.WebSocketJSON(context.BotServer.url, {
    onError = function(message, websocketId)
      if message and message:find("resolve error") then
        context.BotServer.stopReconnect = true
      end
    end,
    onMessage = function(message, socketId)
      if not context._websockets[socketId] then
        return g_http.cancel(socketId)
      end
      if not context.BotServer._websocket or context.BotServer._websocket.id ~= socketId then
        return g_http.cancel(socketId)
      end
      context.BotServer._wasConnected = true
      if message["type"] == "ping" then
        context.BotServer.ping = message["ping"]
        return context.BotServer._websocket.send({type="ping"})
      end
      if message["type"] == "message" then
        context.BotServer._lastMessageId = message["id"]
        local topics = context.BotServer._callbacks[message["topic"]]
        if topics then
          for i=1,#topics do
            topics[i](message["name"], message["message"], message["topic"])
          end
        end
        topics = context.BotServer._callbacks["*"]
        if topics then
          for i=1,#topics do
            topics[i](message["name"], message["message"], message["topic"])
          end
        end
        return
      end
    end,
    onClose = function(message, socketId)
      if not context._websockets[socketId] then
        return
      end
      context._websockets[socketId] = nil
      if not context.BotServer._websocket or context.BotServer._websocket.id ~= socketId then
        return
      end
      if context.BotServer._wasConnected then
        context.warn("BotServer disconnected")
		HTTP.cancel(socketId)
      end
      context.BotServer._wasConnected = false
      context.BotServer._websocket = nil
      context.BotServer.ping = 0
      tryReconnect(name, channel)
    end
  }, context.BotServer.timeout)
  context._websockets[context.BotServer._websocket.id] = 1
  context.BotServer._websocket.send({type="init", name=name, channel=channel, lastMessage=context.BotServer._lastMessageId})
end

context.BotServer.terminate = function()
  if context.BotServer._websocket then
    context.BotServer._websocket:close()
    context.BotServer._websocket = nil
	context.BotServer._callbacks = {}
  end
end

context.BotServer.listen = function(topic, callback) -- callback = function(name, message, topic) -- message is parsed json = table
  if not context.BotServer._websocket then
    return context.error("BotServer is not initialized")
  end
  if not context.BotServer._callbacks[topic] then
    context.BotServer._callbacks[topic] = {}
  end
  table.insert(context.BotServer._callbacks[topic], callback)
end

context.BotServer.send = function(topic, message)
  if not context.BotServer._websocket then
    return context.error("BotServer is not initialized")
  end
  context.BotServer._websocket.send({type="message", topic=topic, message=message})
end

context.BotServer.isConnected = function()
  return context.BotServer._wasConnected and context.BotServer._websocket ~= nil
end

context.BotServer.hasListen = function(topic)
  return context.BotServer._callbacks and context.BotServer._callbacks[topic] ~= nil
end

context.BotServer.resetReconnect = function()
  context.BotServer.stopReconnect = true
end
