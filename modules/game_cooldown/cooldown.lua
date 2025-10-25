local ProgressCallback = {
    update = 1,
    finish = 2
}

cooldownWindow = nil

contentsPanel = nil
cooldownPanel = nil
lastPlayer = nil

cooldown = {}
groupCooldown = {}

function init()
    connect(g_game, {
        onGameEnd = offline,
        onGameStart = online,
        onSpellGroupCooldown = onSpellGroupCooldown,
        onSpellCooldown = onSpellCooldown
    })

    if modules.client_options.getOption('showSpellGroupCooldowns') then
        modules.client_options.setOption('showSpellGroupCooldowns', true)
    else
        modules.client_options.setOption('showSpellGroupCooldowns', false)
    end

    cooldownWindow = g_ui.loadUI('cooldown', modules.game_interface.getBottomPanel())
    contentsPanel = cooldownWindow:getChildById('contentsPanel2')
    cooldownPanel = contentsPanel:getChildById('cooldownPanel')

    -- preload cooldown images
    for k, v in pairs(SpelllistSettings) do
        g_textures.preload(v.iconFile)
        g_textures.preload(v.iconsForGameCooldown)
    end

    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(g_game, {
        onGameEnd = offline,
        onGameStart = online,
        onSpellGroupCooldown = onSpellGroupCooldown,
        onSpellCooldown = onSpellCooldown
    })

    cooldownWindow:destroy()

end

function loadIcon(iconId)
    local spell, profile, spellName = Spells.getSpellByIcon(iconId)
    if not spellName then
        print('[WARNING] loadIcon: empty spellName for server spell id: ' .. iconId)
        return nil, nil
    end
    if not profile then
        print('[WARNING] loadIcon: empty profile for server spell id: ' .. iconId)
        return nil, nil
    end

    local icon = cooldownPanel:getChildById(iconId)
    if not icon then
        icon = g_ui.createWidget('SpellIcon')
        icon:setId(iconId)
    end

    local spellSettings = SpelllistSettings[profile]
    if spellSettings then
        icon:setImageSource(spellSettings.iconsForGameCooldown)
        icon:setImageClip(Spells.getImageClipCooldown(spell.clientId, profile))
        icon.spellName = spellName
        local progressRect = icon:getChildById(iconId)
        local isNewProgressRect = false
        if not progressRect then
            progressRect = g_ui.createWidget('SpellProgressRect', icon)
            progressRect:setId(iconId)
            progressRect:fill('parent')
            isNewProgressRect = true
        end
        progressRect.icon = icon
        progressRect:setTooltip(spellName .. " (" .. (spell.exhaustion / 1000) .. " sec. cooldown)")
        if isNewProgressRect then
            progressRect:setPercent(0)
        end
    else
        print('[WARNING] loadIcon: empty spell icon for server spell id: ' .. iconId)
        icon = nil
    end
    return icon, spellName
end

function onMiniWindowOpen()
    modules.client_options.setOption('showSpellGroupCooldowns', true)
end

function onMiniWindowClose()
    modules.client_options.setOption('showSpellGroupCooldowns', false)
end

function online()
    local console = modules.game_console.consolePanel
    if console then
        console:addAnchor(AnchorTop, cooldownWindow:getId(), AnchorBottom)
    end
    if not g_game.getFeature(GameSpellList) then
        modules.client_options.setOption('showSpellGroupCooldowns', false)
        return
    end

    if not lastPlayer or lastPlayer ~= g_game.getCharacterName() then
        refresh()
        lastPlayer = g_game.getCharacterName()
    end
end

function offline()
    local console = modules.game_console.consolePanel
    if console then
        console:removeAnchor(AnchorTop)
        console:fill('parent')
    end
    if g_game.getFeature(GameSpellList) then
        --cooldownWindow:setParent(nil, true)
   
    end
end

function refresh()
    if cooldownPanel then
        cooldownPanel:destroyChildren()
    end
end

