imageSizeBroad = 0
imageSizeThin = 0

mapPanel = modules.game_interface.getMapPanel()
gameRootPanel = modules.game_interface.gameBottomPanel
gameLeftPanel = modules.game_interface.getLeftPanel()
gameTopMenu = modules.client_topmenu.getTopMenu()

function currentViewMode()
    return modules.game_interface.currentViewMode
end

healthCircle = nil
manaCircle = nil
manaShieldCircle = nil
manaShieldCircleFront = nil
expCircle = nil
skillCircle = nil

healthCircleFront = nil
manaCircleFront = nil
expCircleFront = nil
skillCircleFront = nil

manaShieldImageSizeBroad = 0
manaShieldImageSizeThin = 0
manaShieldCircleOffsetX = -52
manaShieldCircleOffsetY = 7

isHealthCircle = not g_settings.getBoolean('healthcircle_hpcircle')
isManaCircle = not g_settings.getBoolean('healthcircle_mpcircle')
isExpCircle = g_settings.getBoolean('healthcircle_expcircle')
isSkillCircle = g_settings.getBoolean('healthcircle_skillcircle')
skillTypes = g_settings.getNode('healthcircle_skilltypes')
skillsLoaded = false

if not skillTypes then
    skillTypes = {}
end

distanceFromCenter = g_settings.getNumber('healthcircle_distfromcenter')
opacityCircle = g_settings.getNumber('healthcircle_opacity', 0.35)

function init()
    g_ui.importStyle("game_healthcircle.otui")
    healthCircle = g_ui.createWidget('HealthCircle', mapPanel)
    manaCircle = g_ui.createWidget('ManaCircle', mapPanel)
    manaShieldCircle = g_ui.createWidget('ManaShieldCircle', mapPanel)
    expCircle = g_ui.createWidget('ExpCircle', mapPanel)
    skillCircle = g_ui.createWidget('SkillCircle', mapPanel)

    healthCircleFront = g_ui.createWidget('HealthCircleFront', mapPanel)
    manaCircleFront = g_ui.createWidget('ManaCircleFront', mapPanel)
    manaShieldCircleFront = g_ui.createWidget('ManaShieldCircleFront', mapPanel)
    expCircleFront = g_ui.createWidget('ExpCircleFront', mapPanel)
    skillCircleFront = g_ui.createWidget('SkillCircleFront', mapPanel)

    imageSizeBroad = healthCircle:getHeight()
    imageSizeThin = healthCircle:getWidth()
    manaShieldImageSizeBroad = manaShieldCircle:getHeight()
    manaShieldImageSizeThin = manaShieldCircle:getWidth()
    manaShieldCircle:setVisible(false)
    manaShieldCircleFront:setVisible(false)

    whenMapResizeChange()
    initOnHpAndMpChange()
    initOnGeometryChange()
    initOnLoginChange()

    if not isHealthCircle then
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
    end

    if not isManaCircle then
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
    end

    if not isExpCircle then
        expCircle:setVisible(false)
        expCircleFront:setVisible(false)
    end

    if not isSkillCircle then
        skillCircle:setVisible(false)
        skillCircleFront:setVisible(false)
    end

    connect(g_game, {
        onGameStart = onGameStart
    })
end

function terminate()
    healthCircle:destroy()
    healthCircle = nil
    manaCircle:destroy()
    manaCircle = nil
    manaShieldCircle:destroy()
    manaShieldCircle = nil
    expCircle:destroy()
    expCircle = nil
    skillCircle:destroy()
    skillCircle = nil

    healthCircleFront:destroy()
    healthCircleFront = nil
    manaCircleFront:destroy()
    manaCircleFront = nil
    manaShieldCircleFront:destroy()
    manaShieldCircleFront = nil
    expCircleFront:destroy()
    expCircleFront = nil
    skillCircleFront:destroy()
    skillCircleFront = nil

    terminateOnHpAndMpChange()
    terminateOnGeometryChange()
    terminateOnLoginChange()

    disconnect(g_game, {
        onGameStart = onGameStart
    })
