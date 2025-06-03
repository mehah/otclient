function readFile()
    local filePath = "data/XML/mounts.xml"
    local file = io.open(filePath, "r")
    if not file then
        print("Error opening the file: " .. filePath)
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

function Game.getMountIdByClientId(clientId)
    local content = readFile()
    if not content then
        return nil
    end
    
    for id, clientid in content:gmatch('<mount id="(%d+)" clientid="(%d+)"') do
        id = tonumber(id)
        clientid = tonumber(clientid)
        
        if clientid == clientId then
            return id
        end
    end
    
    return nil
end