setDefaultTab("Tools")

local targetID = nil

-- escape when attacking will reset hold target
onKeyPress(function(keys)
    if keys == "Escape" and targetID then
        targetID = nil
    end
end)

macro(100, "Hold Target", function()
    -- if attacking then save it as target, but check pos z in case of marking by mistake on other floor
    if target() and target():getPosition().z == posz() and not target():isNpc() then
        targetID = target():getId()
    elseif not target() then
        -- there is no saved data, do nothing
        if not targetID then return end

        -- look for target
        for i, spec in ipairs(getSpectators()) do
            local sameFloor = spec:getPosition().z == posz()
            local oldTarget = spec:getId() == targetID
            
            if sameFloor and oldTarget then
                attack(spec)
            end
        end
    end
end) 