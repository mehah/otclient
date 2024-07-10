-- LuaFormatter off
--@ array
local ScreenshotType = {
    NONE = 0,
    ACHIEVEMENT = 1,
    BESTIARY_ENTRY_COMPLETED = 2,
    BESTIARY_ENTRY_UNLOCKED = 3,
    BOSS_DEFEATED = 4,
    DEATH_PVE = 5,
    DEATH_PVP = 6,
    LEVEL_UP = 7,
    PLAYER_KILL_ASSIST = 8,
    PLAYER_KILL = 9,
    PLAYER_ATTACKING = 10,
    TREASURE_FOUND = 11,
    SKILL_UP = 12,
    HIGHEST_DAMAGE_DEALT = 13,
    HIGHEST_HEALING_DONE = 14,
    LOW_HEALTH = 15,
    GIFT_OF_LIFE_TRIGGERED = 16
}
local checkboxes = {}
local TypeScreenshots = {}
local AutoScreenshotEvents = {
    {id = ScreenshotType.LEVEL_UP, label = "Level Up", enableDefault = true},
    {id = ScreenshotType.SKILL_UP, label = "Skill Up", enableDefault = true},
    {id = ScreenshotType.ACHIEVEMENT, label = "Achievement", enableDefault = true},
    {id = ScreenshotType.BESTIARY_ENTRY_UNLOCKED, label = "Bestiary Entry Unlocked", enableDefault = false},
    {id = ScreenshotType.BESTIARY_ENTRY_COMPLETED, label = "Bestiary Entry Completed", enableDefault = false},
    {id = ScreenshotType.TREASURE_FOUND, label = "Treasure Found", enableDefault = false},
    {id = -99, label = "Valuable Loot", enableDefault = false},
    {id = ScreenshotType.BOSS_DEFEATED, label = "Boss Defeated", enableDefault = false},
    {id = ScreenshotType.DEATH_PVE, label = "Death PvE", enableDefault = true},
    {id = ScreenshotType.DEATH_PVP, label = "Death PvP", enableDefault = false},
    {id = ScreenshotType.PLAYER_KILL, label = "Player Kill", enableDefault = false},
    {id = ScreenshotType.PLAYER_KILL_ASSIST, label = "Player Kill Assist", enableDefault = false},
    {id = ScreenshotType.PLAYER_ATTACKING, label = "Player Attacking", enableDefault = false},
    {id = ScreenshotType.HIGHEST_DAMAGE_DEALT, label = "Highest Damage Dealt", enableDefault = false},
    {id = ScreenshotType.HIGHEST_HEALING_DONE, label = "Highest Healing Done", enableDefault = false},
    {id = ScreenshotType.LOW_HEALTH, label = "Low Health", enableDefault = false},
    {id = ScreenshotType.GIFT_OF_LIFE_TRIGGERED, label = "Gift of Life Triggered", enableDefault = true}
}
-- LuaFormatter on

-- @ widget
local evento
-- @
-- @ variables
local autoScreenshotDirName = "auto_screenshots"
local autoScreenshotDir = g_resources.getWriteDir() .. "/" .. autoScreenshotDirName

-- @

screenshotController = Controller:new()

function screenshotController:onInit()

end

function screenshotController:onTerminate()
    destroyOptionsModule()

    if evento then
        removeEvent(evento)
        evento = nil
    end
end

function screenshotController:onGameStart()

    if g_game.getClientVersion() < 1310 then
        return
    end
    optionPanel = g_ui.loadUI('game_screenshot')
    modules.client_options.addTab('Screenshot', optionPanel, '/images/icons/icon_misc')

    for _, temp in ipairs(AutoScreenshotEvents) do
        local label = g_ui.createWidget("ScreenshotType", optionPanel.allCheckBox)
        local settingKey = temp.label:gsub("%s+", "")
        local setings = g_settings.getBoolean(settingKey)
        label.text:setText(temp.label)
        label.enabled:setChecked(setings)
        label.enabled:setId(temp.id)
        temp.currentBoolean = setings

    end

    if not g_resources.directoryExists(autoScreenshotDir) then
        g_resources.makeDir(autoScreenshotDirName)
    end

    -- is g_game or LocalPlayer ?
    screenshotController:registerEvents(LocalPlayer, {
        onTakeScreenshot = onScreenShot
    })
end

function screenshotController:onGameEnd()
    if g_game.getClientVersion() >= 1310 then
        modules.client_options.removeTab('Screenshot')
    end
    if evento then
        removeEvent(evento)
        evento = nil
    end
    for _, evento in ipairs(AutoScreenshotEvents) do
        local labelSinEspacios = evento.label:gsub("%s+", "")
        g_settings.set(labelSinEspacios, evento.currentBoolean)
    end

end

function onUICheckBox(widget, checked)
    if not widget then
        return
    end
    local id = tonumber(widget:getId())
    for _, temp in ipairs(AutoScreenshotEvents) do
        if temp.id == id then
            temp.currentBoolean = checked
            break
        end
    end

end

-- LuaFormatter off
function resetValues()
    for _, evento in ipairs(AutoScreenshotEvents) do
        local labelSinEspacios = evento.label:gsub("%s+", "")
        g_settings.set(labelSinEspacios, evento.currentBoolean)

    end

    for _, i in pairs(optionPanel.allCheckBox:getChildren()) do
        for _, j in pairs(i:getChildren()) do
            if j:getStyle().__class == 'UICheckBox' then
                local id = tonumber(j:getId())
                if id then
                    for _, evento in ipairs(AutoScreenshotEvents) do
                        if evento.id == id then
        --      hadouken                            
                            j:setChecked(evento.enableDefault)
                            break
                        end
                    end
                end
            end
        end
    end

end
-- LuaFormatter on

function destroyOptionsModule()
    modules.client_options.removeTab('Screenshot')
    optionPanel = nil
end

function onScreenShot(type)

    if not optionPanel.Opciones3.enableScreenshots:isChecked() then
        return
    end
    local name = g_game.getLocalPlayer():getName()
    local level = g_game.getLocalPlayer():getLevel() or 1
    for _, evento in ipairs(AutoScreenshotEvents) do
        if evento.id == type and evento.currentBoolean then

            local screenshotName = name .. level .. "_" .. evento.label:gsub("%s+", "") .. "_" ..
                                       os.date("%Y%m%d%H%M%S") .. ".png"
            takeScreenshot("/" .. autoScreenshotDirName .. "/" .. screenshotName)

            return
        end
    end

end
function takeScreenshot(name)

    if not g_game.isOnline() then
        return
    end

    if evento then
        removeEvent(evento)
        evento = nil
    end

    evento = scheduleEvent(function()
        g_app.doScreenshot(name)
    end, 50)
end

function OpenFolder()
    local dir = g_resources.getWriteDir():gsub("[/\\]+", "\\") .. autoScreenshotDirName
    g_platform.openDir(dir)
end

