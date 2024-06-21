local statsBar
local firstCall = true

local currentStats = {
    dimension = 'hide',
    placement = 'hide'
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
    local statsBarConfigs = {statsBar.largeOnTop, statsBar.parallelOnTop, statsBar.defaultOnTop, statsBar.compactOnTop}
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

local function reloadSkillsTab(skills, parent)
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

    skills:setHeight(lines * skillsLineHeight)
    if parent:getId() == 'largeOnTop' then
        skills:setHeight(skills:getHeight() + 5)
    elseif lines == 0 then
        skills:setHeight(skills:getHeight() + 5)
    end
    parent:setHeight(40 + skills:getHeight())
    statsBar:setHeight(statsBar:getHeight() + skills:getHeight())
end

function StatsBar.getCurrentStatsBar()
    if currentStats.dimension == 'hide' and currentStats.placement == 'hide' then
        return nil
    end

    if currentStats.placement == 'top' then
        if currentStats.dimension == 'large' then
            return statsBar.largeOnTop
        elseif currentStats.dimension == 'parallel' then
            return statsBar.parallelOnTop
        elseif currentStats.dimension == 'default' then
            return statsBar.defaultOnTop
        elseif currentStats.dimension == 'compact' then
            return statsBar.compactOnTop
        end
    end

    return nil
end

function StatsBar.reloadCurrentStatsBarQuickInfo()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local bar = StatsBar.getCurrentStatsBar()
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

local function toggleIcon(bitChanged)
    local contents = {
        {content = statsBar.largeOnTop.icons,loadIconTransparent = true},
        {content = statsBar.parallelOnTop.icons,loadIconTransparent = true}, 
        {content = statsBar.defaultOnTop.icons,loadIconTransparent = true}, 
        {content = statsBar.compactOnTop.icons, loadIconTransparent = true}, 
        {content = modules.game_mainpanel.getIconsPanelOff()},
        {content = modules.game_mainpanel.getIconsPanelOn()}
    }

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

    local bar = StatsBar.getCurrentStatsBar()
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

function StatsBar.hideAll()

    statsBar.largeOnTop.skills:destroyChildren()
    statsBar.largeOnTop.skills:setHeight(0)
    statsBar.largeOnTop:setHeight(0)
    statsBar.largeOnTop:hide()

    statsBar.parallelOnTop.skills:destroyChildren()
    statsBar.parallelOnTop.skills:setHeight(0)
    statsBar.parallelOnTop:setHeight(0)
    statsBar.parallelOnTop:hide()

    statsBar.defaultOnTop.skills:destroyChildren()
    statsBar.defaultOnTop.skills:setHeight(0)
    statsBar.defaultOnTop:setHeight(0)
    statsBar.defaultOnTop:hide()

    statsBar.compactOnTop.skills:destroyChildren()
    statsBar.compactOnTop.skills:setHeight(0)
    statsBar.compactOnTop:setHeight(0)
    statsBar.compactOnTop:hide()

    statsBar:setHeight(0)
    currentStats = {
        dimension = 'hide',
        placement = 'hide'
    }

    -- modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
end

local function constructLargeOnTop()
    statsBar:setHeight(35)
    statsBar.largeOnTop:setHeight(35)
    statsBar.largeOnTop:show()

    currentStats = {
        dimension = 'large',
        placement = 'top'
    }

    statsBar.largeOnTop:show()
    statsBar.largeOnTop:setPhantom(false)
    statsBar.largeOnTop.health = statsBar.largeOnTop:getChildById('health')
    statsBar.largeOnTop.mana = statsBar.largeOnTop:getChildById('mana')
    statsBar.largeOnTop.skills = statsBar.largeOnTop:getChildById('skills')

    reloadSkillsTab(statsBar.largeOnTop.skills, statsBar.largeOnTop)
    StatsBar.reloadCurrentStatsBarQuickInfo()

    modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
    return true
end

local function constructParallelOnTop()
    statsBar:setHeight(55)
    statsBar.parallelOnTop:setHeight(55)
    statsBar.parallelOnTop:show()

    currentStats = {
        dimension = 'parallel',
        placement = 'top'
    }

    statsBar.parallelOnTop:show()
    statsBar.parallelOnTop:setPhantom(false)
    statsBar.parallelOnTop.health = statsBar.parallelOnTop:getChildById('health')
    statsBar.parallelOnTop.mana = statsBar.parallelOnTop:getChildById('mana')
    statsBar.parallelOnTop.skills = statsBar.parallelOnTop:getChildById('skills')

    reloadSkillsTab(statsBar.parallelOnTop.skills, statsBar.parallelOnTop)
    StatsBar.reloadCurrentStatsBarQuickInfo()

    modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
    return true
end

local function constructDefaultOnTop()
    statsBar:setHeight(35)
    statsBar.defaultOnTop:setHeight(35)
    statsBar.defaultOnTop:show()

    currentStats = {
        dimension = 'default',
        placement = 'top'
    }

    statsBar.defaultOnTop:show()
    statsBar.defaultOnTop:setPhantom(false)
    statsBar.defaultOnTop.health = statsBar.defaultOnTop:getChildById('health')
    statsBar.defaultOnTop.mana = statsBar.defaultOnTop:getChildById('mana')
    statsBar.defaultOnTop.skills = statsBar.defaultOnTop:getChildById('skills')

    reloadSkillsTab(statsBar.defaultOnTop.skills, statsBar.defaultOnTop)
    StatsBar.reloadCurrentStatsBarQuickInfo()

    modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
    return true
end

local function constructCompactOnTop()
    statsBar:setHeight(35)
    statsBar.compactOnTop:setHeight(35)
    statsBar.compactOnTop:show()

    currentStats = {
        dimension = 'compact',
        placement = 'top'
    }

    statsBar.compactOnTop:show()
    statsBar.compactOnTop:setPhantom(false)
    statsBar.compactOnTop.health = statsBar.compactOnTop:getChildById('health')
    statsBar.compactOnTop.mana = statsBar.compactOnTop:getChildById('mana')
    statsBar.compactOnTop.skills = statsBar.compactOnTop:getChildById('skills')

    reloadSkillsTab(statsBar.compactOnTop.skills, statsBar.compactOnTop)
    StatsBar.reloadCurrentStatsBarQuickInfo()

    modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
    return true
end

local function openDropMenu(mousePos)
    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)

    local current = StatsBar.getCurrentStatsBar()
    if not (current) or current:getId() ~= 'compactOnTop' then
        menu:addOption(tr('Switch to Compact Style'), function()
            StatsBar.hideAll()
            constructCompactOnTop()
        end)
    end

    if not (current) or current:getId() ~= 'defaultOnTop' then
        menu:addOption(tr('Switch to Default Style'), function()
            StatsBar.hideAll()
            constructDefaultOnTop()
        end)
    end

    if not (current) or current:getId() ~= 'largeOnTop' then
        menu:addOption(tr('Switch to Large Style'), function()
            StatsBar.hideAll()
            constructLargeOnTop()
        end)
    end

    if not (current) or current:getId() ~= 'parallelOnTop' then
        menu:addOption(tr('Switch to Parallel Style'), function()
            StatsBar.hideAll()
            constructParallelOnTop()
        end)
    end

    menu:addSeparator()

    local current = StatsBar.getCurrentStatsBar()
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
        modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)
    end)

    menu:display(mousePos)
