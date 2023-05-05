local context = G.botContext

context.loadScript = function(path, onLoadCallback)
  if type(path) ~= 'string' then
    return context.error("Invalid path for loadScript: " .. tostring(path))
  end
  if path:lower():find("http") == 1 then
    return context.loadRemoteScript(path)
  end
  if not g_resources.fileExists(path) then
    return context.error("File " .. path .. " doesn't exist")
  end
  
  local status, result = pcall(function()
    assert(load(g_resources.readFileContents(path), path, nil, context))()
  end)
  if not status then
    return context.error("Error while loading script from: " .. path .. ":\n" .. result)
  end
  if onLoadCallback then
    onLoadCallback()
  end
end

context.loadRemoteScript = function(url, onLoadCallback)
  if type(url) ~= 'string' or url:lower():find("http") ~= 1 then
    return context.error("Invalid url for loadRemoteScript: " .. tostring(url))
  end
  
  HTTP.get(url, function(data, err)
    if err or data:len() == 0 then
      -- try to load from cache
      if type(context.storage.scriptsCache) ~= 'table' then
        context.storage.scriptsCache = {}
      end
      local cache = context.storage.scriptsCache[url]
      if cache and type(cache) == 'string' and cache:len() > 0 then
        data = cache
      else
        return context.error("Can't load script from: " .. url .. ", error: " .. err)
      end
    end
    
    local status, result = pcall(function()
      assert(load(data, url, nil, context))()
    end)
    if not status then
      return context.error("Error while loading script from: " .. url .. ":\n" .. result)
    end
    -- cache script
    if type(context.storage.scriptsCache) ~= 'table' then
      context.storage.scriptsCache = {}
    end
    context.storage.scriptsCache[url] = data
    if onLoadCallback then
      onLoadCallback()
    end
  end)  
end
