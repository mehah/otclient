Forge.Transfer = {}

local Transfer = Forge.Transfer
Transfer.mainWindow = nil

function Transfer:createButton()
    local buttonPanel = g_ui.createWidget('ForgeButton', Forge.mainWindow)
	buttonPanel:addAnchor(AnchorTop, 'FusionButton', AnchorTop)
	buttonPanel:addAnchor(AnchorLeft, 'FusionButton', AnchorRight)
	buttonPanel:setId('TransferButton')
	self.buttonPanel = buttonPanel
	self.mainButton = buttonPanel:getChildById('button')
	
	local iconWidget = buttonPanel:getChildById('icon')
	iconWidget:setImageSource("/images/game/forge/icon-transfer")		
    if not self.mainWindow then
	    g_ui.importStyle('Transfer')
        self.mainWindow = g_ui.createWidget('TransferWindow', Forge.mainWindow)
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
		self.widgetStorage.requiredTransferCoreItem:setItemId(37110)
	    self.mainButton:setEnabled(false)
    end
	self:init()
end

function Transfer:showWindow()
	if Forge.currentPanel then
	    Forge.currentPanel:setVisible(false)
	end	
	
	Forge.currentPanel = self.mainWindow
	self.widgetStorage.requiredTransferCoreItem:setItemId(37110)
    self.mainWindow:setVisible(true)
	Forge.firstTooltip:setVisible(true)
	Forge.secondTooltip:setVisible(false)
end


local delay = 250
local lastClick = 0

function Transfer:init()
    self.widgetStorage = {}
    local mainPanel = self.mainWindow

    self.widgetStorage.mainButton = mainButton
    self.widgetStorage.mainPanel = mainPanel
    self.widgetStorage.icon = icon

    local convergence = mainPanel:recursiveGetChildById('transferConvergence')
    convergence.onClick = function(widget)
        if widget:isChecked() then
            widget:setChecked(false)
			self:updateWidgets()
			self:displayItems()
        else
            widget:setChecked(true)
			self:updateWidgets()
			self:displayConvergence()
        end
		
    end

    self.widgetStorage.convergence = convergence
    self.widgetStorage.firstItemPanel = mainPanel:recursiveGetChildById('transferContent')
    self.widgetStorage.secondItemPanel = mainPanel:recursiveGetChildById('transferContent2')
    local transferButtonProcess = mainPanel:recursiveGetChildById('transferButtonProcced')
    self.widgetStorage.transferButtonProcess = transferButtonProcess
    local firstButtonPreviewItem = transferButtonProcess:recursiveGetChildById('firstButtonPreviewItem')
    self.widgetStorage.firstButtonPreviewItem = firstButtonPreviewItem
    local secondButtonPreviewItem = transferButtonProcess:recursiveGetChildById('secondButtonPreviewItem')
    self.widgetStorage.secondButtonPreviewItem = secondButtonPreviewItem
    local previewTransferItem = mainPanel:recursiveGetChildById('previewTransferItem')
    self.widgetStorage.previewTransferItem = previewTransferItem
    local previewTransferItemCount = mainPanel:recursiveGetChildById('previewTransferItemCount')
    self.widgetStorage.previewTransferItemCount = previewTransferItemCount
    self.widgetStorage.previewTransferQuestionMark = mainPanel:recursiveGetChildById('previewTransferQuestionMark')
    self.widgetStorage.requiredTransferDust = mainPanel:recursiveGetChildById('requiredTransferCount1')
    self.widgetStorage.requiredTransferCoreItem = mainPanel:recursiveGetChildById('requiredCoreItem')
    self.widgetStorage.requiredTransferCoreCount = mainPanel:recursiveGetChildById('requiredCoreCount')
    self.widgetStorage.requiredTransferMoney = mainPanel:recursiveGetChildById('requiredTransferMoney')
	self.widgetStorage.requiredTransferCoreItem:setItemId(37110)
    self.widgetStorage.transferButtonProcess = transferButtonProcess
    transferButtonProcess.onClick = function()
		transferButtonProcess:setEnabled(false)
		scheduleEvent(function ()
		    transferButtonProcess:setEnabled(true)
		end, 500, self)
        local firstItem = firstButtonPreviewItem:getItem()
        local secondItem = secondButtonPreviewItem:getItem()
        if not firstItem or not secondItem then
            return
        end
		
		local firstWidget = self.widgetStorage.firstButtonPreviewItem
		local firstItem = firstWidget:getItem()
		if not firstWidget or not firstItem then
		    return
		end
		local leftItemId = firstItem:getId()
		local leftItemTier = firstItem:getTier()
		
		local secondWidget = self.widgetStorage.secondButtonPreviewItem
		local secondItem = secondWidget:getItem()
		if not secondWidget or not secondItem then
		    return
		end
		local rightItemId = secondItem:getId()
		local rightTier = secondItem:getTier()
		
        g_game.sendForgeAction(1, self.widgetStorage.convergence:isChecked(), leftItemId, leftItemTier, rightItemId)
    end
