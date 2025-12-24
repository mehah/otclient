--[[
    register(id, name, thingId, config)
    config = {
        drawOnUI, priority, onlyAddon, addon,
        shader, bounce, fixed, sizeFactor,
        color, headColor, bodyColor, legsColor, feetColor,
        useMountPattern, showOnMount
        offset{x, y, onTop}, dirOffset[dir]{x, y, onTop},
        mountOffset{x, y, onTop}, mountDirOffset[dir]{x, y, onTop},
        onAttach, onDetach
    }
]]
--

PaperdollManager.register(1, 'Armadura', 512, {
    priority = 1,
    addon = 1,
    onlyAddon = true,
    onAttach = function(paperdoll, creature)
        print('onAttach: ', paperdoll:getId(), creature:getName())
    end,
    onDetach = function(paperdoll, creature)
        print('onDetach: ', paperdoll:getId(), creature:getName())
    end
})

PaperdollManager.register(2, 'Weapons/shield', 512, {
    priority = 2,
    addon = 2,
    onlyAddon = true
})

PaperdollManager.register(3, 'Peitoral', 367, {
    priority = 3,
    addon = 1,
    onlyAddon = true
})

PaperdollManager.register(4, 'Akuma Aura', 664, {
    priority = 4,
    addon = 1,
    bounce = true,
    fixed = true,
    onlyAddon = true
})

PaperdollManager.register(5, 'Mochila', 136, {
    priority = 5,
    addon = 1,
    color = 77,
    onlyAddon = true
})

PaperdollManager.register(1990, 'wings1990', 136, {
    priority = 5,
    onlyAddon = true,
    addon = 2,
    onTop = true,
    bounce = true,
    fixed = false,
    useMountPattern = true,
    dirOffset = {
        [North] = { 0, 0, true },
        [East] = { 0, 0, true }, -- x+ esquerda, y+ = cima
        [South] = { 0, 0, true },
        [West] = { 0, 0, true }  -- x- = esquerda, y+ = cima

        -- x,y  (x+ = esquerda, y+ = baixo)
    }
})

PaperdollManager.register(130, 'wings130', 136, {
    priority = 4,
    onlyAddon = true,
    addon = 1,
    onTop = true,
    bounce = false,
    fixed = false,
    useMountPattern = true
})