function removeCooldown(progressRect)
    removeEvent(progressRect.event)
    if progressRect.icon then
        progressRect.icon:destroy()
        progressRect.icon = nil
    end
    progressRect = nil
end

function turnOffCooldown(progressRect)
    removeEvent(progressRect.event)
    progressRect.event = nil
    progressRect.callback = nil
    if progressRect.icon then
        progressRect.icon:setOn(false)
        progressRect.icon = nil
    end

    -- create particles
    --[[local particle = g_ui.createWidget('GroupCooldownParticles', progressRect)
  particle:fill('parent')
  scheduleEvent(function() particle:destroy() end, 1000) -- hack until onEffectEnd]]

    progressRect = nil
end

function initCooldown(progressRect, updateCallback, finishCallback)
    progressRect:setPercent(0)

    progressRect.callback = {}
    progressRect.callback[ProgressCallback.update] = updateCallback
    progressRect.callback[ProgressCallback.finish] = finishCallback

    updateCallback()
end

function updateCooldown(progressRect, duration)
    if not progressRect or progressRect:isDestroyed() then
        return
    end

    local callbacks = progressRect.callback
    if not callbacks then
        return
    end
    progressRect:setPercent(progressRect:getPercent() + 10000 / duration)

    if progressRect:getPercent() < 100 then
        removeEvent(progressRect.event)
        local updateCallback = callbacks[ProgressCallback.update]
        if not updateCallback then
            return
        end
        progressRect.event = scheduleEvent(function()
            if progressRect and not progressRect:isDestroyed() and progressRect.callback then
                updateCallback()
            end
        end, 100)
    else
        local finishCallback = callbacks[ProgressCallback.finish]
        if finishCallback then
            finishCallback()
        end
    end
end

function isGroupCooldownIconActive(groupId)
    return groupCooldown[groupId]
end

function isCooldownIconActive(iconId)
    return cooldown[iconId]
end

function onSpellCooldown(iconId, duration)
    if not cooldownWindow:isVisible() then
        return
    end
    local icon, spellName = loadIcon(iconId)
    if not icon then
        print('[WARNING] Can not load cooldown icon on spell with id: ' .. iconId)
        return
    end
    icon:setParent(cooldownPanel)

    local progressRect = icon:getChildById(iconId)
    if not progressRect then
        progressRect = g_ui.createWidget('SpellProgressRect', icon)
        progressRect:setId(iconId)
        progressRect:fill('parent')
    end
    progressRect.icon = icon
    progressRect:setPercent(0)

    local updateFunc = function()
        updateCooldown(progressRect, duration)
    end
    local finishFunc = function()
        removeCooldown(progressRect)
        cooldown[iconId] = false
    end
    initCooldown(progressRect, updateFunc, finishFunc)
    cooldown[iconId] = true
end

function onSpellGroupCooldown(groupId, duration)
    if not cooldownWindow:isVisible() then
        return
    end
    if not SpellGroups[groupId] then
        return
    end

    --print('onSpellGroupCooldown: ' .. groupId)
    local icon = contentsPanel:getChildById('groupIcon' .. SpellGroups[groupId])
    --print("Progress Rect: " .. 'progressRect' .. SpellGroups[groupId])
    local progressRect = contentsPanel:getChildById('progressRect' .. SpellGroups[groupId])
    if icon then
        icon:setOn(true)
        removeEvent(icon.event)
    end

    if progressRect then
        progressRect.icon = icon
        removeEvent(progressRect.event)
        local updateFunc = function()
            updateCooldown(progressRect, duration)
        end
        local finishFunc = function()
            turnOffCooldown(progressRect)
            groupCooldown[groupId] = false
        end
        initCooldown(progressRect, updateFunc, finishFunc)
        groupCooldown[groupId] = true
    end
end

function setSpellGroupCooldownsVisible(visible)
    if visible then
        cooldownWindow:setHeight(30)
        cooldownWindow:show()
    else
        cooldownWindow:hide()
        cooldownWindow:setHeight(10)
    end
end
