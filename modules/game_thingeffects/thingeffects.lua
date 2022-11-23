function init()

    connect(ThingEffect, {
        onAdd = function(effect)
            if effect:getOwner():isPlayer() and effect:getOwner():getLevel() > 90 then
                -- effect:addShader(...)
            end
        end,
        onRemove = function(effect)
        end,
        onChangeTop = function(effect, onTop)
            print(onTop)
        end,
        onChangeDirection = function(effect, dir)
            print(dir)
        end
    })

end

function terminate()

end
