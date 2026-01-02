function Party.Update(partyData)
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  minimapWidget:showParty()
end

function Party.Leave(PlayerName)
  for rem = 1, #Party.Members do
    minimapWidget:removeOldParty(PlayerName)
  end

  for rem = 1, #Party.Members do
    if Party.Members[rem].Name == PlayerName then
      table.remove(Party.Members, rem)
    end
  end
end

function Party.Reset()
  minimapWidget:resetParty()
end

function Party.UpdateFloor(floor)
  minimapWidget:FloorUpdate(floor)
end

function Party.ChangeView()
  if Party.ShowNames == false then
    Party.ShowNames = true

    minimapWidget:ViewUpdate("Show")
  else
    Party.ShowNames = false

    minimapWidget:ViewUpdate("Hide")
  end
end
