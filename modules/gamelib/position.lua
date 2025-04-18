Position = {}

function Position.equals(pos1, pos2)
    return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

function Position.greaterThan(pos1, pos2, orEqualTo)
    if orEqualTo then
        return pos1.x >= pos2.x or pos1.y >= pos2.y or pos1.z >= pos2.z
    else
        return pos1.x > pos2.x or pos1.y > pos2.y or pos1.z > pos2.z
    end
end

function Position.lessThan(pos1, pos2, orEqualTo)
    if orEqualTo then
        return pos1.x <= pos2.x or pos1.y <= pos2.y or pos1.z <= pos2.z
    else
        return pos1.x < pos2.x or pos1.y < pos2.y or pos1.z < pos2.z
    end
end

function Position.isInRange(pos1, pos2, xRange, yRange)
    return math.abs(pos1.x - pos2.x) <= xRange and math.abs(pos1.y - pos2.y) <= yRange and pos1.z == pos2.z;
end

function Position.isValid(pos)
    return not (pos.x == 65535 and pos.y == 65535 and pos.z == 255)
end

function Position.distance(pos1, pos2)
    return math.sqrt(math.pow((pos2.x - pos1.x), 2) + math.pow((pos2.y - pos1.y), 2))
end

function Position.offsetX(pos1, pos2)
    return math.abs(pos2.x - pos1.x)
end

function Position.offsetY(pos1, pos2)
    return math.abs(pos2.y - pos1.y)
end

function Position.offsetZ(pos1, pos2)
    return math.abs(pos2.z - pos1.z)
end

function Position.manhattanDistance(pos1, pos2)
    return math.abs(pos2.x - pos1.x) + math.abs(pos2.y - pos1.y)
end

function Position.translated(pos, dx, dy, dz)
    local newPos = {
        x = pos.x,
        y = pos.y,
        z = pos.z
    }

    newPos.x = newPos.x + dx
    newPos.y = newPos.y + dy
    newPos.z = newPos.z + (dz or 0)

    return newPos
end

function Position.translatedToDirection(pos, direction)
    local newPos = {
        x = pos.x,
        y = pos.y,
        z = pos.z
    }
    if direction == Directions.North then
        newPos.y = newPos.y - 1
    elseif direction == Directions.East then
        newPos.x = newPos.x + 1
    elseif direction == Directions.South then
        newPos.y = newPos.y + 1
    elseif direction == Directions.West then
        newPos.x = newPos.x - 1
    elseif direction == Directions.NorthEast then
        newPos.x = newPos.x + 1
        newPos.y = newPos.y - 1
    elseif direction == Directions.SouthEast then
        newPos.x = newPos.x + 1
        newPos.y = newPos.y + 1
    elseif direction == Directions.SouthWest then
        newPos.x = newPos.x - 1
        newPos.y = newPos.y + 1
    elseif direction == Directions.NorthWest then
        newPos.x = newPos.x - 1
        newPos.y = newPos.y - 1
    end

    return newPos
end

function Position.parse(pos)
    if not pos then
        return nil
    end
    return {
        x = pos.x,
        y = pos.y,
        z = pos.z
    }
end
