-- Market Helper Functions
-- This file contains utility functions used by the market system

-- ============================================================================
-- Game API Wrapper Functions
-- These provide compatibility between different API naming conventions
-- ============================================================================

-- Wrapper for g_game market action
-- Maps sendMarketAction to appropriate C++ function based on action type
-- @param action: Action type (1=myOffers, 2=myHistory, 3=browseItem)
-- @param itemId: Item ID for browse action (optional)
-- @param tier: Item tier for browse action (optional)
function sendMarketAction(action, itemId, tier)
    print("========================================")
    print("=== sendMarketAction CALLED ===")
    print("  action:", action, "itemId:", itemId, "tier:", tier)
    print("========================================")
    
    if action == 3 and itemId then
        -- Browse item (MARKETREQUEST_ITEM_BROWSE = 3)
        print("  Calling g_game.browseMarket(3,", itemId, ",", tier or 0, ")")
        g_game.browseMarket(3, itemId, tier or 0)
    elseif action == 2 then
        -- Request my offers (MARKETREQUEST_OWN_OFFERS = 2)
        print("  Calling g_game.browseMarket(2, 0, 0)")
        g_game.browseMarket(2, 0, 0)
    elseif action == 1 then
        -- Request my history (MARKETREQUEST_OWN_HISTORY = 1)
        print("  Calling g_game.browseMarket(1, 0, 0)")
        g_game.browseMarket(1, 0, 0)
    end
end

-- Wrapper for leaving market
function sendMarketLeave()
    g_game.leaveMarket()
end

-- Wrapper for accepting market offer
-- @param timestamp: Offer timestamp
-- @param counter: Offer counter
-- @param amount: Amount to accept
function sendMarketAcceptOffer(timestamp, counter, amount)
    g_game.acceptMarketOffer(timestamp, counter, amount)
end

-- Wrapper for creating market offer
-- @param offerType: 0=buy, 1=sell
-- @param itemId: Item ID
-- @param tier: Item tier
-- @param amount: Amount to offer
-- @param price: Price per piece
-- @param anonymous: Anonymous offer (0 or 1)
function sendMarketCreateOffer(offerType, itemId, tier, amount, price, anonymous)
    g_game.createMarketOffer(offerType, itemId, tier, amount, price, anonymous and 1 or 0)
end

-- Wrapper for canceling market offer
-- @param timestamp: Offer timestamp
-- @param counter: Offer counter
function sendMarketCancelOffer(timestamp, counter)
    g_game.cancelMarketOffer(timestamp, counter)
end

-- Get transferable Tibia coins from player's resources
-- @return: Number of transferable coins
function getTransferableTibiaCoins()
    local player = g_game.getLocalPlayer()
    if not player then
        return 0
    end
    -- Use constant value 91 for COIN_TRANSFERRABLE from ResourceTypes
    return player:getResourceBalance(91) or 0
end

-- ============================================================================
-- Formatting Helper Functions
-- ============================================================================

-- Format gold amounts with comma separation and optional gold coin display
-- @param amount: Number to format
-- @param showSign: Boolean to show +/- sign for profit/loss (optional)
-- @return: Formatted string like "1,234 gold" or "+1,234 gold"
function convertGold(amount, showSign)
    if not amount then
        return "0"
    end
    
    local sign = ""
    if showSign then
        if amount > 0 then
            sign = "+"
        elseif amount < 0 then
            sign = "-"
            amount = math.abs(amount)
        end
    end
    
    return sign .. comma_value(tostring(amount))
end

-- Format large gold amounts with K/M/B suffixes (e.g., "1.5K", "2.3M")
-- @param amount: Number to format
-- @return: Formatted string with suffix
function convertLongGold(amount)
    if not amount then
        return "0"
    end
    
    amount = tonumber(amount)
    if not amount then
        return "0"
    end
    
    -- Billions
    if amount >= 1000000000 then
        return string.format("%.1fB", amount / 1000000000)
    -- Millions
    elseif amount >= 1000000 then
        return string.format("%.1fM", amount / 1000000)
    -- Thousands
    elseif amount >= 1000 then
        return string.format("%.1fK", amount / 1000)
    else
        return tostring(amount)
    end