end

-------------------------------------------------
-- Scripts----------------------------------------
-------------------------------------------------

function initOnHpAndMpChange()
    connect(LocalPlayer, {
        onHealthChange = whenHealthChange,
        onManaChange = whenManaChange,
        onSkillChange = whenSkillsChange,
        onManaShieldChange = whenManaShieldChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange
    })
end

function terminateOnHpAndMpChange()
    disconnect(LocalPlayer, {
        onHealthChange = whenHealthChange,
        onManaChange = whenManaChange,
        onSkillChange = whenSkillsChange,
        onManaShieldChange = whenManaShieldChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange
    })
end

function initOnGeometryChange()
    connect(mapPanel, {
        onGeometryChange = whenMapResizeChange
    })
end

function terminateOnGeometryChange()
    disconnect(mapPanel, {
        onGeometryChange = whenMapResizeChange
    })
end

function initOnLoginChange()
    connect(g_game, {
        onGameStart = whenMapResizeChange
    })
end

function terminateOnLoginChange()
    disconnect(g_game, {
        onGameStart = whenMapResizeChange
    })
end

function whenHealthChange()
    if g_game.isOnline() then
        -- Fix By TheMaoci ~ if your server doesn't have this properly implemented,
        -- it will cause alot of unnecessary deaths from players which will be unfair.
        -- My friend reported me that while he was using his otcv8 and asked for a fix so here you go :)
        local healthPercent = math.floor(g_game.getLocalPlayer():getHealth() / g_game.getLocalPlayer():getMaxHealth() *
            100)
        -- Old leaved for ppl who have that implemented correctly
        --local healthPercent = math.floor(g_game.getLocalPlayer():getHealthPercent())

        local yhppc = math.floor(imageSizeBroad * (1 - (healthPercent / 100)))
        local restYhppc = imageSizeBroad - yhppc

        healthCircleFront:setY(healthCircle:getY() + yhppc)
        healthCircleFront:setHeight(restYhppc)
        healthCircleFront:setImageClip({
            x = 0,
            y = yhppc,
            width = imageSizeThin,
            height = restYhppc
        })

        healthCircle:setHeight(yhppc)
        healthCircle:setImageClip({
            x = 0,
            y = 0,
            width = imageSizeThin,
            height = yhppc
        })

        if healthPercent > 92 then
            healthCircleFront:setImageColor('#00BC00')
        elseif healthPercent > 60 then
            healthCircleFront:setImageColor('#50A150')
        elseif healthPercent > 30 then
            healthCircleFront:setImageColor('#A1A100')
        elseif healthPercent > 8 then
            healthCircleFront:setImageColor('#BF0A0A')
        elseif healthPercent > 3 then
            healthCircleFront:setImageColor('#910F0F')
        else
            healthCircleFront:setImageColor('#850C0C')
        end
    end
end

local defaultManaCircleEmpty = '/data/images/game/healthcircle/right_empty'
local defaultManaCircleFull = '/data/images/game/healthcircle/right_full'
local defaultManaWithManaShieldCircleEmpty = '/data/images/game/healthcircle/right_tiny_empty'
local defaultManaWithManaShieldCircleFull = '/data/images/game/healthcircle/right_tiny_full'
local manaShieldManaCircleEmpty = '/data/images/game/healthcircle/right_extra_empty'
local manaShieldManaCircleFull = '/data/images/game/healthcircle/right_extra_full'

local function resetManaCircleImages()
    if manaCircle then
        manaCircle:setImageSource(defaultManaCircleEmpty)
    end

    if manaCircleFront then
        manaCircleFront:setImageSource(defaultManaCircleFull)
    end
end

