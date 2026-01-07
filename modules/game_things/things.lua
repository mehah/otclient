ThingsLoaderController = Controller:new()

local loaded = false

function isLoaded()
    return loaded
end

local function tryLoadDatWithFallbacks(datPath)
    if g_things.loadDat(datPath) then
        return true
    end

    local featureFlags = {
        GameSpritesU32,
        GameEnhancedAnimations,
        GameIdleAnimations
    }

    local combinations = {
        { 1 }, { 2 }, { 3 },
        { 1, 2 }, { 1, 3 }, { 2, 3 },
        { 1, 2, 3 }
    }

    for _, combo in ipairs(combinations) do
        for _, idx in ipairs(combo) do
            g_game.enableFeature(featureFlags[idx])
        end

        if g_things.loadDat(datPath) then
            return true
        end
    end

    return false
end

local function findFileByExtension(path, ext)
	-- find Tibia.ext
	local fileName = "Tibia" .. ext
	local resolvedPath = resolvepath(path .. fileName)
	if g_resources.fileExists(resolvedPath) then
		return resolvedPath
	end

	-- find any filename.ext
	resolvedPath = resolvepath(path)
    local files = g_resources.listDirectoryFiles(resolvedPath)
    for _, file in ipairs(files) do
		-- match .otfi extension
		if file:lower():sub(ext:len()) == ext then
			resolvedPath = resolvepath(path .. "/" .. file)
            return resolvedPath
        end
    end

	-- no file found
end

-- helper to get boolean from parsed otfi
local function toboolean(v)
    if v == nil then
        return false
    end

    if type(v) == "boolean" then
        return v
    end

    if type(v) ~= "string" then
        return false
    end

    v = string.lower(v)
    return v == "true" or v == "1" or v == "yes" or v == "on" or v == "enabled"
end

local function setFeature(feature, value)
	if value == nil then
		-- use version default if not defined in otfi
		return
	elseif toboolean(value) then
		-- evaluated to true
		g_game.enableFeature(feature)
	else
		-- evaluated to false
		g_game.disableFeature(feature)
	end
end

local function addError(errorList, message, resourceId)
	if resourceId > 0 then
		errorList[#errorList + 1] = string.format("Resource %d: %s", resourceId, message)
	else
		errorList[#errorList + 1] = message
	end
end

local function loadResource(path, version, resourceId, errorList)
	-- file loading fallback order:
	-- 1. catalog-content.json - if found: load assets
	-- 2. Tibia.otfi - if found: load dat specified in it
	-- 3. any otfi - if found: load dat specified in it
	-- 4. Tibia.dat
	-- 5. any dat

	-- assets
	if g_resources.fileExists(resolvepath(path .. 'catalog-content.json')) then
		g_logger.info(string.format("Loading resource %d (assets) ...", resourceId))
		if not g_things.loadAppearances(resolvepath(path), resourceId) then
            addError(errorList, "Couldn't load assets", resourceId)
        end
        if not g_things.loadStaticData(path) then
            addError(errorList, "Couldn't load staticdata", resourceId)
        end

		return
	end

	g_logger.info(string.format("Loading resource %d (spr/dat) from %s ...", resourceId, path))

	-- otfi-defined spr/dat
	local otfiPath = findFileByExtension(path, ".otfi")
	if otfiPath then
		-- read config from otfi
		local otfiSettings = g_configs.create(otfiPath)
		if not otfiSettings then
			addError(errorList, "Failed to load OTFI", resourceId)
			return
		end

		local datSpr = otfiSettings:getNode("DatSpr")
		if not datSpr then
			addError(errorList, "Invalid OTFI structure", resourceId)
			return
		end

		-- nodes priority:
		-- 1. otfi assets-name
		-- 2. otfi "-file" nodes
		-- 3. (if not defined by otfi) Tibia .spr/.dat
		local sprName = "Tibia.spr"
		local datName = "Tibia.dat"

		local assetsName = datSpr["assets-name"]
		if assetsName then
			sprName = assetsName .. ".spr"
			datName = assetsName .. ".dat"
		else
			sprName = datSpr["sprites-file"] or sprName
			datName = datSpr["metadata-file"] or datName
		end

		-- set features according to otfi
		setFeature(GameSpritesU32, datSpr["extended"])
		setFeature(GameSpritesAlphaChannel, datSpr["transparency"])
		setFeature(GameIdleAnimations, datSpr["frame-groups"])
		setFeature(GameEnhancedAnimations,datSpr["frame-durations"])

		-- check if otfi-specified dat file exists
		local datPath = resolvepath(path .. datName)
		if not g_resources.fileExists(datPath) then
			addError(errorList, string.format("Unable to load %s: file not found", datName), resourceId)
			return
		end

		-- try to load dat file
		if not g_things.loadDat(datPath, resourceId) then
			addError(errorList, string.format("Failed to read %s: file structure does not match the defined version or OTFI specification", datName), resourceId)
			return
		end
	else
		-- normal spr/dat
		local datPath = findFileByExtension(path, ".dat")
		if not datPath then
			addError(errorList, "DAT file not found", resourceId)
			return
		end

		local datResult = tryLoadDatWithFallbacks(datPath, resourceId)
		if not datResult then
			addError(errorList, "Failed to read dat file: file structure does not match the defined version", resourceId)
		end
	end
end

local function loadPackInfo(packPath, errorList)
	g_logger.info("Found packinfo.xml")
	local packInfo = g_things.decodePackInfo(resolvepath(packPath))
	if #packInfo == 0 then
		addError(errorList, "Failed to decode packinfo.xml", 0)
		return
	end

	for _, resInfo in pairs(packInfo) do
		loadResource(string.format("%s%s/", packPath, resInfo.dir), resInfo.version, resInfo.id, errorList)

		if #errorList > 0 then
			break
		end
	end
end

local function load(version)
	-- prevent calling again after a failed attempt
	if version == 0 then
		return
	end

    local errorList = {}
	local path = string.format('/data/things/%s/', version)

	g_logger.info("Loading game assets from " .. path)

	local packPath = resolvepath(path .. 'packinfo.xml')
	if g_resources.fileExists(packPath) then
		loadPackInfo(path, errorList)
	else
		loadResource(path, version, 0, errorList)
	end

    loaded = #errorList == 0
    if loaded then
        -- loading client files was successful, try to load sounds now
        -- sound files are optional, this means that failing to load them
        -- will not block logging into game
		if version > 1300 then
			g_sounds.loadClientFiles(resolvepath(string.format('/sounds/%d/', version)))
		end

		g_logger.info("Assets loading complete.")
        return
    end

	local errors = table.concat(errorList, "\n")
    local messageBox = displayErrorBox(tr('Error'), errors)
    addEvent(function()
        messageBox:raise()
        messageBox:focus()
    end)

    g_game.setClientVersion(0)
    g_game.setProtocolVersion(0)
	g_logger.error(errors)
end

function ThingsLoaderController:onInit()
    self:registerEvents(g_game, {
        onClientVersionChange = load
    })
end
