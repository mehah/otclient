-- https://github.com/opentibiabr/myaac/pull/33/files

local MainWindowsCreateAccount = nil

local UIwidgetImagen = {
    AccountData = nil,
    AllData = nil,
    CharacterData = nil
}

local UIComboBox = {
    world = nil,
    pvp = nil
}

local UITextEdit = {
    email = nil,
    password = nil,
    repeatPassword = nil,
    character = nil
}

local iconsCreateAccount = {
    Password = nil,
    Email = nil,
    RepeatPassword = nil,
    CheckBox = nil
}
local iconsCreateCharacter = {
    Sex = nil,
    RecommendedWorld = nil,
    CharacterName = nil
}
local UITextList = {
    listAllWorlds = nil
}

local UIlabel = {
    RecommendedWorld = nil,
    passwordSecurityLevel = nil,
    titleMiniPanelWorld = nil
}

local globalInfo = {
    email = "",
    password = "",
    characterName = "",
    characterSex = "",
    selectedWorld = ""
}

local toolstips = {
    password = nil,
    allExceptPassword = nil
}

local auxWidgets = {
    worldDefault = nil
}

local Worlds = {}

local sexModeGroup = nil

-- /*=============================================
-- =            http post // receive             =
-- =============================================*/
local lastRequestTime = {}
local REQUEST_COOLDOWN = 500

local function reportRequestWarning(requestType, msg, errorCode)
    g_logger.warning(("[Webscraping - %s] %s"):format(requestType, msg), errorCode)
end

local function handleHttpResponse(requestType, callback)
    return function(message, err)
        if err then
            reportRequestWarning(requestType, requestType, "fx handleHttpResponse")
            return callback(nil, err)
        end
        local json_part = message:match("{.*}")
        if not json_part then
            reportRequestWarning(requestType, "ERROR: JSON not found in the response", "fx handleHttpResponse")
            return
        end
        local status, response = pcall(json.decode, json_part)
        if not status then
            if requestType == "getaccountcreationstatus" then
                ensableBtnCreateNewAccount()
            end
            reportRequestWarning(requestType, "[HTTP] JSON decode error: " .. response, "fx handleHttpResponse")
            return
        end
        if type(response) ~= "table" then
            reportRequestWarning(requestType, "[HTTP] Invalid response format", "fx handleHttpResponse")
            return
        end
        if not status then
            reportRequestWarning(requestType, response, "fx handleHttpResponse")
            return callback(nil, response)
        end
        return callback(response)
    end
end

