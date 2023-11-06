local context = G.botContext

context.BotServer = {}
context.BotServer.url = "ws://bot.otclient.ovh:8000/"
context.BotServer.timeout = 3
context.BotServer.ping = 0
context.BotServer._callbacks = {}
context.BotServer._lastMessageId = 0
context.BotServer._wasConnected = true -- show first warning

context.BotServer.init = function(name, channel)
  if not channel or not name or channel:len() < 1 or name:len() < 1 then
    return context.error("Invalid params for BotServer.init")
  end
  if context.BotServer._websocket then
    return context.error("BotServer is already initialized")
  end
  context.BotServer._websocket = HTTP.WebSocketJSON(context.BotServer.url, {
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
      end
      context.BotServer._wasConnected = false
      context.BotServer._websocket = nil
      context.BotServer.ping = 0
      context.BotServer.init(name, channel)
    end    
  }, context.BotServer.timeout)
  context._websockets[context.BotServer._websocket.id] = 1
  context.BotServer._websocket.send({type="init", name=name, channel=channel, lastMessage=context.BotServer._lastMessageId})
end

context.BotServer.terminate = function()
  if context.BotServer._websocket then
    context.BotServer._websocket:close()
    context.BotServer._websocket = nil
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
