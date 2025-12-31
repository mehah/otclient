Forge.Fusion = {}

local Fusion = Forge.Fusion
Fusion.mainWindow = nil

local fusionPanel = nil
local fusionContentPanel = nil
local previewPanel = nil
local previewFusionItem = nil
local previewFusionQuestionMark = nil
local previewPanel2 = nil
local previewFusionItem2 = nil
local previewFusionCountWidget = nil
local previewFusionCountValue = nil
local previewFusionQuestionMark2 = nil
local requiredItem = nil
local requiredImage = nil
local fusionData = {}
local fusionCache = {}
local fusionButtonProcced = nil
local fusionItem1 = nil
local fusionItem2 = nil
local fusionItem1Id = nil
local fusionItem2Id = nil
local fusionTier = nil
local fusionCost = nil
local exaltedCorePanel2 = nil
local exaltedCorePanel3 = nil
local convergenceDustCountValue = nil

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function Fusion:get()
    return self
end

function Fusion:createButton()
    local buttonPanel = g_ui.createWidget('ForgeButton', Forge.mainWindow)
	buttonPanel:setId('FusionButton')
	self.buttonPanel = buttonPanel
	self.mainButton = buttonPanel:getChildById('button')
	self.mainButton:setText("Fusion")
	local iconWidget = buttonPanel:getChildById('icon')
	iconWidget:setImageSource("/images/game/forge/icon-fusion")	
	g_ui.importStyle('fusion')
    self.mainWindow = g_ui.createWidget('FusionWindow', Forge.mainWindow)
	self.mainWindow:setVisible(false)
	self.mainWindow:addAnchor(AnchorTop,    'FusionButton', AnchorBottom)
	self.mainWindow:addAnchor(AnchorLeft,   'FusionButton', AnchorLeft)
	self.mainWindow:addAnchor(AnchorRight,  'parent', AnchorRight)
	self.mainWindow:addAnchor(AnchorBottom, 'parent', AnchorBottom)
	
	self:init()
			
    self.mainButton.onClick = function(widget, mousePos, mouseButton)
        self:showWindow()
    end
end

function Fusion:showWindow()
	if Forge.currentPanel then
	    Forge.currentPanel:setVisible(false)
	end
	
	if Forge.currentButton then
	    Forge.currentButton:setEnabled(true)
	end
	
	Forge.currentPanel = self.mainWindow
	Forge.currentButton = self.mainButton
	Forge.firstTooltip:setVisible(true)
	Forge.secondTooltip:setVisible(false)
    self.mainWindow:setVisible(true)
	self.mainButton:setEnabled(false)
end

local delay = 250
local lastClick = 0

