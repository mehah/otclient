__EFFECTS = {{
    id = 1,
    name = 'Raio',
    thingId = 12,
    category = ThingCategoryEffect,
    speed = 0.5,
    onTop = false,
    offset = {
        x = 0,
        y = 0
    }
}, {
    id = 2,
    name = 'Raio',
    thingId = 307,
    category = ThingCategoryCreature,
    speed = 2,
    dirsControl = {
        [North] = {
            onTop = true,
            offset = {
                x = 0,
                y = 2
            }
        },
        [East] = {
            x = 5,
            y = -5
        },
        [South] = {
            x = -5,
            y = 0
        },
        [West] = {
            onTop = true,
            offset = {
                x = -10,
                y = -5
            }
        }
    }
}}