end

local function onStatsMousePress(tab, mousePos, mouseButton)
    if mouseButton == MouseRightButton then
        openDropMenu(mousePos)
        return true
    end
end

function StatsBar.reloadCurrentTab()
    if currentStats.placement == 'top' then
        if currentStats.dimension == 'large' then
            return constructLargeOnTop()
        elseif currentStats.dimension == 'parallel' then
            return constructParallelOnTop()
        elseif currentStats.dimension == 'default' then
            return constructDefaultOnTop()
        elseif currentStats.dimension == 'compact' then
            return constructCompactOnTop()
        end
    end
end

function StatsBar.setStatsBarOption(dimension, placement)
    StatsBar.hideAll()
    if firstCall then
        if g_settings.getString('top_statsbar_dimension') and g_settings.getString('top_statsbar_dimension') ~= "" then
            dimension = g_settings.getString('top_statsbar_dimension')
        else
            dimension = "compact"
        end

        firstCall = false
    end

    currentStats = {
        dimension = dimension,
        placement = placement
    }
    g_settings.set('top_statsbar_dimension', currentStats.dimension)
    g_settings.set('top_statsbar_placement', currentStats.placement)

    if dimension ~= "hide" then
        StatsBar.reloadCurrentTab()
    end

end

function StatsBar.OnGameEnd()
    g_settings.set('top_statsbar_dimension', currentStats.dimension)
    g_settings.set('top_statsbar_placement', currentStats.placement)

    StatsBar.hideAll()

    modules.game_mainpanel.getIconsPanelOn():destroyChildren()
    modules.game_mainpanel.getIconsPanelOff():destroyChildren()

    statsBar.largeOnTop.icons:destroyChildren()
    statsBar.parallelOnTop.icons:destroyChildren()
    statsBar.defaultOnTop.icons:destroyChildren()
    statsBar.compactOnTop.icons:destroyChildren()
end

function StatsBar.OnGameStart()
    currentStats = {
        dimension = g_settings.getString('top_statsbar_dimension'),
        placement = g_settings.getString('top_statsbar_placement')
    }

    if not (currentStats.dimension) or not (currentStats.placement) or currentStats.dimension == '' or
        currentStats.placement == '' then
        currentStats = {
            dimension = 'default',
            placement = 'top'
        }
    end

    createBlankIcon()
    StatsBar.reloadCurrentTab()
    modules.game_healthcircle.setTopBarOption(currentStats.dimension, currentStats.placement)

end

function StatsBar.init()
    statsBar = modules.game_interface.getGameTopStatsBar()
    if not statsBar then
        return
    end
    statsBar.largeOnTop = statsBar:getChildById('largeOnTop')
    statsBar.parallelOnTop = statsBar:getChildById('parallelOnTop')
    statsBar.defaultOnTop = statsBar:getChildById('defaultOnTop')
    statsBar.compactOnTop = statsBar:getChildById('compactOnTop')
    statsBar.onMousePress = onStatsMousePress

    StatsBar.hideAll()
    connect(LocalPlayer, {
        onExperienceChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onHealthChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onManaChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onStatesChange = StatsBar.reloadCurrentStatsBarQuickInfo_state

    })
    connect(g_game, {
        onGameStart = StatsBar.OnGameStart,
        onGameEnd = StatsBar.OnGameEnd
    })
end

function StatsBar.terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onHealthChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onManaChange = StatsBar.reloadCurrentStatsBarQuickInfo,
        onMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseMagicLevelChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onBaseSkillChange = StatsBar.reloadCurrentStatsBarDeepInfo,
        onStatesChange = StatsBar.reloadCurrentStatsBarQuickInfo_state
    })
    disconnect(g_game, {
        onGameStart = StatsBar.OnGameStart,
        OnGameEnd = StatsBar.OnGameEnd
    })
    statsBar:destroy()
end
