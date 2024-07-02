local statsBarTop
local statsBarBottom

local statsBars = {}
local statsBarDeepInfo = {}

-- If you want to add more placements/dimensions, you'll need to add them here.
-- This is used in getStatsBarMenuOptions(), createStatsBarWidgets(), 
--                         hideAll() and destroyAllIcons() functions.
local statsBarsPlacements = {
    "Top",
    "Bottom"
}

-- This is used in constructStatsBar(), getStatsBarMenuOptions(), 
--                   reloadCurrentTab(), createStatsBarWidgets(), 
--                       hideAll() and destroyALlIcons functions.
local statsBarsDimensions = {
    Large = {
        height = 35
    },
    Default = {
        height = 35
    },
    Parallel = {
        height = 35
    },
    Compact = {
        height = 20
    }
}

local firstCall = true

local currentStats = {
    dimension = "hide",
    placement = "hide"
}

local skillsLineHeight = 20
local skillsTuples = {
    {skill = nil,               key = 'experience', icon = '/images/icons/icon_experience',  placement = 'center',   order = 0,  name = "Level"},
    {skill = nil,               key = 'magic',      icon = '/images/icons/icon_magic',       placement = 'left',     order = 1,  name = "Magic Level"},
    {skill = Skill.Axe,         key = 'axe',        icon = '/images/icons/icon_axe',         placement = 'right',    order = 1,  name = "Axe Fighting Skill"},
    {skill = Skill.Club,        key = 'club',       icon = '/images/icons/icon_club',        placement = 'left',     order = 2,  name = "Club Fighting Skill"},
    {skill = Skill.Distance,    key = 'distance',   icon = '/images/icons/icon_distance',    placement = 'right',    order = 2,  name = "Distance Fighting Skill"},
    {skill = Skill.Fist,        key = 'fist',       icon = '/images/icons/icon_fist',        placement = 'left',     order = 3,  name = "Fist Fighting Skill"},
    {skill = Skill.Shielding,   key = 'shielding',  icon = '/images/icons/icon_shielding',   placement = 'right',    order = 3,  name = "Shielding Fighting Skill"},
    {skill = Skill.Sword,       key = 'sword',      icon = '/images/icons/icon_sword',       placement = 'left',     order = 4,  name = "Sword Fighting Skill"},
    {skill = Skill.Fishing,     key = 'fishing',    icon = '/images/icons/icon_fishing',     placement = 'right',    order = 4,  name = "Fishing Fighting Skill"},
}

StatsBar = {}


local function createBlankIcon()
    local statsBarConfigs = getConfigurations()
    
    for _, statsBarConfig in ipairs(statsBarConfigs) do
        local icon = g_ui.createWidget('ConditionWidget', statsBarConfig.icons)
        icon:setImageSource('/images/ui/blank')
        icon:setImageSize({
            width = 1,
            height = 1
        })
        icon:setMarginRight(-10)
    end
end

function getConfigurations()
    -- This method will return all the stats bar configurations.
    local configs = {}
    for _, statsBar in pairs(statsBars) do
        for _, placement in ipairs(statsBarsPlacements) do
            for dimension, _ in pairs(statsBarsDimensions) do
                local dimensionOnPlacement = tostring(dimension):lower() .. "On" .. placement
                local key = "statsBar" .. placement:gsub("^%l", string.upper)
                if statsBar[key] then
                    table.insert(configs, statsBar[key][dimensionOnPlacement])
                end
            end
        end
    end
    return configs
end

