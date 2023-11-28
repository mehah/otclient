onAttackingCreatureChange(function(creature, OldCreature)
    if creature and creature:isNpc() and distanceFromPlayer(creature:getPosition()) <= 3 then
        CaveBot.Conversation("hi", "trade")
    end
end)