end

function Transfer:get()
    return self
end

function Transfer:updateWidgets()
    local dustCost = 0	
    if Forge.data and Forge.data.config then
        local config = Forge.data.config	
        Forge:setWidget(self.widgetStorage.previewTransferItemCount, "0/1", false)
	
	    dustCost = config.dustNormalTransfer
	    if self.widgetStorage.convergence:isChecked() then
	       dustCost = config.dustConvergenceTransfer
	    end
	end
	
    Forge:setWidget(self.widgetStorage.requiredTransferDust, dustCost)
	Forge:setWidget(self.widgetStorage.requiredTransferCoreCount, "???", false)
	Forge:updateWidget('dust', self.widgetStorage.requiredTransferDust,  dustCost)
	self.widgetStorage.firstItemPanel:destroyChildren()
	self.widgetStorage.secondItemPanel:destroyChildren()
	Forge:setWidget(self.widgetStorage.requiredTransferMoney, "???", false)
	self.widgetStorage.transferButtonProcess:setEnabled(false)
	
	local item = self.widgetStorage.firstButtonPreviewItem:getItem()
	if item then
	    item:setTier(0)
		ItemsDatabase.setTier(self.widgetStorage.firstButtonPreviewItem, item)
	    self.widgetStorage.firstButtonPreviewItem:setItem(nil)
	end
	
	local item = self.widgetStorage.secondButtonPreviewItem:getItem()
	if item then
	    item:setTier(0)
		ItemsDatabase.setTier(self.widgetStorage.secondButtonPreviewItem, item)
	    self.widgetStorage.secondButtonPreviewItem:setItem(nil)
	end	
	
	local item = self.widgetStorage.previewTransferItem:getItem()
	if item then
	    item:setTier(0)
		ItemsDatabase.setTier(self.widgetStorage.previewTransferItem, item)
		self.widgetStorage.previewTransferItem:setItem(nil)
	end
	
end

function Transfer:setActiveItem(panel, id)
    if not self.activePanels then
	    self.activePanels = {}
	end
	
	if self.activePanels[id] then
	    self.activePanels[id]:setBorderColor('alpha')
		self.activePanels[id]:setBorderWidth(0)
		self.activePanels[id]:setOpacity(1)
	end
	
    panel:setBorderColor('yellow')
    panel:setBorderWidth(1)
	panel:setOpacity(0.7)
	
	self.activePanels[id] = panel
	
	if not self.activePanelList then
	    self.activePanelList = {}
	end
	
	self.activePanelList[id] = panel
end