local function updateManaShieldDisplay()
    if not manaShieldCircle or not manaShieldCircleFront or not manaCircle or not manaCircleFront then
        return
    end

    if not g_game.isOnline() or not isManaCircle then
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
        resetManaCircleImages()
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local maxShield = player:getMaxManaShield()
    local remainingShield = player:getManaShield()

    if remainingShield <= 0 then
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
        resetManaCircleImages()
        return
    end

    if maxShield <= 0 then
        maxShield = remainingShield
    end

    manaCircle:setImageSource(defaultManaWithManaShieldCircleEmpty)
    manaCircleFront:setImageSource(defaultManaWithManaShieldCircleFull)
    manaShieldCircle:setImageSource(manaShieldManaCircleEmpty)
    manaShieldCircleFront:setImageSource(manaShieldManaCircleFull)
    manaShieldCircle:setVisible(true)
    manaShieldCircleFront:setVisible(true)

    local clampedShield = math.max(math.min(remainingShield, maxShield), 0)
    local shieldPercent = clampedShield / maxShield

    local emptyPixels = math.floor(manaShieldImageSizeBroad * (1 - shieldPercent))
    if emptyPixels < 0 then
        emptyPixels = 0
    end
    if emptyPixels > manaShieldImageSizeBroad then
        emptyPixels = manaShieldImageSizeBroad
    end

    local filledPixels = manaShieldImageSizeBroad - emptyPixels

    manaShieldCircleFront:setY(manaShieldCircle:getY() + emptyPixels)
    manaShieldCircleFront:setHeight(filledPixels)
    manaShieldCircleFront:setImageClip({
        x = 0,
        y = emptyPixels,
        width = manaShieldImageSizeThin,
        height = filledPixels
    })

    manaShieldCircle:setHeight(emptyPixels)
    manaShieldCircle:setImageClip({
        x = 0,
        y = 0,
        width = manaShieldImageSizeThin,
        height = emptyPixels
    })
end

function whenManaShieldChange()
    updateManaShieldDisplay()
end

function whenManaChange()
    if g_game.isOnline() then
        local player = g_game.getLocalPlayer()
        local maxMana = player:getMaxMana()
        if maxMana <= 0 then
            manaCircle:setVisible(false)
            manaCircleFront:setVisible(false)
            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setVisible(false)
                manaShieldCircleFront:setVisible(false)
            end
            resetManaCircleImages()
            return
        elseif isManaCircle then
            manaCircle:setVisible(true)
            manaCircleFront:setVisible(true)
        end

        updateManaShieldDisplay()

        local manaPercent = math.floor(maxMana - (maxMana - player:getMana())) * 100 / maxMana

        local ymppc = math.floor(imageSizeBroad * (1 - (manaPercent / 100)))
        local restYmppc = imageSizeBroad - ymppc
        if restYmppc <= 0 then
            manaCircleFront:setVisible(false)
        else
            manaCircleFront:setVisible(isManaCircle)

            if isManaCircle then
                manaCircleFront:setY(manaCircle:getY() + ymppc)
                manaCircleFront:setHeight(restYmppc)
                manaCircleFront:setImageClip({
                    x = 0,
                    y = ymppc,
                    width = imageSizeThin,
                    height = restYmppc
                })
            end
        end

        manaCircle:setHeight(ymppc)
        manaCircle:setImageClip({
            x = 0,
            y = 0,
            width = imageSizeThin,
            height = ymppc
        })
    end
end

