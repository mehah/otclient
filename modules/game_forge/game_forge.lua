-- Todo 
-- change to TypeScript

local windowTypes = {}
local TAB_ORDER = {'fusion', 'transfer', 'conversion', 'history'}
local TAB_CONFIG = {
    fusion = {
        modeProperty = 'modeFusion'
    },
    transfer = {
        modeProperty = 'modeTransfer'
    },
    conversion = {},
    history = {}
}

ui = {
    panels = {}
}
forgeController = Controller:new()

local function loadTabFragment(tabName)
    local fragment = io.content(('modules/%s/tab/%s/%s.html'):format(forgeController.name, tabName, tabName))
    local container = forgeController.ui.content:prepend(fragment)
    local panel = container and container[tabName]
    if panel and panel.hide then
        panel:hide()
    end
    return panel
end

local function setWindowState(window, enabled)
    if window.obj then
        window.obj:setOn(not enabled)
        if enabled then
            window.obj:enable()
        else
            window.obj:disable()
        end
    end
end

local function hideAllPanels()
    for _, panel in pairs(ui.panels) do
        if panel and panel.hide then
            panel:hide()
        end
    end
end

function forgeController:onInit()
    forgeController:loadHtml('game_forge.html')
    g_ui.importStyle("otui/style.otui")
    self.modeFusion, self.modeTransfer = false, false

    for _, tabName in ipairs(TAB_ORDER) do
        self:loadTab(tabName)
    end
    hideAllPanels()

    local buttonPanel = self.ui.buttonPanel
    for tabName, config in pairs(TAB_CONFIG) do
        windowTypes[tabName .. 'Menu'] = {
            obj = buttonPanel and buttonPanel[tabName .. 'Btn'],
            panel = tabName,
            modeProperty = config.modeProperty
        }
    end

    SelectWindow("fusionMenu")
end

function SelectWindow(type, isBackButtonPress)
    local nextWindow = windowTypes[type]
    if not nextWindow then
        return
    end

    for windowType, window in pairs(windowTypes) do
        if windowType ~= type then
            setWindowState(window, true)
        end
    end

    setWindowState(nextWindow, false)
    forgeController.currentWindowType = type

    hideAllPanels()
    local panel = forgeController:loadTab(nextWindow.panel)
    if panel then
        panel:show()
        panel:raise()
    end
end

function forgeController:loadTab(tabName)
    if ui.panels[tabName] then
        return ui.panels[tabName]
    end

    local panel = loadTabFragment(tabName)
    if panel then
        ui.panels[tabName] = panel
    end
    return panel
end

function forgeController:getCurrentWindow()
    return self.currentWindowType and windowTypes[self.currentWindowType]
end

function forgeController:onTerminate()
end
function forgeController:onGameStart()
end
function forgeController:onGameEnd()
end