function Transfer:displayItems(data)
    local data = self.transfers
	if not data then
	    return
	end
	
	local widgetData = self.widgetStorage
    local convergence = widgetData.convergence:isChecked()
	local firstItemPanel = widgetData.firstItemPanel
	local secondItemPanel = widgetData.secondItemPanel 
	local transferButtonProcess = widgetData.transferButtonProcess
	local firstButtonPreviewItem = widgetData.firstButtonPreviewItem
	local secondButtonPreviewItem = widgetData.secondButtonPreviewItem
	local previewTransferItem = widgetData.previewTransferItem
	local previewTransferItemCount = widgetData.previewTransferItemCount
	local previewTransferQuestionMark = widgetData.previewTransferQuestionMark
	local requiredTransferDust = widgetData.requiredTransferDust
	local requiredTransferCoreCount = widgetData.requiredTransferCoreCount
	local requiredTransferMoney = widgetData.requiredTransferMoney
	
    for i, v in ipairs(data) do
        for z, donor in ipairs(v.donors) do
            local id = donor.id
            local count = donor.count
            local tier = donor.tier
			local container = g_ui.createWidget('ForgeContainerItem', firstItemPanel)
		    container:setId('container '.. firstItemPanel:getId())
		    local containerPanel = container:getChildById('forgeItem')
		    local itemWidget = g_ui.createWidget('Item', containerPanel)
            --local itemWidget = g_ui.createWidget('Item', firstItemPanel)
            local item = Item.create(id)
            item:setTier(tier)
            itemWidget:setId('item' .. z)
            itemWidget:setItem(item)
            ItemsDatabase.setRarityItem(itemWidget, item)
            ItemsDatabase.setTier(itemWidget, item)
			local label = itemWidget:getChildById('charges2')
            if label then
                label:setText(count)
                label:setVisible(true)
            end

            itemWidget.onClick = function()
                secondItemPanel:destroyChildren()
				self:setActiveItem(container, container:getId())
                previewTransferItem:setItem(item)
                ItemsDatabase.setTier(previewTransferItem, item)
                firstButtonPreviewItem:setItem(item)
                previewTransferQuestionMark:setVisible(false)
                ItemsDatabase.setTier(firstButtonPreviewItem, item)
				
				Forge:setWidget(previewTransferItemCount, count .. "/" .. 1, true)
				
				local coreCost = Forge.data.exaltedCores[tostring(tier)]
				Forge:setWidget(requiredTransferCoreCount, coreCost)
				Forge:updateWidget("core", requiredTransferCoreCount, coreCost)
                local newTier = tier - 1
                local cost = Forge.data.classificationTable[tostring(item:getClassification())][tostring(newTier)]
				Forge:setWidget(requiredTransferMoney, cost)
				Forge:updateWidget('money', requiredTransferMoney, cost)
				
				
				requiredTransferMoney:setText(Forge:formatNumber(cost))
				
				if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("core") < coreCost then
				    self.widgetStorage.transferButtonProcess:setEnabled(false)
				else
				    if not Forge.preview then
				        self.widgetStorage.transferButtonProcess:setEnabled(true)
					end
				end

                for n, receiver in ipairs(v.receivers) do
                    local id2 = receiver.id
                    if id2 ~= id then
                        local count = receiver.count
                        local tier = receiver.tier
						local container = g_ui.createWidget('ForgeContainerItem', secondItemPanel)
		                container:setId('container '.. secondItemPanel:getId())
		                local containerPanel = container:getChildById('forgeItem')
						local itemWidget = g_ui.createWidget('Item', containerPanel)
                        local item = Item.create(id2)
                        item:setTier(tier)
                        itemWidget:setId('item' .. z)
                        itemWidget:setItem(item)
                        ItemsDatabase.setRarityItem(itemWidget, item)
                        ItemsDatabase.setTier(itemWidget, item)
						local label = itemWidget:getChildById('charges2')
                        if label then
                            label:setText(count)
                            label:setVisible(true)
                        end

                        itemWidget.onClick = function()
						    self:setActiveItem(container, container:getId())
							item:setTier(donor.tier - 1)
                            secondButtonPreviewItem:setItem(item)
                            ItemsDatabase.setTier(secondButtonPreviewItem, item)
                        end
                    end
                end
            end
        end
    end
end

