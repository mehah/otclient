local HOTKEY = 'Ctrl+Y'
local MAP_SHADERS = { {
    name = 'Map - Default',
    frag = nil
}, {
    name = 'Map - Fog',
    frag = 'shaders/fragment/fog.frag',
    tex1 = 'images/clouds'
}, {
    name = 'Map - Rain',
    frag = 'shaders/fragment/rain.frag'
}, {
    name = 'Map - Snow',
    frag = 'shaders/fragment/snow.frag',
    tex1 = 'images/snow'
}, {
    name = 'Map - Gray Scale',
    frag = 'shaders/fragment/grayscale.frag'
}, {
    name = 'Map - Bloom',
    frag = 'shaders/fragment/bloom.frag'
}, {
    name = 'Map - Sepia',
    frag = 'shaders/fragment/sepia.frag'
}, {
    name = 'Map - Pulse',
    frag = 'shaders/fragment/pulse.frag',
    drawViewportEdge = true
}, {
    name = 'Map - Old Tv',
    frag = 'shaders/fragment/oldtv.frag'
}, {
    name = 'Map - Party',
    frag = 'shaders/fragment/party.frag'
}, {
    name = 'Map - Radial Blur',
    frag = 'shaders/fragment/radialblur.frag',
    drawViewportEdge = true
}, {
    name = 'Map - Zomg',
    frag = 'shaders/fragment/zomg.frag',
    drawViewportEdge = true
}, {
    name = 'Map - Heat',
    frag = 'shaders/fragment/heat.frag',
    drawViewportEdge = true
}, {
    name = 'Map - Noise',
    frag = 'shaders/fragment/noise.frag'
} }

OUTFIT_SHADERS = { {
    name = 'Outfit - Default',
    frag = nil
}, {
    name = 'Outfit - Rainbow',
    frag = 'shaders/fragment/party.frag'
}, {
    name = 'Outfit - Ghost',
    frag = 'shaders/fragment/radialblur.frag',
    drawColor = false
}, {
    name = 'Outfit - Jelly',
    frag = 'shaders/fragment/heat.frag'
}, {
    name = 'Outfit - Fragmented',
    frag = 'shaders/fragment/noise.frag'
}, {
    name = 'Outfit - Outline',
    useFramebuffer = true,
    frag = 'shaders/fragment/outline.frag'
} }

MOUNT_SHADERS = { {
    name = 'Mount - Default',
    frag = nil
}, {
    name = 'Mount - Rainbow',
    frag = 'shaders/fragment/party.frag'
} }

-- Fix for texture offset drawing, adding walking offsets.
local dirs = {
    [0] = {
        x = 0,
        y = 1
    },
    [1] = {
        x = 1,
        y = 0
    },
    [2] = {
        x = 0,
        y = -1
    },
    [3] = {
        x = -1,
        y = 0
    },
    [4] = {
        x = 1,
        y = 1
    },
    [5] = {
        x = 1,
        y = -1
    },
    [6] = {
        x = -1,
        y = -1
    },
    [7] = {
        x = -1,
        y = 1
    }
}

local function attachShaders()
    local map = modules.game_interface.getMapPanel()
    map:setShader('Default')

    local player = g_game.getLocalPlayer()
    player:setShader('Default')
    player:setMountShader('Default')
end

local registerShader = function(opts, method)
    local fragmentShaderPath = resolvepath(opts.frag)

    if fragmentShaderPath ~= nil then
        --  local shader = g_shaders.createShader()
        g_shaders.createFragmentShader(opts.name, opts.frag, opts.useFramebuffer or false)

        if opts.tex1 then
            g_shaders.addMultiTexture(opts.name, opts.tex1)
        end
        if opts.tex2 then
            g_shaders.addMultiTexture(opts.name, opts.tex2)
        end

        -- Setup proper uniforms
        g_shaders[method](opts.name)
    end
end

ShaderController = Controller:new()

function ShaderController:onInit()
    for _, opts in pairs(MAP_SHADERS) do
        registerShader(opts, 'setupMapShader')
    end

    for _, opts in pairs(OUTFIT_SHADERS) do
        registerShader(opts, 'setupOutfitShader')
    end

    for _, opts in pairs(MOUNT_SHADERS) do
        registerShader(opts, 'setupMountShader')
    end
end

function ShaderController:onTerminate()
    g_shaders.clear()
end

function ShaderController:onGameStart()
    attachShaders()

    self:bindKeyDown(HOTKEY, function()
        ShaderController.ui:setVisible(not ShaderController.ui:isVisible())
    end)

    self:loadUI('shaders', modules.game_interface.getMapPanel())

    self.ui:setMarginTop(80)
    self.ui:hide()

    local mapComboBox = self.ui:getChildById('mapComboBox')
    mapComboBox.onOptionChange = function(combobox, option)
        local map = modules.game_interface.getMapPanel()
        map:setShader(option)

        local data = combobox:getCurrentOption().data
        map:setDrawViewportEdge(data.drawViewportEdge == true)
    end

    local outfitComboBox = self.ui:getChildById('outfitComboBox')
    outfitComboBox.onOptionChange = function(combobox, option)
        local player = g_game.getLocalPlayer()
        if player then
            player:setShader(option)
            local data = combobox:getCurrentOption().data
            player:setDrawOutfitColor(data.drawColor ~= false)
        end
    end

    local mountComboBox = self.ui:getChildById('mountComboBox')
    mountComboBox.onOptionChange = function(combobox, option)
        local player = g_game.getLocalPlayer()
        if player then
            player:setMountShader(option)
        end
    end

    for _, opts in pairs(MAP_SHADERS) do
        mapComboBox:addOption(opts.name, opts)
    end

    for _, opts in pairs(OUTFIT_SHADERS) do
        outfitComboBox:addOption(opts.name, opts)
    end

    for _, opts in pairs(MOUNT_SHADERS) do
        mountComboBox:addOption(opts.name, opts)
    end
end