-- Account creation status request
local function getAccountCreationStatus(callback)
    --[[     HTTP.addCustomHeader({
        ["Date"] = "Fri, 14 Feb 2025 22:13:09 GMT",
        ["Content-Type"] = "application/json; charset=utf-8",
        ["Content-Length"] = "3787",
        ["Connection"] = "keep-alive",
        ["content-security-policy"] = "frame-ancestors 'self';script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' *.tibia.com *.cipsoft.com *.cipsoft.de https://www.youtube.com https://platform.twitter.com https://www.paypal.com https://www.sandbox.paypal.com https://www.google.com https://s.ytimg.com https://www.gstatic.com https://www.googletagmanager.com https://googleads.g.doubleclick.net;connect-src 'self' *.tibia.com *.cipsoft.com *.cipsoft.de https://rpc.walletconnect.com https://rpc.walletconnect.org https://explorer-api.walletconnect.com https://explorer-api.walletconnect.org https://relay.walletconnect.com https://relay.walletconnect.org wss://relay.walletconnect.com wss://relay.walletconnect.org https://pulse.walletconnect.com https://pulse.walletconnect.org https://api.web3modal.com https://api.web3modal.org https://keys.walletconnect.com https://keys.walletconnect.org https://notify.walletconnect.com https://notify.walletconnect.org https://echo.walletconnect.com https://echo.walletconnect.org https://push.walletconnect.com https://push.walletconnect.org wss://www.walletlink.org https://bsc-dataseed.binance.org/;",
        ["x-content-security-policy"] = "frame-ancestors 'self';script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' *.tibia.com *.cipsoft.com *.cipsoft.de https://www.youtube.com https://platform.twitter.com https://www.paypal.com https://www.sandbox.paypal.com https://www.google.com https://s.ytimg.com https://www.gstatic.com https://www.googletagmanager.com https://googleads.g.doubleclick.net;connect-src 'self' *.tibia.com *.cipsoft.com *.cipsoft.de https://rpc.walletconnect.com https://rpc.walletconnect.org https://explorer-api.walletconnect.com https://explorer-api.walletconnect.org https://relay.walletconnect.com https://relay.walletconnect.org wss://relay.walletconnect.com wss://relay.walletconnect.org https://pulse.walletconnect.com https://pulse.walletconnect.org https://api.web3modal.com https://api.web3modal.org https://keys.walletconnect.com https://keys.walletconnect.org https://notify.walletconnect.com https://notify.walletconnect.org https://echo.walletconnect.com https://echo.walletconnect.org https://push.walletconnect.com https://push.walletconnect.org wss://www.walletlink.org https://bsc-dataseed.binance.org/;",
        ["x-webkit-csp"] = "frame-ancestors 'self';script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' *.tibia.com *.cipsoft.com *.cipsoft.de https://www.youtube.com https://platform.twitter.com https://www.paypal.com https://www.sandbox.paypal.com https://www.google.com https://s.ytimg.com https://www.gstatic.com https://www.googletagmanager.com https://googleads.g.doubleclick.net;connect-src 'self' *.tibia.com *.cipsoft.com *.cipsoft.de https://rpc.walletconnect.com https://rpc.walletconnect.org https://explorer-api.walletconnect.com https://explorer-api.walletconnect.org https://relay.walletconnect.com https://relay.walletconnect.org wss://relay.walletconnect.com wss://relay.walletconnect.org https://pulse.walletconnect.com https://pulse.walletconnect.org https://api.web3modal.com https://api.web3modal.org https://keys.walletconnect.com https://keys.walletconnect.org https://notify.walletconnect.com https://notify.walletconnect.org https://echo.walletconnect.com https://echo.walletconnect.org https://push.walletconnect.com https://push.walletconnect.org wss://www.walletlink.org https://bsc-dataseed.binance.org/;",
        ["strict-transport-security"] = "max-age=15552000;",
        ["vary"] = "Accept-Encoding",
        ["Content-Encoding"] = "gzip",
        ["CF-Cache-Status"] = "DYNAMIC",
        ["Server"] = "cloudflare",
        ["CF-RAY"] = "91206759bef5b440-SCL",
        ["alt-svc"] = 'h3=":443"; ma=86400'
    }) ]]
    HTTP.post(Services.createAccount, json.encode({
        type = "getaccountcreationstatus"
    }), handleHttpResponse("getaccountcreationstatus", callback), false)
    --[[
         
    { 

    ["RecommendedWorld"] = "Ustebra",
    ["IsCaptchaDeactivated"] = false,
    ["Worlds"] = { 
        [1] = { 
            ["Region"] = "North America",
            ["BattlEyeActivationTimestamp"] = 1729065600,
            ["PremiumOnly"] = 0,
            ["BattlEyeInitiallyActive"] = 1,
            ["TransferType"] = "Blocked",
            ["PvPType"] = "Open PvP",
            ["PlayersOnline"] = 32,
            ["Name"] = "Aethera",
            ["CreationDate"] = 1729065600
        },
        [2] = { 
            ["Region"] = "South America",
            ["BattlEyeActivationTimestamp"] = 1697616000,
            ["PremiumOnly"] = 0,
            ["BattlEyeInitiallyActive"] = 1,
            ["TransferType"] = "Blocked",
            ["PvPType"] = "Retro Open PvP",
            ["PlayersOnline"] = 38,
            ["Name"] = "Ambra",
            ["CreationDate"] = 1697616000
        },
        [3] = { 
            ["Region"] = "Europe",
            ["BattlEyeActivationTimestamp"] = 1503993600,
            ["PremiumOnly"] = 0,
            ["BattlEyeInitiallyActive"] = 0,
            ["TransferType"] = "Standard",
            ["PvPType"] = "Open PvP",
            ["PlayersOnline"] = 271,
            ["Name"] = "Antica",
            ["CreationDate"] = 852109200
        },
    }
    } ]]
end

local function generateCharacterName(callback)
    HTTP.post(Services.createAccount, json.encode({
        type = "generatecharactername"
    }), handleHttpResponse("generatecharactername", callback), false)
end