function Transfer:displayConvergence()
    local data = self.convergenceTransfers
	if not data then
	    return
	end
	
	local widgetData = self.widgetStorage
    local convergence = widgetData.convergence:isChecked()
	local firstItemPanel = widgetData.firstItemPanel
	local secondItemPanel = widgetData.secondItemPanel 
	local transferButtonProcess = widgetData.transferButtonProcess
	local firstButtonPreviewItem = widgetData.firstButtonPreviewItem
	local secondButtonPreviewItem = widgetData.secondButtonPreviewItem
	local previewTransferItem = widgetData.previewTransferItem
	local previewTransferItemCount = widgetData.previewTransferItemCount
	local previewTransferQuestionMark = widgetData.previewTransferQuestionMark
	local requiredTransferDust = widgetData.requiredTransferDust
	local requiredTransferCoreCount = widgetData.requiredTransferCoreCount
	local requiredTransferMoney = widgetData.requiredTransferMoney
	
	self.widgetStorage.transferButtonProcess:setEnabled(false)
	
    for i, v in ipairs(data) do
        for z, donor in ipairs(v.donors) do
            local id = donor.id
            local count = donor.count
            local tier = donor.tier
			local container = g_ui.createWidget('ForgeContainerItem', firstItemPanel)
		    container:setId('container '.. firstItemPanel:getId())
		    local containerPanel = container:getChildById('forgeItem')
            local itemWidget = g_ui.createWidget('Item', containerPanel)
            local item = Item.create(id)
            item:setTier(tier)
            itemWidget:setId('item' .. z)
            itemWidget:setItem(item)
            ItemsDatabase.setRarityItem(itemWidget, item)
            ItemsDatabase.setTier(itemWidget, item)
			local label = itemWidget:getChildById('charges2')
            if label then
                label:setText(count)
                label:setVisible(true)
            end

            itemWidget.onClick = function()
			    local secondButtonItem = secondButtonPreviewItem:getItem()
				if secondButtonItem then
				    secondButtonItem:setTier()
					ItemsDatabase.setTier(secondButtonPreviewItem, secondButtonItem)
					secondButtonPreviewItem:setItem(nil)
				end
			    
                secondItemPanel:destroyChildren()
				self:setActiveItem(container, container:getId())
                previewTransferItem:setItem(item)
                ItemsDatabase.setTier(previewTransferItem, item)
                firstButtonPreviewItem:setItem(item)
                previewTransferQuestionMark:setVisible(false)
                ItemsDatabase.setTier(firstButtonPreviewItem, item)
				
				Forge:setWidget(previewTransferItemCount, count .. "/" .. 1, true)
				
				local coreCost = Forge.data.exaltedCores[tostring(tier)]
				Forge:setWidget(requiredTransferCoreCount, coreCost)
				Forge:updateWidget("core", requiredTransferCoreCount, coreCost)
                local newTier = tier - 1
                local cost = Forge.data.classificationTable[tostring(item:getClassification())][tostring(newTier)]
				Forge:setWidget(requiredTransferMoney, cost)
				Forge:updateWidget('money', requiredTransferMoney, cost)
				
				
				requiredTransferMoney:setText(Forge:formatNumber(cost))
				
				if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("core") < coreCost then
				    self.widgetStorage.transferButtonProcess:setEnabled(false)
				end

                for n, receiver in ipairs(v.receivers) do
                    local id2 = receiver.id
                    if id2 ~= id then
                        local count = receiver.count
                        local tier = receiver.tier
						local container = g_ui.createWidget('ForgeContainerItem', secondItemPanel)
						container:setId('container '.. secondItemPanel:getId())
						local containerPanel = container:getChildById('forgeItem')
						local itemWidget = g_ui.createWidget('Item', containerPanel)
                        local item = Item.create(id2)
                        item:setTier(receiver.tier)
                        itemWidget:setId('item' .. z)
                        itemWidget:setItem(item)
                        ItemsDatabase.setRarityItem(itemWidget, item)
                        ItemsDatabase.setTier(itemWidget, item)
						
						local label = itemWidget:getChildById('charges2')
						if label then
							label:setText(count)
							label:setVisible(true)
						end

                        itemWidget.onClick = function()
						    local item = Item.create(id2)
							item:setTier(donor.tier)
							secondButtonPreviewItem:setItem(item)
							ItemsDatabase.setTier(secondButtonPreviewItem, item)
							self:setActiveItem(container, container:getId())
							
							if Forge:getResourceBalance("money") >= cost and Forge:getResourceBalance("core") >= coreCost and Forge:getResourceBalance("dust") >= tonumber(requiredTransferDust:getText()) then
        						if not Forge.preview then
								    self.widgetStorage.transferButtonProcess:setEnabled(true)
								end
							end
                        end
                    end
                end
            end
        end
    end
end

function Transfer:parseData(data)

    scheduleEvent(function()
	
    self:updateWidgets()
	self.transfers = data.transfers
	self.convergenceTransfers = data.convergenceTransfers
	if self.widgetStorage.convergence:isChecked() then
	    self:displayConvergence()
	else
	    self:displayItems()
	end
    end, 10)

end

function Transfer:parseResult(data)	
end
