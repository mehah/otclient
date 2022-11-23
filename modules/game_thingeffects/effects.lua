-- outfit
-- 307
-- 293 - raio
-- effect 32, 12
EFFECTS = {{
    id = 1,
    name = 'Teste',
    thingId = 130,
    category = ThingCategoryEffect,
    speed = 0.5,
    onTop = true,
    offset = {
        x = -30,
        y = -20
    }, -- Default for All outfit
    dirsControl = {
        [North] = {
            onTop = true,
            offset = {
                x = -10,
                y = 2
            }
        },
        [East] = {
            x = -11,
            y = 10
        },
        [South] = {
            x = -12,
            y = 15
        },
        [West] = {
            x = -13,
            y = 15
        }
    },
    outfitOffset = { -- Offset based on outfit
        [300] = { -- Outfit ID
            offset = {
                x = -30,
                y = -20
            },
            dirsOffset = {
                [North] = {
                    x = -10,
                    y = 2
                },
                [East] = {
                    x = -11,
                    y = 10
                },
                [South] = {
                    x = -12,
                    y = 15
                },
                [West] = {
                    x = -13,
                    y = 15
                }
            }
        }
    }
}}