local function reloadSkillsTab(skills, parent)
    -- This method might need some refactoring if you want to add side stats bars.
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local tuples = {}
    for i = 1, #skillsTuples do
        local skillTuple = skillsTuples[i]
        if skillTuple and g_settings.getBoolean('top_statsbar_' .. skillTuple.key) then
            table.insert(tuples, skillTuple)
        end
    end

    local statsBar = StatsBar.getCurrentStatsBar()
    if not statsBar then
        return
    end

    statsBar:setHeight(statsBar:getHeight() - skills:getHeight())

    parent:setHeight(parent:getHeight() - (40 + skills:getHeight()))
    skills:setHeight(0)
    skills:destroyChildren()
    local lines = 0
    local lastPlacement = 'left'
    for i = 1, #tuples do
        local skillTuple = tuples[i]
        local widget = g_ui.createWidget('TopStatsSkillElement', skills)
        widget:setId('statsbar_skill_' .. skillTuple.key)
        widget:addAnchor(AnchorTop, 'parent', AnchorTop)
        if lastPlacement == 'left' then
            widget:setMarginTop(lines * skillsLineHeight)
        else
            widget:setMarginTop((lines - 1) * skillsLineHeight)
        end
        widget.level = widget:getChildById('level')
        widget.icon = widget:getChildById('icon')
        widget.bar = widget:getChildById('bar')

        widget.icon:setImageSource(skillTuple.icon)
        widget.icon:setTooltip(skillTuple.name)

        widget.bar.statsGrade = 4
        widget.bar.statsGradeColor = '#070707ff'
        widget.bar:reloadBorder()

        widget.bar.showText = false
        if skillTuple.key == 'experience' then
            widget.bar.statsType = 'experience'
        else
            widget.bar.statsType = 'skill'
        end

        if skillTuple.placement == 'center' or (i == #tuples and lastPlacement == 'left') then
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorRight, 'parent', AnchorRight)
            lines = lines + 1
        elseif lastPlacement == 'left' then
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorRight, 'parent', AnchorHorizontalCenter)
            lines = lines + 1
            lastPlacement = 'right'
        elseif lastPlacement == 'right' then
            widget:addAnchor(AnchorRight, 'parent', AnchorRight)
            widget:addAnchor(AnchorLeft, 'parent', AnchorHorizontalCenter)
            lastPlacement = 'left'
        end

        if skillTuple.key == 'experience' then
            widget.level:setText(player:getLevel())
            widget.bar:setValue(player:getLevelPercent(), 100)
        elseif skillTuple.key == 'magic' then
            widget.level:setText(player:getMagicLevel())
            widget.bar:setValue(player:getMagicLevelPercent(), 100)
        else
            widget.level:setText(player:getSkillLevel(skillTuple.skill))
            widget.bar:setValue(player:getSkillLevelPercent(skillTuple.skill), 100)
        end

    end

    skills:setHeight((lines * skillsLineHeight) + 5)
    parent:setHeight(40 + skills:getHeight())
    statsBar:setHeight(statsBar:getHeight() + skills:getHeight())
end

