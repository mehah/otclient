ACTION_FUSION_TYPE = 0
ACTION_TRANSFER_TYPE = 1
ACTION_DUST_TO_SILVER = 2
ACTION_SILVER_TO_CORE = 3
ACTION_INCREASE_DUST_LIMIT = 4

Forge.Conversion = {}

local Conversion = Forge.Conversion
Conversion.mainWindow = nil

function Conversion:get()
    return self
end


function Conversion:createButton()
    local buttonPanel = g_ui.createWidget('ForgeButton', Forge.mainWindow)
	buttonPanel:addAnchor(AnchorTop, 'FusionButton', AnchorTop)
	buttonPanel:addAnchor(AnchorLeft, 'TransferButton', AnchorRight)
	buttonPanel:setId('ConversionButton')
	self.buttonPanel = buttonPanel
	self.mainButton = buttonPanel:getChildById('button')
	self.mainButton:setText("Conversion")
	
	local iconWidget = buttonPanel:getChildById('icon')
	iconWidget:setImageSource("/images/game/forge/icon-conversion")		
    if not self.mainWindow then
	    g_ui.importStyle('Conversion')
        self.mainWindow = g_ui.createWidget('ConversionWindow', Forge.mainWindow)
		self.mainWindow:addAnchor(AnchorTop,    'TransferButton', AnchorBottom)
		self.mainWindow:addAnchor(AnchorLeft,   'FusionButton', AnchorLeft)
		self.mainWindow:addAnchor(AnchorRight,  'parent', AnchorRight)
		self.mainWindow:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    end	
    self.mainButton.onClick = function(widget, mousePos, mouseButton)
	    if Forge.currentPanel then
	        Forge.currentPanel:setVisible(false)
	    end
	
	    if Forge.currentButton then
	        Forge.currentButton:setEnabled(true)
	    end
	
	    Forge.currentPanel = self.mainWindow
	    Forge.currentButton = self.mainButton
        self.mainWindow:setVisible(true)
	    self.mainButton:setEnabled(false)
		Forge.firstTooltip:setVisible(false)
	    Forge.secondTooltip:setVisible(true)
		
		--dust_rewardWidget:setItemId(37109)
		--silver_rewardWidget:setItemId(37110)
		
		self.widgetStorage.dustRewardWidget:setItemId(37109)
		self.widgetStorage.silverRewardWidget:setItemId(37110)
		self.widgetStorage.silver_forgeItem:setItemId(37109)
		
    end
	self:init()
end

function Conversion:updateLimitCost(currentLimit, baseLimit, newLimit, percent)
    local baseCost = 25	
    local limit = currentLimit - 100
	local value = baseCost + limit
	local _dustEnough = true
	if Forge:getResourceBalance("dust") < value then
	    _dustEnough = false
	end
	local currentLimitWidget = self.widgetStorage.currentLimit
	local newLimitWidget = self.widgetStorage.newLimit
	local newCostWidget = self.widgetStorage.limitCost
	local button = self.widgetStorage.DustLimitProcced
	local opacity = 0.3
	local image1 = self.widgetStorage.imageFirst
	local image2 = self.widgetStorage.imageSecond
	
	local value2 = baseLimit - 100 + baseCost
	self.widgetStorage.limitCost:setText(value2)
	newLimitWidget:setText(baseLimit + 1)
	currentLimitWidget:setText(baseLimit)
	if _dustEnough then
	    newCostWidget:setColor(Forge.colors.enough)
		button:setEnabled(true)
		button:setOpacity(1)
		image1:setImageSource('/images/game/forge/dust')
		image2:setImageSource('/images/game/forge/dust')
	else
		newCostWidget:setColor(Forge.colors.missing)
		button:setEnabled(false)
		button:setOpacity(opacity)
		image1:setImageSource('/images/game/forge/dust2')
		image2:setImageSource('/images/game/forge/dust2')
	end		
end