function Fusion:init()
    self.data = nil
	local mainPanel1 = self.mainWindow:recursiveGetChildById('mainPanel1')
	local contentPanel = mainPanel1:recursiveGetChildById('contentPanel')
	self.contentPanel = contentPanel
	local previewPanel = mainPanel1:recursiveGetChildById('previewPanel')
	local convergenceWidget = previewPanel:recursiveGetChildById('convergence')
	self.convergenceWidget = convergenceWidget
	fusionPanel = mainPanel1
	fusionContentPanel = fusionPanel:recursiveGetChildById('contentPanel')
	previewPanel = fusionPanel:recursiveGetChildById('previewPanel')
	previewFusionItem = previewPanel:recursiveGetChildById('previewItem')
	previewFusionQuestionMark = previewPanel:recursiveGetChildById('previewQuestionMark')
	previewPanel2 = self.mainWindow:recursiveGetChildById('previewPanel2')
	previewFusionItem2 = previewPanel2:recursiveGetChildById('previewItem')
	previewFusionItem2Count = previewPanel2:recursiveGetChildById('previewCount')
	previewFusionItem2Value = previewFusionItem2Count:recursiveGetChildById('value')	
	previewFusionQuestionMark2 = previewPanel2:recursiveGetChildById('previewQuestionMark') 
	fusionButtonProcced = previewPanel2:recursiveGetChildById('fusionButtonProcced')
	fusionButtonProcced.onClick = function()
		fusionButtonProcced:setEnabled(false)
		scheduleEvent(function ()
		    fusionButtonProcced:setEnabled(true)
		end, 500, self)
        
		g_game.sendForgeAction(0, convergenceWidget:isChecked(), self.leftItemId, self.fusionTier, self.rightItemId, self.improveClicked, self.tierLossClicked)
	end
	
	
	fusionItem1 = fusionButtonProcced:recursiveGetChildById('item1')
	fusionItem2 = fusionButtonProcced:recursiveGetChildById('item2')
	
	exaltedCorePanel3 = previewPanel2:recursiveGetChildById('exaltedCorePanel3')
	fusionCost = exaltedCorePanel3:recursiveGetChildById('value')
	
	requiredItem = previewPanel2:recursiveGetChildById('requiredItem')
	requiredImage = previewPanel2:recursiveGetChildById('requiredImage')
	requiredCountPanel = previewPanel2:recursiveGetChildById('requiredCount')
	requiredCount = requiredCountPanel:recursiveGetChildById('value')
	
	successRateLabel = previewPanel2:recursiveGetChildById('successRate')
	improveButton = previewPanel2:recursiveGetChildById('improveButton')
	improveButton.onClick = function(widget)
	    if Fusion.improveClicked then
	        successRateValue:setColor("#F75F5F")
			successRateValue:setText(self.baseChance .. "%")
			Fusion.improveClicked = nil
			widget:setImageClip("0 0 22 23")
			if Forge:getResourceBalance('core') >= 1 then
			    tierLossButton:setEnabled(true)
				Forge:setWidget(exaltedCorePanel2Value, 1, true)
			end			
		else
		    successRateValue:setColor('#44AD25')
			successRateValue:setText(self.baseChance + self.improvedChance .. "%")
			Fusion.improveClicked = true
			widget:setImageClip("0 46 22 23")
			if Forge:getResourceBalance('core') < 2 then
			    tierLossButton:setEnabled(false)
				Forge:setWidget(exaltedCorePanel2Value, 1, false)
			end
			
		end
	end
		
	exaltedCorePanel = previewPanel2:recursiveGetChildById('exaltedCorePanel')
	exaltedCorePanelValue = exaltedCorePanel:recursiveGetChildById('value')
	successRateValue = previewPanel2:recursiveGetChildById('successRateValue')
		
	tierLossButton = previewPanel2:recursiveGetChildById('tierLossButton')
	tierLossButton.onClick = function(widget)
	    if Fusion.tierLossClicked then
	        tierLossValue:setColor("#F75F5F")
			tierLossValue:setText("100%")
			Fusion.tierLossClicked = nil
			widget:setImageClip("0 0 22 23")
			if Forge:getResourceBalance('core') >= 1 then
			    improveButton:setEnabled(true)
				Forge:setWidget(exaltedCorePanelValue, 1, true)
			end			
		else
		    tierLossValue:setColor('#44AD25')
			tierLossValue:setText("50%")
			Fusion.tierLossClicked = true
			widget:setImageClip("0 46 22 23")
			if Forge:getResourceBalance('core') < 2 then
			    improveButton:setEnabled(false)
				Forge:setWidget(exaltedCorePanelValue, 1, false)
			end
			
		end
	end	
	
	tierLossLabel = previewPanel2:recursiveGetChildById('tierLoss')
	exaltedCorePanel2 = previewPanel2:recursiveGetChildById('exaltedCorePanel2')
	exaltedCorePanel2Value = exaltedCorePanel2:recursiveGetChildById('value')
	tierLossValue = previewPanel2:recursiveGetChildById('tierLossValue')
	fusionContent2 = previewPanel2:recursiveGetChildById('fusionContent2')
	fusionContent2ScrollBar = previewPanel2:recursiveGetChildById('fusionScrollBar2')
	convergenceDustItem = previewPanel2:recursiveGetChildById('convergenceDustItem')
	convergenceDustImage = previewPanel2:recursiveGetChildById('convergenceDustImage')
	convergenceDustCountPanel = previewPanel2:recursiveGetChildById('convergenceDustCountPanel')
	convergenceDustCountValue = convergenceDustCountPanel:recursiveGetChildById('value')
		
	convergenceWidget.onClick = function(widget)
	    if not widget:isChecked() then
		    widget:setChecked(true)
			self:displayConvergence()
		else
		    widget:setChecked(false)
			self:displayItems()
		end
	end
	self.convergenceWidget = convergenceWidget
