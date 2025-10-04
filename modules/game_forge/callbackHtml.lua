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
        local fusionLabel = self.modeFusion and 'Convergence Fusion' or 'Fusion'
        local title = string.format('Further Items Needed For %s', fusionLabel)
        ui.panels.fusion.test:setTitle(title)
    elseif window.panel == 'transfer' then
        local transferLabel = self.modeTransfer and 'Convergence transfer requeriments' or 'Transfer Requirements'
        ui.panels.transfer.test:setTitle(transferLabel)
    end
end

