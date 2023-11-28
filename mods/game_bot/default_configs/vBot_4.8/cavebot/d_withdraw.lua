CaveBot.Extensions.DWithdraw = {}

CaveBot.Extensions.DWithdraw.setup = function()
	CaveBot.registerAction("dpwithdraw", "#002FFF", function(value, retries)
		local capLimit
		local data = string.split(value, ",")
		if retries > 600 then
			print("CaveBot[DepotWithdraw]: actions limit reached, proceeding") 
			return false
		end
		local destContainer
		local depotContainer
		delay(70)

		-- input validation
		if not value or #data ~= 3 and #data ~= 4 then
			warn("CaveBot[DepotWithdraw]: incorrect value!")
			return false
		end
		local indexDp = tonumber(data[1]:trim())
		local destName = data[2]:trim():lower()
		local destId = tonumber(data[3]:trim())
		if #data == 4 then
			capLimit = tonumber(data[4]:trim())
		end


		-- cap check
		if freecap() < (capLimit or 200) then
			for i, container in ipairs(getContainers()) do
				if container:getName():lower():find("depot") or container:getName():lower():find("locker") then
					g_game.close(container)
				end
			end
			print("CaveBot[DepotWithdraw]: cap limit reached, proceeding") 
			return false 
		end

		-- containers
		for i, container in ipairs(getContainers()) do
			local cName = container:getName():lower()
			if destName == cName then
				destContainer = container
			elseif cName:find("depot box") then
				depotContainer = container
			end
		end

		if not destContainer then 
			print("CaveBot[DepotWithdraw]: container not found!")
			return false
		end

		if containerIsFull(destContainer) then
			for i, item in pairs(destContainer:getItems()) do
				if item:getId() == destId then
					g_game.open(item, destContainer)
					return "retry"
				end
			end
		end

		-- stash validation
		if depotContainer and #depotContainer:getItems() == 0 then
			print("CaveBot[DepotWithdraw]: all items withdrawn")
			g_game.close(depotContainer)
			return true
		end

		if containerIsFull(destContainer) then
			for i, item in pairs(destContainer:getItems()) do
				if item:getId() == destId then
					g_game.open(foundNextContainer, destContainer)
					return "retry"
				end
			end
			print("CaveBot[DepotWithdraw]: loot containers full!")
			return false
		end

		if not CaveBot.OpenDepotBox(indexDp) then
			return "retry"
		end

		CaveBot.PingDelay(2)

		for i, container in pairs(g_game.getContainers()) do
			if string.find(container:getName():lower(), "depot box") then
				for j, item in ipairs(container:getItems()) do
					statusMessage("[D_Withdraw] witdhrawing item: "..item:getId())
					g_game.move(item, destContainer:getSlotPosition(destContainer:getItemsCount()), item:getCount())
					return "retry"
				end
			end
		end

		return "retry"
  	end)

 	CaveBot.Editor.registerAction("dpwithdraw", "dpwithdraw", {
 	 value="1, shopping bag, 21411",
 	 title="Loot Withdraw",
 	 description="insert index, destination container name and it's ID",
 	})
end