end

-- Get total money from player's bank and inventory
-- Uses ResourceTypes.BANK_BALANCE and ResourceTypes.GOLD_EQUIPPED
-- @return: Total gold amount
function getTotalMoney()
    local player = g_game.getLocalPlayer()
    if not player then
        return 0
    end
    
    -- Try using getTotalMoney method if available (C++ implementation)
    if player.getTotalMoney then
        return player:getTotalMoney()
    end
    
    -- Fallback: Use resource balance
    -- 0 = BANK_BALANCE, 1 = GOLD_EQUIPPED from ResourceTypes
    local bankBalance = player:getResourceBalance(0) or 0
    local goldEquipped = player:getResourceBalance(1) or 0
    
    return bankBalance + goldEquipped
end

-- Shorten text to specified character limit with ellipsis
-- @param text: String to shorten
-- @param chars_limit: Maximum character count (default: 20)
-- @return: Shortened string with "..." if truncated
function short_text(text, chars_limit)
    if not text then
        return ""
    end
    
    chars_limit = chars_limit or 20
    
    if string.len(text) <= chars_limit then
        return text
    end
    
    return string.sub(text, 1, chars_limit - 3) .. "..."
end

-- Check if search text matches target text (case-insensitive)
-- @param text: Text to search in
-- @param search: Search query
-- @return: Boolean indicating match
function matchText(text, search)
    if not text or not search then
        return false
    end
    
    return text:lower():find(search:lower(), 1, true) ~= nil
end

-- Set colored text within a text string or append to a table
-- Used for highlighting specific parts of text or building colored tooltips
-- @param textStringOrTable: String to modify or table to append to
-- @param text: Text to add or find and color
-- @param color: Color code (e.g., "#ff0000")
-- @return: Formatted text with color tags (if string) or nil (if table - modifies in place)
function setStringColor(textStringOrTable, text, color)
    if not textStringOrTable then
        return ""
    end
    
    -- If it's a table, append colored text to it
    if type(textStringOrTable) == "table" then
        table.insert(textStringOrTable, "{" .. text .. ", " .. color .. "}")
        return
    end
    
    -- If it's a string, find and color the text
    if not text or not color then
        return textStringOrTable
    end
    
    local startPos, endPos = textStringOrTable:lower():find(text:lower(), 1, true)
    
    if startPos then
        local before = textStringOrTable:sub(1, startPos - 1)
        local match = textStringOrTable:sub(startPos, endPos)
        local after = textStringOrTable:sub(endPos + 1)
        
        return before .. "{" .. color .. "," .. match .. "}" .. after
    end
    
    return textStringOrTable
end

-- Get coin step value based on current amount for increment/decrement buttons
-- Returns appropriate step size: 1, 10, 100, 1000, etc.
-- @param currentAmount: Current amount value
-- @return: Step size to use
function getCoinStepValue(currentAmount)
    if not currentAmount or currentAmount < 1 then
        return 1
    end
    
    currentAmount = tonumber(currentAmount)
    
    if currentAmount >= 10000000 then
        return 1000000  -- 1M step
    elseif currentAmount >= 1000000 then
        return 100000   -- 100K step
    elseif currentAmount >= 100000 then
        return 10000    -- 10K step
    elseif currentAmount >= 10000 then
        return 1000     -- 1K step
    elseif currentAmount >= 1000 then
        return 100      -- 100 step
    elseif currentAmount >= 100 then
        return 10       -- 10 step
    else
        return 1        -- 1 step
    end
end

-- Translate wheel vocation ID to readable string
-- Maps vocation IDs to names
-- @param vocationId: Numeric vocation ID
-- @return: Vocation name string
function translateWheelVocation(vocationId)
    if not vocationId then
        return "None"
    end
    
    local vocationNames = {
        [0] = "None",
        [1] = "Knight",
        [2] = "Paladin",
        [3] = "Sorcerer",
        [4] = "Druid",
        [5] = "Monk",
        [11] = "Elite Knight",
        [12] = "Royal Paladin",
        [13] = "Master Sorcerer",
        [14] = "Elder Druid",
        [15] = "Exalted Monk"
    }
    
    return vocationNames[vocationId] or "Unknown"
end
