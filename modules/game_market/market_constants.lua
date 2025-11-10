-- Market Constants
-- This file contains constant definitions used by the market system

-- Market sell offer status strings
-- Maps status codes to display strings for sell history
MarketSellStatus = {
    [0] = "Active",
    [1] = "Cancelled",
    [2] = "Expired",
    [3] = "Accepted"
}

-- Market buy offer status strings
-- Maps status codes to display strings for buy history
MarketBuyStatus = {
    [0] = "Active",
    [1] = "Cancelled",
    [2] = "Expired",
    [3] = "Accepted"
}

-- Market detail field names
-- Array of label names for item details display
-- Corresponds to MarketItemDescription enum values
MarketDetailNames = {
    "Armor: ",              -- 1: Armor
    "Attack: ",             -- 2: Attack
    "Container: ",          -- 3: Container
    "Defense: ",            -- 4: Defense
    "Description: ",        -- 5: General/Description
    "Use Time: ",           -- 6: DecayTime
    "Combat: ",             -- 7: Combat
    "Min Level: ",          -- 8: MinLevel
    "Min Magic Level: ",    -- 9: MinMagicLevel
    "Vocation: ",           -- 10: Vocation
    "Rune: ",               -- 11: Rune
    "Ability: ",            -- 12: Ability
    "Charges: ",            -- 13: Charges
    "Weapon Type: ",        -- 14: WeaponName
    "Weight: ",             -- 15: Weight
    "Augment: ",            -- 16: Augment
    "Imbuing Slots: ",      -- 17: ImbuingSlots
    "Magic Shield: ",       -- 18: MagicShield
    "Cleave: ",             -- 19: Cleave
    "Reflection: ",         -- 20: Reflection
    "Perfect Show: ",       -- 21: Perfect
    "Upgrade Classification: ", -- 22: UpgradeClassification
    "Tier: "                -- 23: CurrentTier
}

-- Market category virtual IDs
-- These are virtual categories that don't exist in the base MarketCategory enum
-- WeaponsAll: Virtual category for all weapon types
-- FistWeapons: Virtual category for fist weapons
MarketCategoryWeaponsAll = 100
MarketCategoryFistWeapons = 101