local function checkCharacterName(name, callback)
    HTTP.post(Services.createAccount, json.encode({
        type = "checkcharactername",
        CharacterName = name
    }), handleHttpResponse("checkcharactername", callback), false)
    --[[     
    { 
        ["CharacterName"] = "asdasd",
        ["errorCode"] = 99,
        ["IsAvailable"] = false,
        ["errorMessage"] = "The first letter of a name has to be a capital letter."
    } ]]
end

local function checkEmail(email, callback)
    HTTP.post(Services.createAccount, json.encode({
        type = "checkemail",
        Email = email
    }), handleHttpResponse("checkemail", callback), false)

    --[[     
    { 
        ["errorCode"] = 59,
        ["EMail"] = "asdasd",
        ["errorMessage"] = "This email address has an invalid format. Please enter a correct email address!"
    } ]]
end

local function checkPassword(password, callback)
    HTTP.post(Services.createAccount, json.encode({
        type = "checkpassword",
        Password1 = password
    }), handleHttpResponse("checkpassword", callback), false)
    --[[     { 
        ["PasswordStrength"] = 0,
        ["PasswordStrengthColor"] = "#EC644B",
        ["PasswordValid"] = false,
        ["PasswordRequirements"] = { 
            ["HasUpperCase"] = false,
            ["HasNumber"] = false,
            ["PasswordLength"] = false,
            ["InvalidCharacters"] = true,
            ["HasLowerCase"] = true
        },
        ["Password1"] = "asdasd"
    } ]]
end

local function createAccountAndCharacter(array, callback)
    HTTP.post(Services.createAccount, json.encode({
        type = "createaccountandcharacter",
        EMail = array.email,
        Password = array.password,
        CharacterName = array.characterName,
        CharacterSex = array.characterSex
    }), handleHttpResponse("createaccountandcharacter", callback), false)
end

-- /*=============================================
-- =            successfull Check               =
-- =============================================*/
local function checkAllRequirements()
    local function allWidgetsEnabled(widgets)
        for _, widget in pairs(widgets) do
            if not widget:isEnabled() then
                return false
            end
        end
        return true
    end
    local createAccountPassed = allWidgetsEnabled(iconsCreateAccount)
    local createYourCharacterPassed = allWidgetsEnabled(iconsCreateCharacter)
    UIwidgetImagen.AccountData:setEnabled(createAccountPassed)
    UIwidgetImagen.AllData:setEnabled(createAccountPassed and createYourCharacterPassed)
    UIwidgetImagen.CharacterData:setEnabled(createYourCharacterPassed)
    return createAccountPassed and createYourCharacterPassed
end

local function updateButtonState(button)
    button:setEnabled(checkAllRequirements())
end

local function setRequirementState(widget, enabled, widgetError, errorMessage)
    widget:setEnabled(enabled)
    updateButtonState(MainWindowsCreateAccount.createAccount.buttonStartPlaying)

    if widgetError then
        local errorWidget = toolstips.allExceptPassword:getChildById(widgetError:getId())
        errorWidget:setVisible(not enabled)
        if errorMessage then
            errorWidget:setText(errorMessage)
        else
            errorWidget:setVisible(false)
        end
    end
end

local function updatePasswordRequirements(response)
    if not response or not response.PasswordRequirements then
        return
    end

    local requirements = response.PasswordRequirements
    local requirementsPanel = toolstips.password

    local allRequirementsPassed = true

    if requirementsPanel then
        for requirement, value in pairs(requirements) do
            local reqPanel = requirementsPanel:getChildById(requirement)
            if reqPanel then
                local icon = reqPanel:getChildById('icons')
                if icon then
                    icon:setEnabled(value)
                end
            end
            if not value then
                allRequirementsPassed = false
            end
        end
    end
    setRequirementState(iconsCreateAccount.Password, allRequirementsPassed)
end

