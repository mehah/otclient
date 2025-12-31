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

function matchText(input, target)
    input = input:lower()
    target = target:lower()

    if input == target then
        return true
    end

    if #input >= 1 and target:find(input, 1, true) then
        return true
    end
    return false
end

function roundToTwoDecimalPlaces(num)
  return math.floor(num * 100 + 0.5) / 100
end

function convertLongGold(amount, short)
  if short then
    if amount >= 1000000 then
      return string.format("%.1fM", amount / 1000000)
    elseif amount >= 1000 then
      return string.format("%.1fK", amount / 1000)
    else
      return tostring(amount)
    end
  else
    return comma_value(amount)
  end
end