end
	
function Fusion:hasConvergence()
    return self.convergenceWidget:isChecked()
end

function Fusion:displayConvergence(preview)
    self:updateWidgets()
    Forge:setWidget(fusionCost, "???", false)
    Forge:setWidget(convergenceDustCountValue, self.dustConvergenceFusion, true)
    Forge:updateWidget("dust", convergenceDustCountValue, 130)
    self.contentPanel:destroyChildren()
	fusionContent2:destroyChildren()
    fusionButtonProcced:setEnabled(false)
	
	if not self.data then
	    return
	end
	
	local data = self.data.convergenceFusion
	if not data then
	    return
	end
	
	
	for i, itemsTable in ipairs(data) do
	    for z, v in ipairs(itemsTable) do
		    local container = g_ui.createWidget('ForgeContainerItem', self.contentPanel)
		    container:setId('container '.. fusionContentPanel:getId())
		    local containerPanel = container:getChildById('forgeItem')
		    local itemWidget = g_ui.createWidget('Item', containerPanel)			
            local item = Item.create(v.id)
            item:setTier(v.tier)
            itemWidget:setId('item' .. z)
            itemWidget:setItem(item)
            local label = itemWidget:getChildById('charges2')
            if label then
                label:setText(v.count)
                label:setVisible(true)
            end
			
			local classification = tostring(item:getClassification())
            local tier = tostring(v.tier)
            local cost = self.convergenceFusionCost[tier]
			
			local mainItem = item
			
            ItemsDatabase.setRarityItem(itemWidget, item)
            ItemsDatabase.setTier(itemWidget, item)
			itemWidget.onClick = function()
			    fusionContent2:destroyChildren()
				fusionButtonProcced:setEnabled(false)
				previewFusionQuestionMark:setVisible(false)
                previewFusionQuestionMark2:setVisible(false)
				self:setActiveItem(container, container:getId())
                fusionItem1:setItem(item)
                ItemsDatabase.setTier(fusionItem1, item)
				
				item:setTier(v.tier + 1)
				previewFusionItem:setItem(item)
				ItemsDatabase.setTier(previewFusionItem, item)
				
				if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("dust") < self.dustConvergenceFusion then
			        fusionItem1:setOpacity(0.3)
			        fusionItem2:setOpacity(0.3)
			    end
				
				Forge:updateWidget("money", fusionCost, cost)
                fusionCost:setText(Forge:formatNumber(cost))
				
				for n, m in ipairs(itemsTable) do
				    local _canFusion = false
					if m.id == v.id then
					    if m.tier == v.tier then
						    if m.count >= 2 then
							    _canFusion = true
							end
						end
					else
					    if m.tier == v.tier then
					        _canFusion = true
						end
					end
					
					if _canFusion then
						local container = g_ui.createWidget('ForgeContainerItem', fusionContent2)
						container:setId('container '.. fusionContent2:getId())
						local containerPanel = container:getChildById('forgeItem')
						local itemWidget = g_ui.createWidget('Item', containerPanel)
						---local itemWidget = g_ui.createWidget('Item', fusionContent2)
						local item = Item.create(m.id)
						item:setTier(m.tier)
						itemWidget:setId('item' .. z)
						itemWidget:setItem(item)
						local label = itemWidget:getChildById('charges2')
						if label then
							label:setText(m.count)
							label:setVisible(true)
						end
						ItemsDatabase.setRarityItem(itemWidget, item)
						ItemsDatabase.setTier(itemWidget, item)	
						
						itemWidget.onClick = function()	
                            mainItem:setTier(v.tier + 1)
							self.leftItemId = fusionItem1:getItem():getId()
							self.rightItemId = m.id
							self.fusionTier = v.tier							
						    fusionItem2:setItem(mainItem)
							ItemsDatabase.setTier(fusionItem2, mainItem)	
							if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("dust") < self.dustConvergenceFusion then
								fusionButtonProcced:setEnabled(false)
								fusionItem1:setOpacity(0.3)
								fusionItem2:setOpacity(0.3)
							else
							    if not Forge.preview then
								    fusionButtonProcced:setEnabled(true)
								end
							end
						

							self:setActiveItem(container, container:getId())
                        end
					
                    end					
				end	
					
					
					
					
			end	
		end
	end
	
	-- local first = true
    -- for i, itemsTable in ipairs(data) do
	    -- if first then
		    -- print("Data:" .. dump(data))
		    -- first = false
		-- end
        -- for z, v in ipairs(itemsTable) do
            -- -- local itemWidget = g_ui.createWidget('Item', self.contentPanel)	
		    -- local container = g_ui.createWidget('ForgeContainerItem', self.contentPanel)
		    -- container:setId('container '.. fusionContentPanel:getId())
		    -- local containerPanel = container:getChildById('forgeItem')
		    -- local itemWidget = g_ui.createWidget('Item', containerPanel)			
            -- local item = Item.create(v.id)
            -- item:setTier(v.tier)
            -- itemWidget:setId('item' .. z)
            -- itemWidget:setItem(item)
            -- local label = itemWidget:getChildById('charges2')
            -- if label then
                -- label:setText(v.count)
                -- label:setVisible(true)
            -- end
            -- ItemsDatabase.setRarityItem(itemWidget, item)
            -- ItemsDatabase.setTier(itemWidget, item)

            -- itemWidget.onClick = function()
                -- fusionContent2:destroyChildren()
                -- fusionButtonProcced:setEnabled(false)
                -- previewFusionQuestionMark:setVisible(false)
                -- previewFusionQuestionMark2:setVisible(false)
				-- self:setActiveItem(container, container:getId())
                -- fusionItem1:setItem(item)
                -- ItemsDatabase.setTier(fusionItem1, item)

                -- local item = Item.create(v.id)
                -- item:setTier(v.tier + 1)
                -- previewFusionItem:setItem(item)
                -- ItemsDatabase.setTier(previewFusionItem, item)
                -- previewFusionItem:setColor("black")
                -- fusionItem2:setItem(item)
                -- ItemsDatabase.setTier(fusionItem2, item)

                -- local classification = tostring(item:getClassification())
                -- local tier = tostring(v.tier)
                -- local cost = self.convergenceFusionCost[tier]

			    -- if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("dust") < self.dustConvergenceFusion then
			        -- fusionItem1:setOpacity(0.3)
			        -- fusionItem2:setOpacity(0.3)
				    -- fusionButtonProcced:setEnabled(false)
			    -- end
				
				-- Forge:updateWidget("money", fusionCost, cost)
                -- fusionCost:setText(Forge:formatNumber(cost))
                
				-- local test = true
                -- if test then
					-- local container = g_ui.createWidget('ForgeContainerItem', fusionContent2)
		            -- container:setId('container '.. fusionContent2:getId())
		            -- local containerPanel = container:getChildById('forgeItem')
		            -- local itemWidget = g_ui.createWidget('Item', containerPanel)
                    -- ---local itemWidget = g_ui.createWidget('Item', fusionContent2)
                    -- local item = Item.create(v.id)
                    -- item:setTier(v.tier)
                    -- itemWidget:setId('item' .. z)
                    -- itemWidget:setItem(item)
                    -- local label = itemWidget:getChildById('charges2')
                    -- if label then
                        -- label:setText(v.count)
                        -- label:setVisible(true)
                    -- end
                    -- ItemsDatabase.setRarityItem(itemWidget, item)
                    -- ItemsDatabase.setTier(itemWidget, item)

                    -- itemWidget.onClick = function()
                        -- if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("dust") < self.dustConvergenceFusion then
                            -- fusionButtonProcced:setEnabled(false)
							-- fusionItem1:setOpacity(0.3)
			                -- fusionItem2:setOpacity(0.3)
                        -- else
						    -- fusionButtonProcced:setEnabled(true)
						-- end
						
			            -- self.leftItemId = fusionItem1:getItem():getId()
			            -- self.rightItemId = fusionItem2:getItem():getId()
			            -- self.fusionTier = v.tier
						-- self:setActiveItem(container, container:getId())
                    -- end
                -- end
            -- end
        -- end
    -- end
