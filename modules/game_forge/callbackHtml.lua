-- Todo
-- change to TypeScript
function forgeController:loadMenu(a, b, c)
    SelectWindow(a)
end

function forgeController:onCheckChangeConvergence(widget)
    local window = self:getCurrentWindow()
    if not window or not window.modeProperty then
        return
    end

    self[window.modeProperty] = widget.checked

    if window.panel == 'fusion' then
        self.fusionConvergence = not self.fusionConvergence
        self[window.modeProperty] = self.fusionConvergence
        local fusionLabel = self.modeFusion and 'Convergence Fusion' or 'Fusion'
        local title = string.format('Further Items Needed For %s', fusionLabel)
        self.fusionConvergenceTitle = title
        self:updateFusionItems(self.fusionConvergence)
    elseif window.panel == 'transfer' then
        self.transferConvergence = not self.transferConvergence
        self[window.modeProperty] = self.transferConvergence
        local transferLabel = self.modeTransfer and 'Convergence transfer requeriments' or 'Transfer Requirements'
        self.transferConvergenceTitle = transferLabel
        self:updateFusionItems(self.transferConvergence, true)

        if not self.transferConvergence then
            self.transferDustAmount = self.normalDustTransfer
        else
            self.transferDustAmount = self.convergenceDustTransfer
        end
        self.transferDustAmountColor = self:getColorByStatus(self.currentDust < self.transferDustAmount)
    end
end
