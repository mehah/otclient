function init()
    -- WALKING SYSTEM
    -- Set true if using Nostalrius 7.2, Nekiro TFS-1.5-Downgrades-7.72
    -- or any protocol below 860 that the walking system is stuttering.
    g_game.setForceNewWalkingFormula(true)

    -- set latest supported version
    g_game.setLastSupportedVersion(1291)

    g_fonts.setWidgetTextFont('verdana-11px-antialised')
    g_fonts.setStaticTextFont('verdana-11px-rounded')
    g_fonts.setAnimatedTextFont('verdana-11px-rounded')
    g_fonts.setCreatureNameFont('verdana-11px-rounded')
end
