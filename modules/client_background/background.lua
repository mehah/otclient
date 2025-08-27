-- private variables
local background
local clientVersionLabel
local bgEffectEvent = nil
local toggleState = true  -- controls which effect  is active
local timeLoopBackgroundEffect = 5000 -- 5 seconds

-- public functions
function init()
    background = g_ui.displayUI('background')
    background:lower()

    clientVersionLabel = background:getChildById('clientVersionLabel')
    clientVersionLabel:setText(g_app.getName() .. ' ' .. g_app.getVersion() .. '\n' .. 'Rev  ' ..
                                   g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ')\n' .. 'Built on ' ..
                                   g_app.getBuildDate() .. '\n' .. g_app.getBuildCompiler() .. ' - ' ..
                                   g_app.getBuildArch())

    if not g_game.isOnline() then
        addEvent(function()
            g_effects.fadeIn(clientVersionLabel, 1500)
        end)
    end

    connect(g_game, {
        onGameStart = hide
    })
    connect(g_game, {
        onGameEnd = show
    })
    startBackgroundEffectLoop() -- start the background effect loop
end

function terminate()
    disconnect(g_game, {
        onGameStart = hide
    })
    disconnect(g_game, {
        onGameEnd = show
    })

    g_effects.cancelFade(background:getChildById('clientVersionLabel'))
    if bgEffectEvent then
        removeEvent(bgEffectEvent)
        bgEffectEvent = nil
    end
    background:destroy()

    background = nil
    clientVersionLabel = nil
end

function hide()
    background:hide()
    if bgEffectEvent then
        removeEvent(bgEffectEvent)
        bgEffectEvent = nil
    end
end

function show()
    background:show()
    startBackgroundEffectLoop()
end

function hideVersionLabel()
    background:getChildById('clientVersionLabel'):hide()
end

function setVersionText(text)
    clientVersionLabel:setText(text)
end

function getBackground()
    return background
end

-- 🔄 example of how to use the particles widget
function startBackgroundEffectLoop()
    if bgEffectEvent then
        removeEvent(bgEffectEvent)
        bgEffectEvent = nil
    end

    local function switchEffect()
        if not background then
            return
        end

        local particlesWidget = background:getChildById('particles') -- background is the root widget of the background module
        if not particlesWidget then
            return
        end

        if toggleState then
            particlesWidget:setEffect('background-effect')
        else
            particlesWidget:setEffect('background2-effect')
        end
        toggleState = not toggleState

        -- repeat every 5 seconds (adjust the time you want)
        bgEffectEvent = scheduleEvent(switchEffect, timeLoopBackgroundEffect)
    end

    -- start the first effect change
    switchEffect()
end
