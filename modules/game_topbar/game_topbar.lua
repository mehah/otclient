-------------------------------------------------
-- Game Topbar Module
-- Options panel for health circle and stats bar
-------------------------------------------------

optionPanel = nil
healthCheckBox = nil
manaCheckBox = nil
experienceCheckBox = nil
skillCheckBox = nil
chooseSkillComboBox = nil
chooseStatsBarDimension = nil
chooseStatsBarPlacement = nil
distFromCenScrollbar = nil
opacityScrollbar = nil

statsBarMenuLoaded = false

function init()
    addToOptionsModule()

    connect(g_game, {
        onGameStart = setPlayerValues
    })
end

function terminate()
    destroyOptionsModule()

    disconnect(g_game, {
        onGameStart = setPlayerValues
    })
end

-------------------------------------------------
-- Option Settings
-------------------------------------------------

function addToOptionsModule()
    optionPanel = g_ui.loadUI('option_topbar', modules.client_options:getPanel())

    -- UI values
    healthCheckBox = optionPanel:recursiveGetChildById('healthCheckBox')
    manaCheckBox = optionPanel:recursiveGetChildById('manaCheckBox')
    experienceCheckBox = optionPanel:recursiveGetChildById('experienceCheckBox')
    skillCheckBox = optionPanel:recursiveGetChildById('skillCheckBox')
    chooseSkillComboBox = optionPanel:recursiveGetChildById('chooseSkillComboBox')
    chooseStatsBarDimension = optionPanel:recursiveGetChildById('chooseStatsBarDimension')
    chooseStatsBarPlacement = optionPanel:recursiveGetChildById('chooseStatsBarPlacement')
    distFromCenScrollbar = optionPanel:recursiveGetChildById('distFromCenScrollbar')
    opacityScrollbar = optionPanel:recursiveGetChildById('opacityScrollbar')

    -- ComboBox start values
    chooseSkillComboBox:addOption('Magic Level', 'magic')
    chooseSkillComboBox:addOption('Fist Fighting', 'fist')
    chooseSkillComboBox:addOption('Club Fighting', 'club')
    chooseSkillComboBox:addOption('Sword Fighting', 'sword')
    chooseSkillComboBox:addOption('Axe Fighting', 'axe')
    chooseSkillComboBox:addOption('Distance Fighting', 'distance')
    chooseSkillComboBox:addOption('Shielding', 'shielding')
    chooseSkillComboBox:addOption('Fishing', 'fishing')

    chooseStatsBarPlacement:addOption(tr('Top'), 'top')
    chooseStatsBarPlacement:addOption(tr('Bottom'), 'bottom')

    chooseStatsBarDimension:addOption(tr('Hide'), 'hide')
    chooseStatsBarDimension:addOption(tr('Compact'), 'compact')
    chooseStatsBarDimension:addOption(tr('Default'), 'default')
    chooseStatsBarDimension:addOption(tr('Large'), 'large')
    chooseStatsBarDimension:addOption(tr('Parallel'), 'parallel')

    statsBarMenuLoaded = true

    chooseStatsBarDimension:setCurrentOptionByData(g_settings.getString('statsbar_dimension'), true)
    chooseStatsBarPlacement:setCurrentOptionByData(g_settings.getString('statsbar_placement'), true)

    -- Set values from healthcircle module
    local healthcircle = modules.game_healthcircle
    healthCheckBox:setChecked(healthcircle.isHealthCircle)
    manaCheckBox:setChecked(healthcircle.isManaCircle)
    experienceCheckBox:setChecked(healthcircle.isExpCircle)
    skillCheckBox:setChecked(healthcircle.isSkillCircle)

    -- Notify healthcircle that skills are loaded
    healthcircle.skillsLoaded = true

    distFromCenScrollbar:setValue(healthcircle.distanceFromCenter)
    opacityScrollbar:setValue(healthcircle.opacityCircle * 100)
    modules.client_options.addButton("Interface", "HP/MP Circle", optionPanel)
end

function updateStatsBar()
    if statsBarMenuLoaded then
        modules.game_interface.updateStatsBar(chooseStatsBarDimension:getCurrentOption().data,
            chooseStatsBarPlacement:getCurrentOption().data)
    end
end

function setPlayerValues()
    local healthcircle = modules.game_healthcircle
    local skillType = healthcircle.skillTypes[g_game.getCharacterName()]
    if not skillType then
        skillType = 'magic'
    end
    chooseSkillComboBox:setCurrentOptionByData(skillType, true)
end

function setStatsBarOption(dimension, placement)
    if dimension then
        chooseStatsBarDimension:setCurrentOptionByData(dimension, true)
    end
    if placement then
        chooseStatsBarPlacement:setCurrentOptionByData(placement, true)
    end
end

function destroyOptionsModule()
    healthCheckBox = nil
    manaCheckBox = nil
    experienceCheckBox = nil
    skillCheckBox = nil
    chooseSkillComboBox = nil
    distFromCenScrollbar = nil
    opacityScrollbar = nil
    chooseStatsBarDimension = nil
    chooseStatsBarPlacement = nil

    modules.client_options.removeButton("Interface", "HP/MP Circle")
    optionPanel = nil
    statsBarMenuLoaded = false
end

-- Getters for external access
function getOptionPanel()
    return optionPanel
end

function isStatsBarMenuLoaded()
    return statsBarMenuLoaded
end
