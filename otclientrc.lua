-- this file is loaded after all modules are loaded and initialized
-- you can place any custom user code here

print 'Startup done :]'

-- OTClient Map Generator
-- Based on https://github.com/gesior/otclient_mapgen

local clientVersion = 0
local otbPath = ''
local mapPath = ''

local isGenerating = false
local threadsToRun = 3
local areasAdded = 0

local startTime = os.time()
local lastPrintStatus = os.time()

local mapParts = {}
local mapPartsToGenerate = {}
local mapPartsCount = 0
local mapPartsCurrentId = 0
local mapImagesGenerated = 0

-- Example: prepareClient(1076, '/things/1076/items.otb', '/map.otbm', 8, 5)
function prepareClient(cv, op, mp, ttr, mpc)
    clientVersion = cv
    otbPath = op
    mapPath = mp
    threadsToRun = ttr or 3
    mapPartsCount = mpc
    g_logger.info("Loading client data... (it will freeze client for a few seconds)")
    g_dispatcher.scheduleEvent(prepareClient_action, 1000)
end

function prepareClient_action()


    g_map.initializeMapGenerator(threadsToRun);
    g_resources.makeDir('house');
    g_resources.makeDir('exported_images');
    g_resources.makeDir('exported_images/map');
    
    g_logger.info("Loading client Tibia.dat and Tibia.spr...")
    g_game.setClientVersion(clientVersion)
    g_logger.info("Loading server items.otb...")
    if clientVersion >= 1281 and not g_game.getFeature(GameLoadSprInsteadProtobuf) then
        --g_things.loadAppearances(otbPath)
        print("no compatibility")
        return
    else
        g_things.loadOtb(otbPath)

    end
    g_logger.info("Loading server map information...")
    g_map.setMaxXToLoad(-1) -- do not load tiles, just save map min/max position
    g_map.loadOtbm(mapPath)
    g_logger.info("Loaded map positions. Minimum [X: " .. g_map.getMinPosition().x .. ", Y: " .. g_map.getMinPosition().y .. ", Z: " .. g_map.getMinPosition().z .. "] Maximum [X: " .. g_map.getMaxPosition().x .. ", Y: " .. g_map.getMaxPosition().y .. ", Z: " .. g_map.getMaxPosition().z .. "]")
    g_logger.info("Loaded client data.")

    local totalTilesCount = 0
    local mapTilesPerX = g_map.getMapTilesPerX()
    for x, c in pairs(mapTilesPerX) do
        totalTilesCount = totalTilesCount + c
    end
    
    mapParts = {}
    local targetTilesCount = totalTilesCount / mapPartsCount
    local currentTilesCount = 0
    local currentPart = {["minXrender"] = 0}
    for i = 0, 70000 do
        if mapTilesPerX[i] then
            currentTilesCount = currentTilesCount + mapTilesPerX[i]
            currentPart.maxXrender = i
            if #mapParts < mapPartsCount and currentTilesCount > targetTilesCount then
                table.insert(mapParts, currentPart)
                currentPart = {["minXrender"] = i}
                currentTilesCount = 0
            end
        end
    end
    currentPart.maxXrender = 70000
    table.insert(mapParts, currentPart)
    
    g_logger.info('----- MAP PARTS LIST -----')
    for i, currentPart in pairs(mapParts) do
        -- render +/- 8 tiles to avoid problem with calculations precision
        currentPart.minXrender = math.max(0, math.floor((currentPart.minXrender - 8) / 8) * 8)
        currentPart.maxXrender = math.floor((currentPart.maxXrender + 8) / 8) * 8
        
        -- load +/- 16 tiles to be sure that all items on floors below will load
        currentPart.minXload = math.max(0, math.floor((currentPart.minXrender - 16) / 8) * 8)
        currentPart.maxXload = math.floor((currentPart.maxXrender + 16) / 8) * 8
        
        print("PART " .. i .. " FROM X: " .. currentPart.minXrender .. ", TO X: " .. currentPart.maxXrender)
    end
    g_logger.info('----- MAP PARTS LIST -----')
    
    g_logger.info('')
    g_logger.info("----- STEP 2 -----")
    g_logger.info("Now just type (lower levels shadow 30%):");
    g_logger.info("ALL PARTS OF MAP:")
    g_logger.info("generateMap('all', 30)");
    g_logger.info("ONLY PARTS 2 AND 3 OF MAP:")
    g_logger.info("generateMap({2, 3}, 30)");
    g_logger.info("")
