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

function Helpers.normalizeFusionGradeEntries(entries)
    local values = {}
    if type(entries) ~= 'table' then
        return values
    end

    for _, entry in ipairs(entries) do
        if type(entry) == 'table' then
            local tierId = tonumber(entry.tier) or tonumber(entry.tierId) or tonumber(entry.id)
            if tierId then
                local value = tonumber(entry.exaltedCores)
                    or tonumber(entry.cores)
                    or tonumber(entry.value)
                values[tierId + 1] = value or 0
            end
        end
    end

    return values
end

function Helpers.resolveForgePrice(priceMap, itemPtr, itemTier)
    if type(priceMap) ~= 'table' then
        return 0
    end

    local tierIndex = (tonumber(itemTier) or 0) + 1

    local classification = itemPtr and itemPtr.getClassification and itemPtr:getClassification() or 0
    if classification <= 0 then return 0 end

    for class, tiers in pairs(priceMap) do
        if class == classification then
            for tier, price in pairs(tiers) do
                if tier == tierIndex then
                    return tonumber(price) or 0
                end
            end
        end
    end

    return 0
end

function Helpers.defaultResourceFormatter(value)
    local numericValue = tonumber(value) or 0
    return tostring(numericValue)
end

function Helpers.formatGoldAmount(value)
    local numericValue = tonumber(value) or 0
    if type(comma_value) == 'function' then
        return comma_value(tostring(numericValue))
    end

    return tostring(numericValue)
end

function Helpers.formatHistoryDate(timestamp)
    if not timestamp or timestamp == 0 then
        return tr('Unknown')
    end

    return os.date('%Y-%m-%d, %H:%M:%S', timestamp)
end

function Helpers.resolveHistoryList(panel)
    if not panel then
        return nil
    end

    if panel.historyList and not panel.historyList:isDestroyed() then
        return panel.historyList
    end

    local list = panel:getChildById('historyList')
    if list then
        panel.historyList = list
    end
    return list
end

function Helpers.registerResourceConfig(resourceConfig, resourceType, config)
    if not resourceConfig or not resourceType or resourceConfig[resourceType] == config then
        return
    end

    resourceConfig[resourceType] = config
end

function Helpers.resolveStatusWidget(controller, config)
    if config.widget then
        if config.widget:isDestroyed() then
            config.widget = nil
        else
            return config.widget
        end
    end

    if not controller or not controller.ui then
        return nil
    end

    local widget = controller:findWidget(config.selector)
    if widget then
        config.widget = widget
    end

    return widget
end

function Helpers.loadTabFragment(controller, tabName)
    if not controller or not controller.ui then
        return nil
    end

    local fragment = io.content(('modules/%s/tab/%s/%s.html'):format(controller.name, tabName, tabName))
    local container = controller.ui.content:prepend(fragment)
    local panel = container
    if panel and panel.hide then
        panel:hide()
    end
    return panel
end

function Helpers.resolveScrollContents(widget)
    if not widget or widget:isDestroyed() then
        return nil
    end

    if widget.getChildById then
        local contents = widget:getChildById('contentsPanel')
        if contents and not contents:isDestroyed() then
            return contents
        end
    end

    return widget
end

function Helpers.getChildrenByStyleName(widget, styleName)
    if not widget or widget:isDestroyed() then
        return {}
    end

    local children = widget:recursiveGetChildrenByStyleName(styleName)
    if type(children) ~= 'table' then
        return {}
    end

    local results = {}
    for _, child in ipairs(children) do
        if child and not child:isDestroyed() then
            table.insert(results, child)
        end
    end

    return results
end

function Helpers.getFirstChildByStyleName(widget, styleName)
    local children = Helpers.getChildrenByStyleName(widget, styleName)
    return children[1]
end

return Helpers