function whenSkillsChange()
    if g_game.isOnline() then
        if isExpCircle then
            local player = g_game.getLocalPlayer()
            local Xexpc = math.floor(imageSizeBroad * (1 - player:getLevelPercent() / 100))

            expCircleFront:setImageClip({
                x = 0,
                y = 0,
                width = imageSizeBroad - Xexpc,
                height = imageSizeThin
            })
            expCircleFront:setWidth(imageSizeBroad - Xexpc)

            expCircle:setImageClip({
                x = imageSizeBroad - Xexpc,
                y = 0,
                width = Xexpc,
                height = imageSizeThin
            })
            expCircle:setWidth(Xexpc)
            expCircle:setX(expCircleFront:getX() + expCircleFront:getWidth())
        end

        if isSkillCircle then
            local player = g_game.getLocalPlayer()

            local skillPercent
            local skillColor
            local skillType = skillTypes[player:getName()]

            if skillType == 'fist' then
                skillPercent = player:getSkillLevelPercent(0)
                skillColor = '#9900cc'
            elseif skillType == 'club' then
                skillPercent = player:getSkillLevelPercent(1)
                skillColor = '#cc3399'
            elseif skillType == 'sword' then
                skillPercent = player:getSkillLevelPercent(2)
                skillColor = '#FF7F00'
            elseif skillType == 'axe' then
                skillPercent = player:getSkillLevelPercent(3)
                skillColor = '#696969'
            elseif skillType == 'distance' then
                skillPercent = player:getSkillLevelPercent(4)
                skillColor = '#A62A2A'
            elseif skillType == 'shielding' then
                skillPercent = player:getSkillLevelPercent(5)
                skillColor = '#663300'
            elseif skillType == 'fishing' then
                skillPercent = player:getSkillLevelPercent(6)
                skillColor = '#ffff33'
            else
                -- default skill: MAGIC
                skillPercent = player:getMagicLevelPercent()
                skillColor = '#00ffcc'
            end

            local Xskpc = math.floor(imageSizeBroad * (1 - skillPercent / 100))
            skillCircleFront:setImageColor(skillColor)

            skillCircleFront:setImageClip({
                x = 0,
                y = 0,
                width = imageSizeBroad - Xskpc,
                height = imageSizeThin
            })
            skillCircleFront:setWidth(imageSizeBroad - Xskpc)

            skillCircle:setImageClip({
                x = imageSizeBroad - Xskpc,
                y = 0,
                width = Xskpc,
                height = imageSizeThin
            })
            skillCircle:setWidth(Xskpc)
            skillCircle:setX(skillCircleFront:getX() + skillCircleFront:getWidth())
        end
    end
end

function whenMapResizeChange()
    if g_game.isOnline() then
        local barDistance = 90
        if not (math.floor(mapPanel:getHeight() / 2 * 0.2) < 100) then -- 0.381
            barDistance = math.floor(mapPanel:getHeight() / 2 * 0.2)
        end

        if currentViewMode() == 2 then
            healthCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - barDistance - imageSizeThin) -
                distanceFromCenter)
            manaCircleFront:setX(math.floor(mapPanel:getWidth() / 2 + barDistance) + distanceFromCenter)

            healthCircle:setX(math.floor(mapPanel:getWidth() / 2 - barDistance - imageSizeThin) - distanceFromCenter)
            manaCircle:setX(math.floor((mapPanel:getWidth() / 2 + barDistance)) + distanceFromCenter)

            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setX(manaCircle:getX() - manaShieldImageSizeThin - manaShieldCircleOffsetX)
                manaShieldCircleFront:setX(manaShieldCircle:getX())
            end

            healthCircle:setY(mapPanel:getHeight() / 2 - imageSizeBroad / 2 + 0)
            manaCircle:setY(mapPanel:getHeight() / 2 - imageSizeBroad / 2 + 0)

            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setY(manaCircle:getY() + manaShieldCircleOffsetY)
                manaShieldCircleFront:setY(manaShieldCircle:getY())
            end

            if isExpCircle then
                expCircleFront:setY(math.floor(mapPanel:getHeight() / 2 - barDistance - imageSizeThin) -
                    distanceFromCenter)

                expCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - imageSizeBroad / 2))
                expCircle:setY(math.floor(mapPanel:getHeight() / 2 - barDistance - imageSizeThin) - distanceFromCenter)
            end

            if isSkillCircle then
                skillCircleFront:setY(math.floor(mapPanel:getHeight() / 2 + barDistance) + distanceFromCenter)

                skillCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - imageSizeBroad / 2))
                skillCircle:setY(math.floor(mapPanel:getHeight() / 2 + barDistance) + distanceFromCenter)
            end
        else
            healthCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - barDistance -
                distanceFromCenter)
            manaCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 + barDistance + distanceFromCenter)

            healthCircle:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - barDistance -
                distanceFromCenter)
            manaCircle:setX(mapPanel:getX() + mapPanel:getWidth() / 2 + barDistance + distanceFromCenter)

            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setX(manaCircle:getX() - manaShieldImageSizeThin - manaShieldCircleOffsetX)
                manaShieldCircleFront:setX(manaShieldCircle:getX())
            end

            healthCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2)
            manaCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2)

            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setY(manaCircle:getY() + manaShieldCircleOffsetY)
                manaShieldCircleFront:setY(manaShieldCircle:getY())
            end

            if isExpCircle then
                expCircleFront:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeThin - barDistance -
                    distanceFromCenter)

                expCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeBroad / 2)
                expCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeThin - barDistance -
                    distanceFromCenter)
            end

            if isSkillCircle then
                skillCircleFront:setY(mapPanel:getY() + mapPanel:getHeight() / 2 + barDistance + distanceFromCenter)

                skillCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeBroad / 2)
                skillCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 + barDistance + distanceFromCenter)
            end
        end

        whenHealthChange()
        whenManaChange()
        if isExpCircle or isSkillCircle then
            whenSkillsChange()
        end
    end

    updateManaShieldDisplay()
