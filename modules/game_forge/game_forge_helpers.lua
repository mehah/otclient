local Helpers = {}

function Helpers.cloneValue(value)
    if type(value) == 'table' then
        if table and type(table.recursivecopy) == 'function' then
            return table.recursivecopy(value)
        end

        local copy = {}
        for key, child in pairs(value) do
            copy[key] = Helpers.cloneValue(child)
        end
        return copy
    end

    return value
end

function Helpers.normalizeTierPriceEntries(entries)
    local prices = {}
    if type(entries) ~= 'table' then
        return prices
    end

    for _, entry in ipairs(entries) do
        if type(entry) == 'table' then
            local tierId = tonumber(entry.tier) or tonumber(entry.tierId) or tonumber(entry.id)
            local price = tonumber(entry.price) or tonumber(entry.cost) or tonumber(entry.value)
            if tierId then
                prices[tierId + 1] = price or 0
            end
        end
    end

    return prices
end

function Helpers.normalizeClassPriceEntries(entries)
    local pricesByClass = {}
    if type(entries) ~= 'table' then
        return pricesByClass
    end

    for _, classInfo in ipairs(entries) do
        if type(classInfo) == 'table' then
            local classId = tonumber(classInfo.classId)
                or tonumber(classInfo.id)
                or tonumber(classInfo.classification)
            if classId then
                pricesByClass[classId] = Helpers.normalizeTierPriceEntries(classInfo.tiers)
            end
        end
    end

    return pricesByClass
end

function Helpers.formatHistoryDate(timestamp)
    if not timestamp or timestamp == 0 then
        return 'Unknown'
    end

    return os.date('%Y-%m-%d, %H:%M:%S', timestamp)
end

Helpers.rightArrow = "/modules/game_forge/images/arrows/icon-arrow-rightlarge.png"
Helpers.filledRightArrow = "/modules/game_forge/images/arrows/icon-arrow-rightlarge-filled.png"

Helpers.baseResult = {
    leftItemId = -1,
    leftTier = 0,
    leftClip = nil,
    rightItemId = -1,
    rightTier = 0,
    rightClip = nil,
    label = "",
    labelResult = "",
    bonusItem = -1,
    bonusTier = 0,
    bonusItemClip = nil,
    bonusLabel = "",
    bonusAction = nil,
    arrows = {
        Helpers.rightArrow,
        Helpers.rightArrow,
        Helpers.rightArrow,
    },
    buttonLabel = "Close"
}

Helpers.green = "#44ad25"
Helpers.red = "#d33c3c"
Helpers.grey = "#c0c0c0"

return Helpers
