Forge.History = {}

local History = Forge.History
History.mainWindow = nil

function History:get()
    return self
end



function History:createButton()
    local buttonPanel = g_ui.createWidget('ForgeButton', Forge.mainWindow)
	buttonPanel:addAnchor(AnchorTop, 'FusionButton', AnchorTop)
	buttonPanel:addAnchor(AnchorLeft, 'ConversionButton', AnchorRight)
	buttonPanel:setId('HistoryButton')
	self.buttonPanel = buttonPanel
	self.mainButton = buttonPanel:getChildById('button')
	self.mainButton:setText("History")
	
	
	local iconWidget = buttonPanel:getChildById('icon')
	iconWidget:setImageSource("/images/game/forge/icon-history")			
    if not self.mainWindow then
	    g_ui.importStyle('History')
        self.mainWindow = g_ui.createWidget('HistoryWindow', Forge.mainWindow)
		self.mainWindow:addAnchor(AnchorTop,    'TransferButton', AnchorBottom)
		self.mainWindow:addAnchor(AnchorLeft,   'FusionButton', AnchorLeft)
		self.mainWindow:addAnchor(AnchorRight,  'parent', AnchorRight)
		
		self.mainPanel = self.mainWindow:getChildById('mainPanel')
	    --self.datePanel = self.mainPanel:getChildById('datePanel')
		self.dateButton = self.mainPanel:getChildById('dateButton')
		self.actionButton = self.mainPanel:getChildById('actionButton')
		self.contentPanel = self.mainPanel:getChildById('contentPanel')
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
		g_game.sendForgeHistory(1)
    end
	self:init()
end

function History:addDate(date, action, details)
    local dateWidget = g_ui.createWidget('ForgeHistoryWidget', self.contentPanel)
	
	
	local dateLabel = dateWidget:getChildById('date')
	dateLabel:setText(date)
	
	local actionLabel = dateWidget:recursiveGetChildById('action')
	actionLabel:setText(action)
	actionLabel:setColor('#2791F5')
	
	
	local actionLabel = dateWidget:getChildById('details')
	actionLabel:setText(details)	
	
	local firstColor = "#414141"
	local secondColor = "#484848"
	
	
	if not self.currentColor then
	    self.currentColor = firstColor
	else
	    if self.currentColor == firstColor then
		    self.currentColor = secondColor
		elseif self.currentColor == secondColor then
		    self.currentColor = firstColor
		end
	end
	
	dateWidget:setBackgroundColor(self.currentColor)
end

function parseDetails(details)
    if not details then
        return ""
    end

    -- wyciągamy tylko "Successful" albo "Unsuccessful", albo zostawiamy tekst
    local result = details:match("Successful")
    if result then return "Successful" end

    result = details:match("Unsuccessful")
    if result then return "Unsuccessful" end

    -- jeżeli to nie Fusion tylko np. Conversion → zwracamy cały opis
    return details:gsub("<br>", " "):gsub("<.->", "")
end

function getStringByActionType(value)
    if value == 0 then
	    return "Fusion"
	end
	
	if value == 1 then
	    return "Transfer"
	end
	
	if value >= 2 then
	    return "Conversion"
	end
end
	

function History:parse(currentPage, lastPage, data)	
	self.currentPage = currentPage
	self.lastPage = lastPage
	self.data = data
	self.contentPanel:destroyChildren()
	
	
	for i, v in ipairs(self.data) do
	    History:addDate(v.date, getStringByActionType(tonumber(v.action)), parseDetails(v.details))
	end
	
end

function History:init()
end