end

function Fusion:updateWidgets()
	if self.convergenceWidget:isChecked() then
		previewFusionItem2:setVisible(false)
	    previewFusionItem2Count:setVisible(false)
		previewFusionQuestionMark2:setVisible(false)
		requiredItem:setVisible(false)
		requiredImage:setVisible(false)
		requiredCountPanel:setVisible(false)
		successRateLabel:setVisible(false)
		improveButton:setVisible(false)
		exaltedCorePanel:setVisible(false)
		successRateValue:setVisible(false)
		tierLossButton:setVisible(false)
		tierLossLabel:setVisible(false)
		exaltedCorePanel2:setVisible(false)
		tierLossValue:setVisible(false)
		fusionContent2:setVisible(true)
		--showItems(true, fusionContent2, convergenceItems)
		fusionContent2ScrollBar:setVisible(true)
		convergenceDustItem:setVisible(true)
		convergenceDustImage:setVisible(true)
		convergenceDustCountPanel:setVisible(true)
		fusionButtonProcced:setEnabled(false)
		local item = previewFusionItem:getItem()
		if item then
			item:setTier(0)
			ItemsDatabase.setTier(previewFusionItem, item)
			previewFusionItem:setItem(nil)
		end
		if item then
			item:setTier(0)
		    ItemsDatabase.setTier(fusionItem1, item)
			fusionItem1:setItem(nil)
		end
		local item = fusionItem2:getItem()
		if item then
			item:setTier(0)
			ItemsDatabase.setTier(fusionItem2, item)
			fusionItem2:setItem(nil)
		end			
		previewFusionQuestionMark:setVisible(true)
		fusionCost:setText('???')
		fusionCost:setColor(notEnoughColor)
	else
		previewFusionItem2:setVisible(true)
		previewFusionItem2Count:setVisible(true)
		previewFusionQuestionMark2:setVisible(true)
		requiredItem:setVisible(true)
		requiredImage:setVisible(true)
		requiredCountPanel:setVisible(true)
		successRateLabel:setVisible(true)
		improveButton:setVisible(true)
		exaltedCorePanel:setVisible(true)
		successRateValue:setVisible(true)
		tierLossButton:setVisible(true)
		tierLossLabel:setVisible(true)
		exaltedCorePanel2:setVisible(true)
		tierLossValue:setVisible(true)
		fusionContent2:setVisible(false)
		fusionContent2ScrollBar:setVisible(false)
		convergenceDustItem:setVisible(false)
		convergenceDustImage:setVisible(false)
		convergenceDustCountPanel:setVisible(false)
		--fusionCache = fusionItemsCache
		previewPanel2:setVisible(true)
		--showItems(true, fusionContentPanel, fusionCache)
		local item = previewFusionItem:getItem()
		if item then
			item:setTier(0)
			ItemsDatabase.setTier(previewFusionItem, item)
			previewFusionItem:setItem(nil)
		end
		local item = fusionItem1:getItem()
		if item then
			item:setTier(0)
		    ItemsDatabase.setTier(fusionItem1, item)
			fusionItem1:setItem(nil)
		end
		local item = fusionItem2:getItem()
		if item then
			item:setTier(0)
		    ItemsDatabase.setTier(fusionItem2, item)
			fusionItem2:setItem(nil)
		end
		previewFusionQuestionMark:setVisible(true)
		fusionCost:setText('???')
	end
