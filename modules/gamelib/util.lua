function postostring(pos)
    return pos.x .. ' ' .. pos.y .. ' ' .. pos.z
end

function dirtostring(dir)
    for k, v in pairs(Directions) do
        if v == dir then
            return k
        end
    end
end

function comma_value(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

function formatTimeBySeconds(totalSeconds)
    local hours = math.floor(totalSeconds / 3600)
    local remainingSeconds = totalSeconds % 3600
    local minutes = math.floor(remainingSeconds / 60)
    return string.format("%02d:%02d", hours, minutes)
end

function formatTimeByMinutes(totalMinutes)
    local totalSeconds = totalMinutes * 60
    local hours = math.floor(totalSeconds / 3600)
    local remainingSeconds = totalSeconds % 3600
    local minutes = math.floor(remainingSeconds / 60)
    return string.format("%02d:%02d", hours, minutes)
end