local function handleTextChange(widget, requestType, validationFunc)
    local currentTime = g_clock.millis()
    local lastTime = lastRequestTime[widget:getId()] or 0
    local text = widget:getText()
    if #text == 0 then
        return
    end
    local processResponse = function(response, err)
        if err then
            widget:setColor("#EC644B")
            return
        end

        local isValid = (requestType == "email" and not response.errorCode) or
                            (requestType == "character" and response.IsAvailable) or
                            (requestType == "password" and response.PasswordValid)

        widget:setColor(isValid and "#76EE00" or "#EC644B")

        if requestType == "password" then
            updatePasswordRequirements(response)
        elseif requestType == "character" then
            setRequirementState(iconsCreateCharacter.CharacterName, response.IsAvailable, widget, response.errorMessage)
        elseif requestType == "email" then
            setRequirementState(iconsCreateAccount.Email, response.IsValid, widget, response.errorMessage)

        end
    end
    if currentTime - lastTime < REQUEST_COOLDOWN then
        if widget.pendingEvent then
            removeEvent(widget.pendingEvent)
            widget.pendingEvent = nil
        end

        widget.pendingEvent = scheduleEvent(function()
            lastRequestTime[widget:getId()] = g_clock.millis()
            validationFunc(text, processResponse)
        end, REQUEST_COOLDOWN)
    else
        lastRequestTime[widget:getId()] = currentTime
        validationFunc(text, processResponse)
    end
end

-- /*=============================================
-- =                onXXXXChangeEvent            =
-- =============================================*/

local function onFocusChange(focused, reason)
    if #focused:getText() == 0 then
        return
    end
    local focusedId = focused:getId()
    if focusedId == "textEditPassword" then
        toolstips.password:setVisible(reason)
        return
    end

    -- test
    local tooltip = toolstips.allExceptPassword:getChildById(focusedId)
    local shouldHide = false
    if focusedId == "textEditEmail" and iconsCreateAccount.Email:isEnabled() then
        shouldHide = true
    elseif focusedId == "textEditRepeatPassword" and iconsCreateAccount.RepeatPassword:isEnabled() then
        shouldHide = true
    elseif focusedId == "textEditCharacter" and iconsCreateAccount.CheckBox:isEnabled() then
        shouldHide = true
    end
    if shouldHide then
        tooltip:setVisible(false)
    else
        tooltip:setVisible(reason)
    end
end

local function behavioronFocusChange()
    for _, field in pairs(UITextEdit) do
        field.onFocusChange = onFocusChange
    end
end