end

function Fusion:setActiveItem(panel, id)
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
	

function Fusion:displayItems(preview)
    Forge:setWidget(previewFusionItem2Value, "0/1", false)
	Forge:setWidget(fusionCost, "???", false)
    fusionButtonProcced:setEnabled(false)
	
	fusionItem1:setOpacity(1)
	fusionItem2:setOpacity(1)
	
    self:updateWidgets()
	


	local item = previewFusionItem2:getItem()
	if item then
	    item:setTier(0)
		ItemsDatabase.setTier(previewFusionItem2, item)
	    previewFusionItem2:setItem(nil)
	end
	
	
	scheduleEvent(function()
		Forge:updateWidget("dust", requiredCount, self.dustNormalFusion)
		Forge:updateWidget("core", exaltedCorePanel2Value, 1)
		Forge:updateWidget("core", exaltedCorePanelValue, 1)
		tierLossButton:setEnabled(true)
		tierLossValue:setColor("#F75F5F")
		tierLossValue:setText("100%")
		Fusion.tierLossClicked = nil
		tierLossButton:setImageClip("0 0 22 23")
	
		improveButton:setEnabled(true)
		successRateValue:setColor("#F75F5F")
		successRateValue:setText(self.baseChance .. "%")
		Fusion.improveClicked = nil
		improveButton:setImageClip("0 0 22 23")	
		
		
		if Forge:getResourceBalance("core") < 1 then
		    tierLossButton:setEnabled(false)
			improveButton:setEnabled(false)
		end
	end, 10)
	
    self.contentPanel:destroyChildren()

    if not self.data then
        return
    end

    local fusionItems = self.data.fusionItems

    for i, v in ipairs(fusionItems) do
        local id = tonumber(v.id)
		local count = v.count
		local container = g_ui.createWidget('ForgeContainerItem', fusionContentPanel)
		container:setId('container '.. fusionContentPanel:getId())
		local containerPanel = container:getChildById('forgeItem')
		local itemWidget = g_ui.createWidget('Item', containerPanel)
        local item = Item.create(id)
        item:setTier(v.tier)
        itemWidget:setId('item' .. i)
        itemWidget:setItem(item)

        local label = itemWidget:getChildById('charges2')
        if label then
            label:setText(v.count)
            label:setVisible(true)
        end

        ItemsDatabase.setRarityItem(itemWidget, item)
        ItemsDatabase.setTier(itemWidget, item)

        itemWidget.onClick = function()
		    self:setActiveItem(container, container:getId())
            previewFusionQuestionMark:setVisible(false)
            previewFusionQuestionMark2:setVisible(false)

            previewFusionItem2:setItem(item)
            ItemsDatabase.setTier(previewFusionItem2, item)
			Forge:setWidget(previewFusionItem2Value, v.count .. "/1", true)
            --previewFusionItem2Count:setText(v.count .. "/1")
            
            fusionItem1:setItem(item)
			
            ItemsDatabase.setTier(fusionItem1, item)

            local nextItem = Item.create(id)
            nextItem:setTier(v.tier + 1)

            previewFusionItem:setItem(nextItem)
            ItemsDatabase.setTier(previewFusionItem, nextItem)
            previewFusionItem:setColor("black")

            fusionItem2:setItem(nextItem)
            ItemsDatabase.setTier(fusionItem2, nextItem)

            local classification = tostring(nextItem:getClassification())
            local tier = tostring(v.tier)
            --local cost = self.data.convergenceFusion[tier]
			
			local cost = self.classificationTable[classification][tier]
			Forge:updateWidget("money", fusionCost, cost)
			
			if Forge:getResourceBalance("money") < cost or Forge:getResourceBalance("dust") < self.dustNormalFusion then
			    fusionItem1:setOpacity(0.3)
			    fusionItem2:setOpacity(0.3)
				fusionButtonProcced:setEnabled(false)
			else
			    if not Forge.preview then
			        fusionButtonProcced:setEnabled(true)
				end
			end	
			
			self.leftItemId = fusionItem1:getItem():getId()
			self.rightItemId = self.leftItemId
			self.fusionTier = v.tier
            
            fusionCost:setText(Forge:formatNumber(cost))
        end
    end