end

-------------------------------------------------
-- Controls---------------------------------------
-------------------------------------------------

function setHealthCircle(value)
    value = toboolean(value)
    isHealthCircle = value
    if value then
        healthCircle:setVisible(true)
        healthCircleFront:setVisible(true)
        whenMapResizeChange()
        updateManaShieldDisplay()
    else
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setVisible(false)
            manaShieldCircleFront:setVisible(false)
        end
        resetManaCircleImages()
    end

    g_settings.set('healthcircle_hpcircle', not value)
end

function setManaCircle(value)
    value = toboolean(value)
    isManaCircle = value
    if value then
        manaCircle:setVisible(true)
        manaCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_mpcircle', not value)
end

function setExpCircle(value)
    value = toboolean(value)
    isExpCircle = value

    if value then
        expCircle:setVisible(true)
        expCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        expCircle:setVisible(false)
        expCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_expcircle', value)
end

function setSkillCircle(value)
    value = toboolean(value)
    isSkillCircle = value

    if value then
        skillCircle:setVisible(true)
        skillCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        skillCircle:setVisible(false)
        skillCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_skillcircle', value)
end

function setSkillType(skill)
    if not skillsLoaded then
        return
    end

    local char = g_game.getCharacterName()
    local skillType = skillTypes[char]

    skillTypes[char] = skill
    whenMapResizeChange()
    g_settings.setNode('healthcircle_skilltypes', skillTypes)
end

function setDistanceFromCenter(value)
    distanceFromCenter = value
    whenMapResizeChange()

    g_settings.set('healthcircle_distfromcenter', value)
end

function setCircleOpacity(value)
    healthCircle:setOpacity(value)
    healthCircleFront:setOpacity(value)
    manaCircle:setOpacity(value)
    manaCircleFront:setOpacity(value)
    if manaShieldCircle then
        manaShieldCircle:setOpacity(value)
    end
    if manaShieldCircleFront then
        manaShieldCircleFront:setOpacity(value)
    end
    expCircle:setOpacity(value)
    expCircleFront:setOpacity(value)
    skillCircle:setOpacity(value)
    skillCircleFront:setOpacity(value)

    g_settings.set('healthcircle_opacity', value)
end

-------------------------------------------------
-- Game Events
-------------------------------------------------

function onGameStart()
    whenMapResizeChange()
end
