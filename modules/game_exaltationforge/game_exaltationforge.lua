Forge = {}


Forge.resourceTypes = {
    ["money"] = 0,
	["dust"] = 70,
	["sliver"] = 71,
	["core"] = 72 
}


Forge.colors = {
    enough = "#C0C0C0",
	missing = "#D33C3C"
}

ACTION_FUSION_TYPE = 0
ACTION_TRANSFER_TYPE = 1
ACTION_DUST_TO_SILVER = 2
ACTION_SILVER_TO_CORE = 3
ACTION_INCREASE_DUST_LIMIT = 4

local Fusion = nil
local Transfer = nil
local Conversion = nil
local History = nil
function init()
    Forge.mainButton = modules.game_mainpanel.addToggleButton("forgeButton", tr("Exaltation Forge"),
            "/images/options/forge", function() Forge:displayPreview() end, false, 17)

    Forge.mainButton:setOn(false)
		
    Forge.mainWindow = g_ui.displayUI("game_exaltationforge")
	Forge.mainWindow:setId("forge")
	Forge.mainWindow:setVisible(false)
	Forge.firstTooltip = Forge.mainWindow:getChildById('firstTooltip')
	Forge.secondTooltip = Forge.mainWindow:getChildById('secondTooltip')
	Forge.goldBalancePanel = Forge.mainWindow:getChildById('goldBalancePanel')
	Forge.goldBalanceValue = Forge.goldBalancePanel:getChildById('value')
	Forge.dustBalancePanel = Forge.mainWindow:getChildById('dustBalancePanel')
	Forge.dustBalanceValue = Forge.dustBalancePanel:getChildById('value')
	Forge.sliverBalancePanel = Forge.mainWindow:getChildById('sliverBalancePanel')
	Forge.sliverBalanceValue = Forge.sliverBalancePanel:getChildById('value')	
	Forge.coreBalancePanel = Forge.mainWindow:getChildById('coreBalancePanel')
	Forge.coreBalanceValue = Forge.coreBalancePanel:getChildById('value')
	
	local closeWidget = Forge.mainWindow:getChildById('close')
    closeWidget.onClick = function(self)
	    Forge.mainWindow:setVisible(false)
	end
	
	Fusion = Forge.Fusion:get()
	Transfer = Forge.Transfer:get()
	Conversion = Forge.Conversion:get()
	History = Forge.History:get()
	
	
	Forge.Fusion:createButton()
	Forge.Transfer:createButton()
	Forge.Conversion:createButton()
	Forge.History:createButton()
	
	
	
	connect(g_game, {
        onOpenExaltationForge = onOpenExaltationForge,
		onResultExaltationForge = onResultExaltationForge,
		onItemClasses = onPlayerResourcesChange,
		onForgeHistory = onForgeHistory,
		onResourceBalance = onResourceBalance,
		onGameEnd = function() Forge:close() end
    })
end

function onResourceBalance()
    Forge:updateResources()
end

function Forge:updateResources()
    self.goldBalanceValue:setText(self:formatNumber(self:getResourceBalance('money')))
	local dustLevel = self.dustLevel or 0
	self.dustBalanceValue:setText(self:getResourceBalance('dust') .. "/" .. dustLevel)
    self.sliverBalanceValue:setText(self:getResourceBalance('sliver'))
	self.coreBalanceValue:setText(self:getResourceBalance('core'))
end

function Forge:close()
    self.mainWindow:setVisible(false)
	self.mainButton:setOn(false)
	if self.resultWindow then
	    self.resultWindow:setVisible(false)
		
	end
end

function Forge:get()
    return self
end

function Forge:displayPreview()
    if not self.mainWindow:isVisible() then
	    g_game.sendResourceBalance()
        self.mainWindow:setVisible(true)
		self.mainButton:setOn(true)
		self.mainWindow:focus()
		Fusion:showWindow()
		Forge.preview = true
		if Fusion:hasConvergence() then
		    Fusion:displayConvergence(true)
		else
		    Fusion:displayItems(true)
		end
		Transfer:updateWidgets()
		--self.mainButton:setEnabled(true)
	else
        self.mainWindow:setVisible(false)
		self.mainButton:setOn(false)
		--self.mainButton:setEnabled(false)	 
    end		
end

function Forge:formatNumber(n)
    if n >= 1000000000 then
        -- miliardy i więcej → w "kk"
        local value = math.floor(n / 1000000)  -- dzielimy przez milion
        local str = tostring(value)
        local result = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if result:sub(1,1) == "," then
            result = result:sub(2)
        end
        return result .. " kk"
    else
        -- poniżej miliarda → normalne formatowanie z przecinkami
        local str = tostring(n)
        local result = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        if result:sub(1,1) == "," then
            result = result:sub(2)
        end
        return result
    end