end

function Fusion:parseData(data)
    self.data = data
	if self.convergenceWidget:isChecked() then
	    self:displayConvergence()
	else
	    self:displayItems()
	end
	if not Forge.mainWindow:isVisible() then
	    Forge.mainWindow:setVisible(true)
	end
	Forge.mainWindow:raise()
	Forge.mainWindow:focus() 
	self:showWindow()
end

function Fusion:parseResourcesChange(data)
    self.classificationTable = data.classificationTable
	self.dustNormalFusion = data.config.dustNormalFusion
	self.dustConvergenceFusion = data.config.dustConvergenceFusion
	self.baseChance = data.config.baseChance
	self.improvedChance = data.config.improvedChance
	self.convergenceFusionCost = data.convergenceFusion
end

function Fusion:parseResult(data)
    
	--Forge:updateWidget(
    -- if data.success == 1 then
	    -- if data.convergence == 0 then
	        -- for i, v in ipairs(self.data.fusionItems) do
		        -- if v.id == data.leftItemId then
			        -- if v.tier == data.leftTier then
				        -- v.count = v.count - 2
				    -- end
				    -- if v.count < 2 then
				        -- self.data.fusionItems[i] = nil
				    -- end
				-- end
			-- end
			-- self:displayItems()
			-- return
		-- end
	-- end
	
end

     
