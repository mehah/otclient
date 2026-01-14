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

function math.cround(value, rd)
    local _round = math.floor(value / rd)
    return _round * rd
end

function formatMoney(amount, separator)
  local patternSeparator = string.format("%%1%s%%2", separator)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", patternSeparator)
    if (k==0) then
      break
    end
  end
  return formatted
end

if not setStringColor then
  function setStringColor(str, color)
    return str  -- ignora a cor e retorna o texto puro
  end
end

function convertLongGold(amount, shortValue, normalized)
    local hasBillion = false
    local hasTrillion = false
  
    local fomarType = 0
    if normalized and amount >= 1000000 then
      amount = math.floor(amount / 1000000)
      fomarType = 1
    elseif normalized and amount >= 10000 then
      amount = math.floor(amount / 1000)
      fomarType = 2
    elseif shortValue and amount > 10000000 then
        fomarType = 1
      amount = math.floor(amount / 1000000)
    elseif shortValue and amount > 1000000 then
        fomarType = 2
      amount = math.floor(amount / 1000)
    elseif amount > 999999999 then
      fomarType = 1
      amount = math.floor(amount / 1000000)
    elseif amount > 99999999 then
      fomarType = 2
      amount = math.floor(amount / 1000)
    end
  
    local formatted = amount
    while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
  
    if fomarType == 1 then
      formatted = formatted .. " kk"
    elseif fomarType == 2 then
      formatted = formatted .. " k"
    end
  
    return formatted
end