end

function Forge:updateWidget(resourceType, widget, value, _disabled)
    local balance = Forge:getResourceBalance(resourceType)	
	value = tonumber(value)
	
	if balance >= value then
	    widget:setColor(Forge.colors.enough)
		if _disabled then
		    widget:setEnabled(false)
		end
	else
	    widget:setColor(Forge.colors.missing)
		if _disabled then
		    widget:setEnabled(true)
		end
	end
end

function Forge:setWidget(widget, value, boolean)
    widget:setText(value)
	if boolean then 
	    widget:setColor(Forge.colors.enough)
	else
	    widget:setColor(Forge.colors.missing)
	end
end

function Forge:getResourceBalance(str)
    local t = self.resourceTypes[str]
	if not t then
	    return 0
	end
	
	local player = g_game.getLocalPlayer()
	if not player then
	    return 0
    end
	
	if str == "money" then
	    return player:getTotalMoney()
	end		
	return player:getResourceBalance(t)
end

function Forge:ProcessFlash(item, widget, times, delay, startDelay, item2, widget2, descWidget, description, success)
	local shaderName = 'Item - Forge'
	local currentDelay = 0
	
	
	local pulseShader = 'Item - ForgePulse'
	local flashShader = 'Item - ForgeFlash'
	local redShader = 'Item - ForgeFlashRed'
	
	local test = true
	if test then
		g_shaders.createFragmentShader(pulseShader, "menu/shaders/forge.frag", true)
	    scheduleEvent(function()
		    animateArrows()
            item:setShader(pulseShader)
			if success then
			    scheduleEvent(function() 
				    widget:setVisible(false)
					descWidget:setColoredText(description)
			        descWidget:setVisible(true)
					g_shaders.createFragmentShader(flashShader, "menu/shaders/flash.frag", true)
					scheduleEvent(function()
					    item2:setShader(flashShader)
						scheduleEvent(function()
					        item2:setShader(nil)
							widget2:setColor(nil)
					    end, 350)
				    end, 10)
				end, 5400)
			else
			    scheduleEvent(function() 
					descWidget:setColoredText(description)
					descWidget:setVisible(true)
					g_shaders.createFragmentShader(redShader, "menu/shaders/red flash.frag", true)
					scheduleEvent(function()
					    item2:setShader(redShader)
					    scheduleEvent(function()
					        widget2:setVisible(false)
						    item:setShader(nil)
						    widget:setColor(nil)
						end, 350)
					end, 10)
				end, 5400)
			end
		end, 10)
		
		scheduleEvent(function()
		    if g_shaders and g_shaders.removeShader then
		      g_shaders.removeShader(pulseShader)
		      g_shaders.removeShader(flashShader)
		      g_shaders.removeShader(redShader)
		    end
		end, 5800)
		return
	end	 
end