local function behavioronTextChange()
    UITextEdit.email.onTextChange = function(widget, text)
        widget:setColor("#FFFFFF")
        handleTextChange(widget, "email", checkEmail)
        if #text == 0 then
            setRequirementState(iconsCreateAccount.Email, false, widget, false)
        end
    end

    UITextEdit.password.onTextChange = function(widget, text)
        widget:setColor("#FFFFFF")
        handleTextChange(widget, "password", checkPassword)

        if #text == 0 then
            setRequirementState(iconsCreateAccount.Password, false)

            local reqPanel = toolstips.password
            if reqPanel then
                for _, child in ipairs(reqPanel:getChildren()) do
                    local icon = child:getChildById('icons')
                    if icon then
                        icon:disable()
                    end
                end
            end
        end
        toolstips.password:setVisible(#text ~= 0)
        local repeatPassword = UITextEdit.repeatPassword:getText()
        if #repeatPassword > 0 then
            setRequirementState(iconsCreateAccount.RepeatPassword, repeatPassword == text)
            UITextEdit.repeatPassword:setColor(repeatPassword == text and "#76EE00" or "#EC644B")
        end
    end

    UITextEdit.repeatPassword.onTextChange = function(widget, text)
        local password = UITextEdit.password:getText()
        if #password == 0 then
            widget:setColor("#FFFFFF")
            return
        end
        local passwordRepeat = widget:getText()
        if #passwordRepeat == 0 then
            toolstips.allExceptPassword:getChildById("textEditRepeatPassword"):setVisible(false)
            return
        end
        local matches = text == password
        widget:setColor(matches and "#76EE00" or "#EC644B")
        setRequirementState(iconsCreateAccount.RepeatPassword, matches, widget, "The two passwords do not match!")
    end

    UITextEdit.character.onTextChange = function(widget, text)
        local filteredText = text:gsub("[^a-zA-Z ]", "")
        if filteredText ~= text then
            widget:setText(filteredText)
            return
        end
        widget:setColor("#FFFFFF")
        handleTextChange(widget, "character", checkCharacterName)
        if #filteredText == 0 then
            setRequirementState(iconsCreateCharacter.CharacterName, false, widget, false)
        end
    end
end

local function behavioronCheckChange()
    MainWindowsCreateAccount.createAccount.createYourAccount.panelCheckBox.checkboxPrivacy.onCheckChange =
        function(a, b)
            setRequirementState(a:getParent():getChildById('icons'), b)
        end
end

-- /*=============================================
-- =            onClick - Create Your Account    =
-- =============================================*/

function toggleCreateAccount(bool)
    if bool then
        EnterGame.show()
        destroyCreateAccount()
    else
        EnterGame.hide()
        createWidgetAccount()
    end
end

function onClickStartPlaying()
    local uiElements = {UITextEdit.email, UITextEdit.password, UITextEdit.character, UITextEdit.repeatPassword}
    for _, element in ipairs(uiElements) do
        element:disable()
    end

    globalInfo.email = UITextEdit.email:getText()
    globalInfo.password = UITextEdit.password:getText()
    globalInfo.characterName = UITextEdit.character:getText()
    globalInfo.characterSex = sexModeGroup:getSelectedWidget():getText():lower()
    -- globalInfo.selectedWorld

    createAccountAndCharacter(globalInfo, function(data, err)
        for _, element in ipairs(uiElements) do
            element:enable()
        end
        if err or not data then
            reportRequestWarning("createAccountAndCharacter", err, "fx onClickStartPlaying")
            return
        end
        if data.Success then
            if not CharacterList.isVisible() then
                local account = g_crypt.encrypt(globalInfo.email)
                local password = g_crypt.encrypt(globalInfo.password)
                -- g_settings.set('account', account)
                -- g_settings.set('password', password)
                EnterGame.setAccountName(account)
                EnterGame.setPassword(password)
                EnterGame.doLogin()
                destroyCreateAccount()
            end
        else
            reportRequestWarning("createAccountAndCharacter", data.errorMessage, "fx onClickStartPlaying")
        end
    end)
end

function onClickSuggestName()
    generateCharacterName(function(data, err)
        if err or not data then
            reportRequestWarning("generatecharactername", err, "fx onClickSuggestName")
            return
        end
        UITextEdit.character:setText(data.GeneratedName)
    end)
end

-- /*=============================================
-- =    Panel game world to play on   =
-- =============================================*/

local function findWorldByName(name)
    for _, world in pairs(Worlds) do
        if world.Name:lower() == name:lower() then
            return world
        end
    end
    return nil
end

local function filterWorldsList()
    local selectedRegion = UIComboBox.world:getCurrentOption().text
    local selectedPvpType = UIComboBox.pvp:getCurrentOption().text

    local index = 0
    for _, widget in pairs(UITextList.listAllWorlds:getChildren()) do
        local world = findWorldByName(widget:getId())
        local regionMatch = selectedRegion == "All" or world.Region == selectedRegion
        local pvpMatch = selectedPvpType == "All" or world.PvPType == selectedPvpType

        local visible = regionMatch and pvpMatch
        widget:setVisible(visible)
        if visible then
            index = index + 1
            widget:setBackgroundColor(index % 2 == 0 and "#ffffff12" or "#00000012")
        end
    end
end

local function updateWorldInformation(widget)
    local world = findWorldByName(widget:getId())

    UIlabel.titleMiniPanelWorld:setText(world.Name)
    for key, value in pairs(world) do
        local w = UIlabel.titleMiniPanelWorld:recursiveGetChildById(key)
        if w then
            if key == "CreationDate" then
                w:setText(os.date("%b. %Y", value))
            elseif key == "PremiumOnly" then
                w:setText(tostring(value == 1))
            elseif key == "BattlEyeActivationTimestamp" then
                local description =
                    world.BattlEyeInitiallyActive == 1 and "initially protected" or "protected since " ..
                        os.date("%b.%Y", value)
                w:setText(description)
            else
                w:setText(value)
            end
        end
    end
end

local function initializeWorldsList(worlds)
    local sortedWorlds = {}
    for _, world in pairs(worlds) do
        table.insert(sortedWorlds, world)
    end
    table.sort(sortedWorlds, function(a, b)
        return a.Name < b.Name
    end)

    UITextList.listAllWorlds:destroyChildren()
    Worlds = worlds

    local regions = {
        ["All"] = true
    }
    local pvpTypes = {
        ["All"] = true
    }
    local focusLabel
    for i, world in ipairs(sortedWorlds) do
        local widget = g_ui.createWidget('WorldWidget', UITextList.listAllWorlds)
        widget:setId(world.Name)
        widget:getChildById('details'):setText(world.Name)
        widget:setBackgroundColor(i % 2 == 0 and "#ffffff12" or "#00000012")
        if i == 1 then
            focusLabel = widget
        end
        if world.Name:lower() == globalInfo.selectedWorld:lower() then
            auxWidgets.worldDefault = widget
        end
        regions[world.Region] = true
        pvpTypes[world.PvPType] = true
    end
    if focusLabel then
        scheduleEvent(function()
            UITextList.listAllWorlds:focusChild(focusLabel, KeyboardFocusReason)
            UITextList.listAllWorlds:ensureChildVisible(focusLabel)
        end, 50)
    end
    connect(UITextList.listAllWorlds, {
        onChildFocusChange = function(self, focusedChild)
            if focusedChild then
                updateWorldInformation(focusedChild)
            end
        end
    })
    UIComboBox.world:clearOptions()
    UIComboBox.world:addOption("All")
    for region in pairs(regions) do
        if region ~= "All" then
            UIComboBox.world:addOption(region)
        end
    end
    UIComboBox.pvp:clearOptions()
    UIComboBox.pvp:addOption("All")
    for pvpType in pairs(pvpTypes) do
        if pvpType ~= "All" then
            UIComboBox.pvp:addOption(pvpType)
        end
    end
    UIComboBox.world.onOptionChange = filterWorldsList
    UIComboBox.pvp.onOptionChange = filterWorldsList
end

-- /*=============================================
-- =    OnClick Select a game world to play on   =
-- =============================================*/

function onClickResetGameWorld()
    if auxWidgets.worldDefault then
        UITextList.listAllWorlds:focusChild(auxWidgets.worldDefault, KeyboardFocusReason)
        UITextList.listAllWorlds:ensureChildVisible(auxWidgets.worldDefault)
    end
end

function toggleMainPanels(bool)
    MainWindowsCreateAccount.createAccount:setVisible(not bool)
    MainWindowsCreateAccount.mainPanelSelectAGameWorldToPlayOn:setVisible(bool)
    if bool then
        MainWindowsCreateAccount:setHeight(350)
    else
        MainWindowsCreateAccount:setHeight(390)
    end
end

function onClickOkChangeWorld()
    toggleMainPanels(false)
    globalInfo.selectedWorld = UIlabel.titleMiniPanelWorld:getText()
    UIlabel.RecommendedWorld:setText(globalInfo.selectedWorld)
    UIlabel.RecommendedWorld:setText(string.format("%s (%s)", globalInfo.selectedWorld,
        findWorldByName(globalInfo.selectedWorld).Region))
end

-- /*=============================================
-- =                    onInit                   =
-- =============================================*/

function createWidgetAccount()
    if not MainWindowsCreateAccount then
        getAccountCreationStatus(function(data, err)
            ensableBtnCreateNewAccount()
            if err or not data then
                reportRequestWarning("getaccountcreationstatus", err, "fx createWidgetAccount")
                return
            end
            MainWindowsCreateAccount = g_ui.displayUI('createAccount')
            -- LuaFormatter off
            UIwidgetImagen.AccountData = MainWindowsCreateAccount.imagesBanner.accountdatainvalid
            UIwidgetImagen.AllData = MainWindowsCreateAccount.imagesBanner.banneralldatainvalid
            UIwidgetImagen.CharacterData = MainWindowsCreateAccount.imagesBanner.bannercharacterdatainvalid

            UIlabel.RecommendedWorld = MainWindowsCreateAccount.createAccount.createYourCharacter.panelRecommendedWorld.worldLabel

            sexModeGroup = UIRadioGroup.create()
            sexModeGroup:addWidget(MainWindowsCreateAccount.createAccount.createYourCharacter.panelSex.Male)
            sexModeGroup:addWidget(MainWindowsCreateAccount.createAccount.createYourCharacter.panelSex.Female)
            -- sexModeGroup.onSelectionChange = sexModeChange
            sexModeGroup:selectWidget(MainWindowsCreateAccount.createAccount.createYourCharacter.panelSex.Male)

            -- world
            UIComboBox.world = MainWindowsCreateAccount.mainPanelSelectAGameWorldToPlayOn.panelSelectAGameWorldToPlayOn.panelSelectworldAndPvp.comboBoxWorld
            UIComboBox.pvp = MainWindowsCreateAccount.mainPanelSelectAGameWorldToPlayOn.panelSelectAGameWorldToPlayOn.panelSelectworldAndPvp.comboBoxPvp
            UITextList.listAllWorlds = MainWindowsCreateAccount.mainPanelSelectAGameWorldToPlayOn.panelSelectAGameWorldToPlayOn.textListAllWorlds
            UIlabel.titleMiniPanelWorld = MainWindowsCreateAccount.mainPanelSelectAGameWorldToPlayOn.panelSelectAGameWorldToPlayOn.worldInfo
    
            -- icons Account
            iconsCreateAccount.Password = MainWindowsCreateAccount.createAccount.createYourAccount.panelPassword.icons
            iconsCreateAccount.Email = MainWindowsCreateAccount.createAccount.createYourAccount.panelEmail.icons
            iconsCreateAccount.RepeatPassword = MainWindowsCreateAccount.createAccount.createYourAccount.panelRepeatPassword.icons
            iconsCreateAccount.CheckBox = MainWindowsCreateAccount.createAccount.createYourAccount.panelCheckBox.icons
            -- icons Characters
            iconsCreateCharacter.Sex = MainWindowsCreateAccount.createAccount.createYourCharacter.panelSex.icons
            iconsCreateCharacter.RecommendedWorld = MainWindowsCreateAccount.createAccount.createYourCharacter.panelRecommendedWorld.icons
            iconsCreateCharacter.CharacterName = MainWindowsCreateAccount.createAccount.createYourCharacter.panelCharacterName.icons

            -- Tooltips Password
            toolstips.allExceptPassword = MainWindowsCreateAccount.createAccount.testToolstips
            toolstips.password = MainWindowsCreateAccount.createAccount.passwordRequirements

            -- Input TextEdit
            UITextEdit.email = MainWindowsCreateAccount.createAccount.test.textEditEmail
            UITextEdit.password = MainWindowsCreateAccount.createAccount.test.textEditPassword
            UITextEdit.repeatPassword = MainWindowsCreateAccount.createAccount.test.textEditRepeatPassword
            UITextEdit.character = MainWindowsCreateAccount.createAccount.test.textEditCharacter
-- LuaFormatter on

            globalInfo.selectedWorld = data.RecommendedWorld

            initializeWorldsList(data.Worlds)
            UIlabel.RecommendedWorld:setText(string.format("%s (%s)", data.RecommendedWorld,
                findWorldByName(data.RecommendedWorld).Region))

            behavioronTextChange()
            behavioronFocusChange()
            behavioronCheckChange()
        end)
    else
        MainWindowsCreateAccount:show()
        ensableBtnCreateNewAccount()
    end
end

-- /*=============================================
-- =                    onTerminate              =
-- =============================================*/

function destroyCreateAccount()
    if MainWindowsCreateAccount then
        for _, widget in pairs(UIwidgetImagen or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        UIwidgetImagen = {}
        for _, widget in pairs(auxWidgets or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        auxWidgets = {}

        if sexModeGroup then
            sexModeGroup:destroy()
            sexModeGroup = nil
        end

        for _, widget in pairs(UIComboBox or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        UIComboBox = {}

        for _, widget in pairs(UITextEdit or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        UITextEdit = {}

        for _, widget in pairs(iconsCreateAccount or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        iconsCreateAccount = {}

        for _, widget in pairs(iconsCreateCharacter or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        iconsCreateCharacter = {}

        if UITextList.listAllWorlds then
            disconnect(UITextList.listAllWorlds, {
                onChildFocusChange = function(self, focusedChild)
                    if focusedChild == nil then
                        return
                    end
                    updateWorldInformation(focusedChild)
                end
            })
            UITextList.listAllWorlds:destroyChildren()
            UITextList.listAllWorlds:destroy()
            UITextList.listAllWorlds = nil
        end

        for _, widget in pairs(UIlabel or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
                widget = nil
            end
        end
        UIlabel = {}

        for _, widget in pairs(toolstips or {}) do
            if widget and not widget:isDestroyed() then
                widget:destroy()
            end
        end
        toolstips = {}

        if not MainWindowsCreateAccount:isDestroyed() then
            MainWindowsCreateAccount:destroy()
            MainWindowsCreateAccount = nil
        end
        Worlds = {}
        lastRequestTime = {}
    end
end