function Conversion:updateConversion(dustRequired, dustReward, silverRequired, silverReward, baseLimit, currentLimit, newLimit, percent)
    local dustRequiredWidget = self.widgetStorage.dustRequired
	local dustRewardWidget = self.widgetStorage.dustReward
	local dustButtonProcced = self.widgetStorage.dustButtonProcced
	local rewardITem = self.widgetStorage.dustRewardWidget
	local _dustEnough = true
	dustRequiredWidget:setText(dustRequired)
	dustRewardWidget:setText(dustReward)
	if Forge:getResourceBalance("dust") < dustRequired then
	    _dustEnough = false
	end
	
	local opacity = 0.3
	if not _dustEnough then
	    dustRequiredWidget:setColor(Forge.colors.missing)
		dustButtonProcced:setEnabled(false)
		dustButtonProcced:setOpacity(opacity)
		rewardITem:setOpacity(opacity)
	else
	    dustRequiredWidget:setColor(Forge.colors.enough)
		dustButtonProcced:setEnabled(true)
		dustButtonProcced:setOpacity(1)
		rewardITem:setOpacity(1)		
	end
	
	local silverRequiredWidget = self.widgetStorage.silverRequired
	local sliverRewardWidget = self.widgetStorage.silverReward
	local silverButtonProcced = self.widgetStorage.silverButtonProcced
	local silverRewardItem = self.widgetStorage.silverRewardWidget
	local _silverEnough = true
	silverRequiredWidget:setText(silverRequired)
	sliverRewardWidget:setText(silverReward)
		
	if Forge:getResourceBalance("sliver") < silverRequired then
	    _silverEnough = false
	end
	if not _silverEnough then
	    silverRequiredWidget:setColor(Forge.colors.missing)
		silverButtonProcced:setEnabled(false)
		silverButtonProcced:setOpacity(opacity)
		silverRewardItem:setOpacity(opacity)
	else
	    silverRequiredWidget:setColor(Forge.colors.enough)
		silverButtonProcced:setEnabled(true)
		silverButtonProcced:setOpacity(1)
		silverRewardItem:setOpacity(1)
	end	
	self:updateLimitCost(currentLimit, baseLimit, newLimit, percent)
end