function StatsBar.getAllStatsBarWithPosition()
    -- This method will return all the stats bars based on their placement and dimension.
    -- i.e statsBarTop.largeOnTop, statsBarTop.parallelOnTop, statsBarTop.defaultOnTop, statsBarTop.compactOnTop [..]
    local statsBarsWithPosition = {}
    for _, statsBar in pairs(statsBars) do
        for _, placement in ipairs(statsBarsPlacements) do
            for dimension, _ in pairs(statsBarsDimensions) do
                local dimensionOnPlacement = tostring(dimension):lower() .. "On" .. placement
                if statsBar[dimensionOnPlacement] then
                    statsBarsWithPosition[#statsBarsWithPosition+1] = statsBar[dimensionOnPlacement]
                end
            end
        end
    end

    return statsBarsWithPosition
end

function StatsBar.getCurrentStatsBarWithPosition()
    -- This method will return the statsbar based on its placement and dimension.
    -- i.e "largeOnTop" will return statsBarTop.largeOnTop.
    -- It's made this way so we can call the current stats bar without having to use a switch statement.
    -- And if it's necessary to add more stats bars like "largeOnLeft" it will be easier to add them
    -- Without changing this code.
    if currentStats.dimension == 'hide' and currentStats.placement == 'hide' then
        return nil
    end
    -- -- Get full position as a single string. 
    -- -- i.e. largeOnTop // parallelOnBottom
    local placement = currentStats.placement:gsub("^%l", string.upper)
    local fullPosition = currentStats.dimension .. "On" .. placement
    local statsBar = StatsBar.getCurrentStatsBar()
    if not statsBar then
        return nil
    end

    if statsBar[fullPosition] then
    -- Return the stats bar based on the full position.
    -- i.e. statsBarTop.largeOnTop
        return statsBar[fullPosition]
    else
        print("No stats bar with position found for:", statsBar)
    end

    return nil
end

function StatsBar.getCurrentStatsBar()
    -- This method will return the statsbar based on its placement.
    -- i.e statsBarTop // statsBarBottom
    if currentStats.dimension == 'hide' and currentStats.placement == 'hide' then
        return nil
    end
    -- -- Get full placement. 
    -- -- i.e. Top // Bottom
    local placement = currentStats.placement:gsub("^%l", string.upper)

    -- -- Get the stats bar based on the placement.
    -- -- i.e. statsBarTop // statsBarBottom
    local statsBar = "statsBar" .. placement

    if statsBars[statsBar] then
        return statsBars[statsBar]
    else
        print("No stats bar found for:", statsBar)
    end

    return nil
end

function StatsBar.reloadCurrentStatsBarQuickInfo()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local bar = StatsBar.getCurrentStatsBarWithPosition()
    if not bar then
        return
    end

    bar.health:setValue(player:getHealth(), player:getMaxHealth())
    bar.mana:setValue(player:getMana(), player:getMaxMana())
end

local function loadIcon(bitChanged, content, topmenu)
    local icon = g_ui.createWidget('ConditionWidget', content)
    icon:setId(Icons[bitChanged].id)
    icon:setImageSource(Icons[bitChanged].path)
    icon:setTooltip(Icons[bitChanged].tooltip)
    icon:setImageSize({
        width = 9,
        height = 9
    })
    if topmenu then
        icon:setMarginTop(5)
    end
    return icon
end

local function getStatsBarsIconContent()
    local iconContents = {}
    local statsBars = StatsBar.getAllStatsBarWithPosition()

    for _, statsBar in ipairs(statsBars) do
        iconContents[#iconContents+1] = { content = statsBar.icons, loadIconTransparent = true }
    end

    iconContents[#iconContents+1] = { content = modules.game_inventory.getIconsPanelOn(), loadIconTransparent = false }
    iconContents[#iconContents+1] = { content = modules.game_inventory.getIconsPanelOff(), loadIconTransparent = false }

    return iconContents
end

local function toggleIcon(bitChanged)
    local contents = getStatsBarsIconContent()

    for _, contentData in ipairs(contents) do
        local icon = contentData.content:getChildById(Icons[bitChanged].id)
        if icon then
            icon:destroy()
        else
            icon = loadIcon(bitChanged, contentData.content, contentData.loadIconTransparent)
            icon:setParent(contentData.content)
        end
    end
end

function StatsBar.reloadCurrentStatsBarQuickInfo_state(localPlayer, now, old)
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    if now == old then
        return
    end

    local bitsChanged = bit.bxor(now, old)
    for i = 1, 32 do
        local pow = math.pow(2, i - 1)
        if pow > bitsChanged then
            break
        end
        local bitChanged = bit.band(bitsChanged, pow)
        if bitChanged ~= 0 then
            toggleIcon(bitChanged)
        end
    end
end

function StatsBar.reloadCurrentStatsBarDeepInfo()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local bar = StatsBar.getCurrentStatsBarWithPosition()
    if not bar then
        return
    end

    for _, skillTuple in ipairs(skillsTuples) do
        local widget = bar:recursiveGetChildById('statsbar_skill_' .. skillTuple.key)
        if widget then
            if skillTuple.key == 'experience' then
                widget.level:setText(player:getLevel())
                widget.bar:setValue(player:getLevelPercent(), 100)
            elseif skillTuple.key == 'magic' then
                widget.level:setText(player:getMagicLevel())
                widget.bar:setValue(player:getMagicLevelPercent(), 100)
            else
                widget.level:setText(player:getSkillLevel(skillTuple.skill))
                widget.bar:setValue(player:getSkillLevelPercent(skillTuple.skill), 100)
            end
        end
    end
end

function constructStatsBar(dimension, placement)
    local dimensionString = dimension:gsub("^%u", string.lower)
    StatsBar.updateCurrentStats(dimensionString, placement)

    local dimensionOnPlacement = dimensionString:gsub("^%u", string.lower) .. "On" .. placement:gsub("^%l", string.upper)
    local statsBar = statsBars["statsBar" .. placement:gsub("^%l", string.upper)]

    if statsBar[dimensionOnPlacement] then
        statsBar:setHeight(statsBarsDimensions[dimension].height)
        statsBar[dimensionOnPlacement]:setHeight(statsBarsDimensions[dimension].height)
        statsBar[dimensionOnPlacement]:show()
        statsBar[dimensionOnPlacement]:setPhantom(false)
        statsBar[dimensionOnPlacement].health = statsBar[dimensionOnPlacement]:getChildById('health')
        statsBar[dimensionOnPlacement].mana = statsBar[dimensionOnPlacement]:getChildById('mana')
        statsBar[dimensionOnPlacement].skills = statsBar[dimensionOnPlacement]:getChildById('skills')

    reloadSkillsTab(statsBar[dimensionOnPlacement].skills, statsBar[dimensionOnPlacement])
    StatsBar.reloadCurrentStatsBarQuickInfo()

    modules.game_healthcircle.setStatsBarOption()
    else 
        print("No stats bar found for:", dimensionOnPlacement .. " on constructStatsBar()")
    end
end

function StatsBar.updateCurrentStats(dimension, placement)
    currentStats = {
        dimension = dimension,
        placement = placement
    }
end

local function openDropMenu(mousePos)
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)

    local current = StatsBar.getCurrentStatsBarWithPosition()

    local menuOptions = getStatsBarMenuOptions(current)

    -- Add options to the menu based on the current stats bar
    for _, option in ipairs(menuOptions) do
        menu:addOption(tr(option.label), function()
            StatsBar.hideAll()
            constructStatsBar(option.dimension, option.placement)
        end)
    end

    menu:addSeparator()

    local current = StatsBar.getCurrentStatsBarWithPosition()
    if current and current.skills then
        for _, skillTuple in ipairs(skillsTuples) do
            if not g_settings.getBoolean('top_statsbar_' .. skillTuple.key) then
                menu:addOption(tr('Show') .. ' ' .. tr(skillTuple.name), function()
                    g_settings.set('top_statsbar_' .. skillTuple.key, true)
                    reloadSkillsTab(current.skills, current)
                end)
            else
                menu:addOption(tr('Hide') .. ' ' .. tr(skillTuple.name), function()
                    g_settings.set('top_statsbar_' .. skillTuple.key, false)
                    reloadSkillsTab(current.skills, current)
                end)
            end
        end
    end

    menu:addSeparator()
    menu:addOption(tr('Hide Customisable Status Bars'), function()
        StatsBar.hideAll()
        modules.game_healthcircle.setStatsBarOption("hide")
    end)

    menu:display(mousePos)
end

function shouldAddStatsBarOption(current, placement, style)
    local id = current:getId()
    return string.find(id, placement) and id ~= style
end

function getStatsBarMenuOptions(current)
    local optionsMenu = {}

    -- Create options available based on statsBarsPlacements and statsBarsDimensions tables.
    for _, placement in ipairs(statsBarsPlacements) do
        for dimension, _ in pairs(statsBarsDimensions) do
            local style = tostring(dimension):gsub("^%u", string.lower) .. 'On' .. placement
            if shouldAddStatsBarOption(current, placement, style) then
                optionsMenu[#optionsMenu+1] = { 
                    label = 'Switch to ' .. tostring(dimension) .. ' Style',
                    dimension = dimension,
                    placement = placement:gsub("^%u", string.lower),
                    style = style
                }
            end
        end
    end
    
    -- Create options available to switch placements keeping the same style
    -- i.e. from bottom to top // from top to bottom
    for _, placement in ipairs(statsBarsPlacements) do
        if not string.find(current:getId(), placement) then
            optionsMenu[#optionsMenu+1] = {
                label = 'Switch to ' .. placement .. ' Style',
                dimension = currentStats.dimension:gsub("^%l", string.upper),
                placement = placement:gsub("^%u", string.lower),
                construct = constructStatsBar,
                style = current:getId()
            }
        end
    end

    return optionsMenu
end

local function onStatsMousePress(tab, mousePos, mouseButton)
    if mouseButton == MouseRightButton then
        openDropMenu(mousePos)
        return true
    end
end

function StatsBar.reloadCurrentTab()
    local dimension = currentStats.dimension:gsub("^%l", string.upper)
    if statsBarsDimensions[dimension] then
        return constructStatsBar(dimension, currentStats.placement)
    else 
        print("No stats bars dimensions found: ", dimension, " on reloadCurrentTab()")
        return
    end
end

function StatsBar.updateStatsBarOption(dimension)
    StatsBar.hideAll()
    StatsBar.firstLoadSettings()

    if currentStats.dimension ~= "hide" and dimension ~= "hide" then
        StatsBar.reloadCurrentTab()
    end
end

local function getSettingOrDefault(setting, default)
  local value = g_settings.getString(setting)
  return value ~= "" and value or default
end

local function setSetting(setting, value)
  g_settings.set(setting, value)
end

function StatsBar.loadSettings()
    currentStats = {
        dimension = getSettingOrDefault('statsbar_dimension', "compact"),
        placement = getSettingOrDefault('statsbar_placement', "top")
    }
end

function StatsBar.saveSettings()
    setSetting('statsbar_dimension', currentStats.dimension)
    setSetting('statsbar_placement', currentStats.placement)
end

function StatsBar.firstLoadSettings()
    if firstCall then
        currentStats.dimension = getSettingOrDefault("statsbar_dimension", "compact")
        currentStats.placement = getSettingOrDefault("statsbar_placement", "top")

        firstCall = false
    end

    StatsBar.saveSettings()
    StatsBar.loadSettings()
end

function StatsBar.OnGameEnd()
    StatsBar.saveSettings()
    StatsBar.hideAll()

    modules.game_inventory.getIconsPanelOn():destroyChildren()
    modules.game_inventory.getIconsPanelOff():destroyChildren()

    StatsBar.destroyAllIcons()
end

function StatsBar.OnGameStart()
    StatsBar.loadSettings()

    createBlankIcon()
    StatsBar.reloadCurrentTab()
    modules.game_healthcircle.setStatsBarOption()
end

function createStatsBarWidgets(statsBar)
    -- This method will create the widgets based on the statsBar, statsBarsPlacements and statsBarsDimensions tables.
    local widget = statsBar
    for _, placement in ipairs(statsBarsPlacements) do
      for dimension, _ in pairs(statsBarsDimensions) do
        local elementName = tostring(dimension):gsub("^%u", string.lower) .. "On" .. placement
        widget[elementName] = statsBar:getChildById(elementName)
      end
    end
    widget.onMousePress = onStatsMousePress
    return widget
end

function StatsBar.init()
    statsBarTop = modules.game_interface.getGameTopStatsBar()
    statsBarBottom = modules.game_interface.getGameBottomStatsBar()

    statsBars = {
        statsBarTop = statsBarTop,
        statsBarBottom = statsBarBottom
    }

    if not statsBarTop then
        return
    end

    if not statsBarBottom then
        return
    end

    -- Create widgets based on statsBars table.
    for _, statBar in pairs(statsBars) do
        statBar = createStatsBarWidgets(statBar)
    end

    statsBarDeepInfo = {
        onExperienceChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onHealthChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onManaChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onStatesChange = StatsBar.reloadCurrentStatsBarQuickInfo_state
    }

    StatsBar.hideAll()
    connect(LocalPlayer, statsBarDeepInfo)
    connect(g_game, {
        onGameStart = StatsBar.OnGameStart,
        onGameEnd = StatsBar.OnGameEnd
    })
end

function StatsBar.hideAll()
    -- This iterates between the tables: statsBar -> statsBarsPlacements -> statsBarsDimensions
    -- And hides all the stats bars based on these tables.
    for _, bar in pairs(statsBars) do
        for _, placement in pairs(statsBarsPlacements) do
            for dimension, _ in pairs(statsBarsDimensions) do
                local key = tostring(dimension):lower() .. "On" .. placement
                if bar[key] and bar[key].skills then
                    bar[key].skills:destroyChildren()
                    bar[key].skills:setHeight(0)
                    bar[key]:setHeight(0)
                    bar[key]:hide()
                end
            end
        end
        bar:setHeight(0)
    end
end

function StatsBar.destroyAllIcons()
    -- This iterates between the tables: statsBar -> statsBarsPlacements -> statsBarsDimensions
    -- And destroy all icons based on these tables.
    for _, bar in pairs(statsBars) do
        for _, placement in pairs(statsBarsPlacements) do
            for dimension, _ in pairs(statsBarsDimensions) do
                local key = tostring(dimension):lower() .. "On" .. placement
                if bar[key] and bar[key].skills then
                    bar[key].icons:destroyChildren()
                end
            end
        end
        bar:setHeight(0)
    end
end

function StatsBar.destroyAllBars()
    -- This iterates between the tables: statsBars
    -- And destroy all bars based on these tables.
    for _, bar in pairs(statsBars) do
        bar:destroy()
    end
end

function StatsBar.terminate()
    StatsBar.saveSettings()
    
    disconnect(LocalPlayer, statsBarDeepInfo)
    disconnect(g_game, {
        onGameStart = StatsBar.OnGameStart,
        OnGameEnd = StatsBar.OnGameEnd
    })
    
    StatsBar.destroyAllBars()
end