function Forge:displayResult(actionType, convergence, success, leftItemId, rightItemId, leftTier, rightTier)
	if self.resultWindow then
	    self.resultWindow:destroy()
		self.resultWindow = nil
	end
    self.resultWindow = g_ui.displayUI("result")
	self.resultWindow:setVisible(false)
	local resultWindow = self.resultWindow
	
	local closeWidget = resultWindow:getChildById('close')
	closeWidget.onClick = function(widget)
	    resultWindow:setVisible(false)
		self.mainWindow:setVisible(true)
		if actionType == ACTION_TRANSFER_TYPE then
            Transfer:showWindow()	
        end			
	end
	
	if actionType == ACTION_FUSION_TYPE then
	    if convergence == 1 then
		    resultWindow:setText("Convergence Fusion Result")
		else
            resultWindow:setText("Fusion Result")
		end
		
		--success = false
		
		local text = "Your fusion attempt was {succesfull, #44AD25}."
		if not success then
		    text = "Your fusion attempt was {failed, #D33C3C}."
		end
		local descWidget = resultWindow:recursiveGetChildById('resultText')
		--descWidget:setColoredText(text)
		--descWidget:setVisible(true)
		
		local rightItem = Item.create(rightItemId)
		local rightWidget = resultWindow:recursiveGetChildById('previewItem2')
		rightItem:setTier(rightTier)
		rightWidget:setItem(rightItem)
		ItemsDatabase.setTier(rightWidget, rightItem)
		rightWidget:setColor("black")
		
		local leftWidget = resultWindow:recursiveGetChildById('previewItem1')
		local leftItem = Item.create(leftItemId)
		leftItem:setTier(leftTier)
        leftWidget:setItem(leftItem)
		ItemsDatabase.setTier(leftWidget, leftItem)
		
	    scheduleEvent(function() 
		    self:ProcessFlash(leftItem, leftWidget, 7, 200, false, rightItem, rightWidget, descWidget, text, success)
		end, 200)		       
	elseif actionType == ACTION_TRANSFER_TYPE then
	    if convergence == 1 then
		    resultWindow:setText("Convergence Tier Transfer Result")
		else
            resultWindow:setText("Transfer Result")
		end
		
		--success = false
		
		local text = "Your transfer was {succesfull, #44AD25}."
		if not success then
		    text = "Your transfer was {failed, #D33C3C}."
		end
		local descWidget = resultWindow:recursiveGetChildById('resultText')
		--descWidget:setColoredText(text)
		--descWidget:setVisible(true)
		
		local rightItem = Item.create(rightItemId)
		local rightWidget = resultWindow:recursiveGetChildById('previewItem2')
		rightItem:setTier(rightTier)
		rightWidget:setItem(rightItem)
		ItemsDatabase.setTier(rightWidget, rightItem)
		rightWidget:setColor("black")
		
		local leftWidget = resultWindow:recursiveGetChildById('previewItem1')
		local leftItem = Item.create(leftItemId)
		leftItem:setTier(leftTier)
        leftWidget:setItem(leftItem)
		ItemsDatabase.setTier(leftWidget, leftItem)
		
	    scheduleEvent(function() 
		    self:ProcessFlash(leftItem, leftWidget, 7, 200, false, rightItem, rightWidget, descWidget, text, success)
		end, 200)		
	end
	--self.mainWindow:setVisible(false)
	--self.mainWindow:setVisible(false)
    self.resultWindow:setVisible(true)
end

function onOpenExaltationForge(data)
    Forge.preview = false
	Forge.dustLevel = data.dustLevel
    Fusion:parseData(data)
	Transfer:parseData(data)
end

function onPlayerResourcesChange(data)
    Forge.data = data
	Forge:updateResources()
    Fusion:parseResourcesChange(data)
	Conversion:parseResourcesChange(data)	
end

function onResultExaltationForge(data)
    local success = nil
	if data.success == 1 then
	    success = true
	end
		
	--Forge.mainWindow:setVisible(false)
	
	scheduleEvent(function()
       Forge.mainWindow:setVisible(false)
    end, 10)
	
    Forge:displayResult(data.actionType, data.convergence, success, data.leftItemId, data.rightItemId, data.leftTier, data.rightTier)
	if data.actionType == ACTION_FUSION_TYPE then
	    Fusion:parseResult(data)
		return
	end
	if data.actionType == ACTION_TRANSFER_TYPE then
	    Transfer:parseResult(data)
	end
	return
end

function onForgeHistory(currentPage, lastPage, data)
    History:parse(currentPage, lastPage, data)
end
function animateArrows(item, description, success)
    local arrow1 = Forge.resultWindow:recursiveGetChildById('arrowsIcon1')
    local arrow2 = Forge.resultWindow:recursiveGetChildById('arrowsIcon2')
    local arrow3 = Forge.resultWindow:recursiveGetChildById('arrowsIcon3')


    local speed = 0.90

    local function runSequence()
        arrow1:setImageSource('/images/game/forge/icon-arrow-rightlarge')
        arrow2:setImageSource('/images/game/forge/icon-arrow-rightlarge')
        arrow3:setImageSource('/images/game/forge/icon-arrow-rightlarge')

        scheduleEvent(function() arrow1:setImageSource('/images/game/forge/icon-arrow-rightlarge-filled') end, 100 * speed)
        scheduleEvent(function() arrow2:setImageSource('/images/game/forge/icon-arrow-rightlarge-filled') end, 350 * speed)
        scheduleEvent(function() arrow3:setImageSource('/images/game/forge/icon-arrow-rightlarge-filled') end, 600 * speed)

        scheduleEvent(function() arrow1:setImageSource('/images/game/forge/icon-arrow-rightlarge') end, 1600 * speed)
        scheduleEvent(function() arrow2:setImageSource('/images/game/forge/icon-arrow-rightlarge') end, 1850 * speed)
        scheduleEvent(function() arrow3:setImageSource('/images/game/forge/icon-arrow-rightlarge') end, 2100 * speed)
    end

    local sequenceDuration = 2200 * speed

    for i = 0, 2 do
        scheduleEvent(runSequence, 100 * speed + i * sequenceDuration)
    end
end

function terminate()
end