function Conversion:init()
    self.widgetStorage = {}
	local mainWindow = self.mainWindow
    local mainPanel = mainWindow	
    local convert_dustPanel = mainPanel:getChildById('convertDustPanel')
    local dust_forgeItemWidget = convert_dustPanel:getChildById('forgeItem')
    local dust_countPanel = dust_forgeItemWidget:getChildById('countPanel')
    local dust_countValue = dust_countPanel:getChildById('value')
    
    --EXCALTATION_FORGE_SYSTEM:addResourceWidget(RESOURCE_DUST, false, dust_countValue)
    
    local dust_rewardAmountWidget = convert_dustPanel:getChildById('forgeTextWithIcon')
    local dust_rewardAmountValue = dust_rewardAmountWidget:getChildById('value')
    --dust_rewardAmountValue:setText("6666")
    
    self.widgetStorage.dustRequired = dust_countValue
    self.widgetStorage.dustReward = dust_rewardAmountValue
    
    local dust_countIcon = dust_countPanel:getChildById('icon')
    dust_countIcon:setImageSource('/images/game/forge/icon-currency-dust')
    dust_rewardWidget = convert_dustPanel:getChildById('rewardItem')
    dust_rewardWidget:setItemId(37109)
    
    self.widgetStorage.dustRewardWidget = dust_rewardWidget
    
    local dust_buttonProcced = convert_dustPanel:getChildById('convertDustProcced')
    dust_buttonProcced.onClick = function()
        g_game.sendForgeAction(ACTION_DUST_TO_SILVER, false, nil, nil, nil)
    end
    
    self.widgetStorage.dustButtonProcced = dust_buttonProcced
    
    
    local convert_silverPanel = mainPanel:getChildById('convertSilverPanel')
    local silver_forgeItemWidget = convert_silverPanel:getChildById('forgeItem')
    local silver_forgeItemImage = silver_forgeItemWidget:getChildById('image')
    silver_forgeItemImage:setVisible(false)
    local silver_forgeItem = silver_forgeItemWidget:getChildById('item')
    silver_forgeItem:setItemId(37109)
	self.widgetStorage.silver_forgeItem = silver_forgeItem
    local silver_rewardWidget = convert_silverPanel:getChildById('rewardItem')
	self.widgetStorage.silverRewardWidget = silver_rewardWidget
    --silver_rewardWidget:setItemId(37110)
    local silver_rewardAmountWidget = convert_silverPanel:getChildById('forgeTextWithIcon')
    local silver_rewardAmountValue = silver_rewardAmountWidget:getChildById('value')
    --silver_rewardAmountValue:setText("6666")
    local silver_rewardAmountIcon = silver_rewardAmountWidget:getChildById('icon')
    silver_rewardAmountIcon:setImageSource('/images/game/forge/icon-currency-exaltedcore')
    
    local silver_countPanel = silver_forgeItemWidget:getChildById('countPanel')
    local silver_countValue = silver_countPanel:getChildById('value')
    
    self.widgetStorage.silverRequired = silver_countValue
    self.widgetStorage.silverReward = silver_rewardAmountValue
    
    local silver_buttonProcced = convert_silverPanel:getChildById('silverButtonProcced')
    silver_buttonProcced.onClick = function()
        g_game.sendForgeAction(ACTION_SILVER_TO_CORE, false, nil, nil, nil)
    end
    self.widgetStorage.silverButtonProcced = silver_buttonProcced
    self.widgetStorage.silverRewardWidget = silver_rewardWidget
    
    local dustLimitPanel = mainPanel:getChildById('dustLimitPanel')
    local dustLimit_forgeItemWidget = dustLimitPanel:getChildById('forgeItem')
    local dustLimit_forgeItemImage = dustLimit_forgeItemWidget:getChildById('image')
    local dustLimit_countPanel = dustLimit_forgeItemWidget:getChildById('countPanel')
    local dustLimit_countValue = dustLimit_countPanel:getChildById('value')
    local dustLimit_countIcon = dustLimit_countPanel:getChildById('icon')
    
    --dustLimit_countValue:setText('66666')
    dustLimit_countIcon:setImageSource('/images/game/forge/icon-currency-dust')
    
    local dustLimit_raiseLimitPanel = dustLimitPanel:getChildById('ForgeTextWithIcon2')
    local dustLimit_raiseLimitFirstValue = dustLimit_raiseLimitPanel:getChildById('value')
    local dustLimit_raiseLimitFirstIcon = dustLimit_raiseLimitPanel:getChildById('icon')
    dustLimit_raiseLimitFirstIcon:setImageSource('/images/game/forge/icon-currency-dust')
    --dustLimit_raiseLimitFirstValue:setText('66666')
    local dustLimit_raiseLimitSecondValue = dustLimit_raiseLimitPanel:getChildById('value2')
    local dustLimit_raiseLimitSecondIcon = dustLimit_raiseLimitPanel:getChildById('icon2')
    dustLimit_raiseLimitSecondIcon:setImageSource('/images/game/forge/icon-currency-dust')
    --dustLimit_raiseLimitSecondValue:setText('66666')
    
    self.widgetStorage.currentLimit = dustLimit_raiseLimitFirstValue
    self.widgetStorage.newLimit = dustLimit_raiseLimitSecondValue
    self.widgetStorage.limitCost = dustLimit_countValue
    
    local DustLimitProcced = dustLimitPanel:getChildById('DustLimitProcced')
    DustLimitProcced.onClick = function()
        g_game.sendForgeAction(ACTION_INCREASE_DUST_LIMIT, false, nil, nil, nil)
    end
    self.widgetStorage.DustLimitProcced = DustLimitProcced
    self.widgetStorage.imageFirst = dustLimitPanel:getChildById('DustLimitButtonImage1')
    self.widgetStorage.imageSecond = dustLimitPanel:getChildById('DustLimitButtonImage2')
end


function Conversion:showWindow()
	if Forge.currentPanel then
	    Forge.currentPanel:setVisible(false)
	end
	
	if Forge.currentButton then
	    Forge.currentButton:setEnabled(true)
	end
	
	Forge.currentPanel = self.mainWindow
	Forge.currentButton = self.mainButton
    self.mainWindow:setVisible(true)
	self.mainButton:setEnabled(false)
end

function Conversion:parseResourcesChange(data)
    local config = data.config
	local currentLimit = config.maxDust
    local dustPercent = config.dustPercent
    local dustToSliver = config.dustToSliver
    local dustRequired = dustToSliver * dustPercent
    local dustReward = config.dustToSliver
    local silverRequired = config.sliverToCore
    local silverReward = 1
    local maxDust = config.maxDustCap
    local dustPercentUpgrade = config.dustPercentUpgrade
    local newLimit = currentLimit + 1
    local startDust = config.maxDust	
    self:updateConversion(dustRequired, dustReward, silverRequired, silverReward, startDust, currentLimit, newLimit, dustPercentUpgrade)
end
     