end

function generateManager()
    -- Add more areas to the generator queue
    if (g_map.getGeneratedAreasCount() / 1000) + 1 > areasAdded then
        g_map.addAreasToGenerator(areasAdded * 1000, areasAdded * 1000 + 999)
        areasAdded = areasAdded + 1
    end

    if lastPrintStatus ~= os.time() then
        -- Print status
        print(math.floor(g_map.getGeneratedAreasCount() / g_map.getAreasCount() * 100) .. '%, ' .. format_int(g_map.getGeneratedAreasCount()) .. ' of ' .. format_int(g_map.getAreasCount()) .. ' images generated - PART ' .. mapPartsCurrentId .. ' OF ' .. #mapPartsToGenerate)

        if g_map.getAreasCount() == g_map.getGeneratedAreasCount() then
            mapImagesGenerated = mapImagesGenerated + g_map.getGeneratedAreasCount()
            if mapPartsCurrentId ~= #mapPartsToGenerate then
                mapPartsCurrentId = mapPartsCurrentId + 1
                startMapPartGenerator()
                g_dispatcher.scheduleEvent(generateManager, 100)
                return
            end
            isGenerating = false
            print('Map images generation finished.')
            print(mapImagesGenerated .. ' images generated in ' .. (os.time() - startTime) .. ' seconds.')
            return
        end

        lastPrintStatus = os.time()
    end

    g_dispatcher.scheduleEvent(generateManager, 100)
end

function startMapPartGenerator()
    local currentMapPart = mapPartsToGenerate[mapPartsCurrentId]
    
    g_logger.info("Set min X to load: " .. currentMapPart.minXload)
    g_logger.info("Set max X to load: " .. currentMapPart.maxXload)
    g_logger.info("Set min X to render: " .. currentMapPart.minXrender)
    g_logger.info("Set max X to render: " .. currentMapPart.maxXrender)
    g_map.setMinXToLoad(currentMapPart.minXload)
    g_map.setMaxXToLoad(currentMapPart.maxXload)
    g_map.setMinXToRender(currentMapPart.minXrender)
    g_map.setMaxXToRender(currentMapPart.maxXrender)
    
    g_logger.info("Loading server map part...")
    g_map.loadOtbm(mapPath)
    
    areasAdded = 0
    g_map.setGeneratedAreasCount(0)

    print('Starting generator (PART ' .. mapPartsCurrentId .. ' OF ' .. #mapPartsToGenerate .. '). ' .. format_int(g_map.getAreasCount()) .. ' images to generate. ' .. threadsToRun .. ' threads will generate it now. Please wait.')
end

function generateMap(mapPartsToGenerateIds, shadowPercent)
    if isGenerating then
        print('Generating script is already running. Cannot start another generation')
        return
    end
    
    isGenerating = true

    if type(mapPartsToGenerateIds) == "string" then
        mapPartsToGenerateIds = {}
        for i = 1, mapPartsCount do
            table.insert(mapPartsToGenerateIds, i)
        end
    end
    
--generateMap({1}, nil)
    g_map.setShadowPercent(shadowPercent)
    mapImagesGenerated = 0
    
    -- split map into parts
    mapPartsCurrentId = 1
    mapPartsToGenerate = {}
    
    for _, i in pairs(mapPartsToGenerateIds) do
        table.insert(mapPartsToGenerate, mapParts[i])
    end
    
    startTime = os.time()
    
    startMapPartGenerator()
    
    g_dispatcher.scheduleEvent(generateManager, 1000)
end

function format_int(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

-- Example usage instructions
g_logger.info('OTClient Map Generator version: 6.1')
g_logger.info("To generate map images, execute:")
g_logger.info("1. prepareClient(1098, '/things/1098/items.otb', '/things/1098/forgotten.otbm', 8, 5)")
g_logger.info("   - client version, OTB path, MAP path, threads, parts")
g_logger.info("2. generateMap('all', 30)")
g_logger.info("   - 'all' or {1,2,3} for parts, shadow percent")

