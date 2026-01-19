-- LuaFormatter off
BUY = 1
SELL = 2

KeywordButtonIcon = {
  KEYWORDBUTTONICON_GENERALTRADE   = 0,
  KEYWORDBUTTONICON_POTIONTRADE    = 1,
  KEYWORDBUTTONICON_EQUIPMENTTRADE = 2,
  KEYWORDBUTTONICON_SAIL           = 3,
  KEYWORDBUTTONICON_DEPOSITALL     = 4,
  KEYWORDBUTTONICON_WITHDRAW       = 5,
  KEYWORDBUTTONICON_BALANCE        = 6,
  KEYWORDBUTTONICON_YES            = 7,
  KEYWORDBUTTONICON_NO             = 8,
  KEYWORDBUTTONICON_BYE            = 9,
}

IconSpriteIndex = {
  [KeywordButtonIcon.KEYWORDBUTTONICON_GENERALTRADE]   = 1,
  [KeywordButtonIcon.KEYWORDBUTTONICON_POTIONTRADE]    = 2,
  [KeywordButtonIcon.KEYWORDBUTTONICON_EQUIPMENTTRADE] = 3,
  [KeywordButtonIcon.KEYWORDBUTTONICON_SAIL]           = 0,
  [KeywordButtonIcon.KEYWORDBUTTONICON_DEPOSITALL]     = 5,
  [KeywordButtonIcon.KEYWORDBUTTONICON_WITHDRAW]       = 6,
  [KeywordButtonIcon.KEYWORDBUTTONICON_BALANCE]        = 4,
  [KeywordButtonIcon.KEYWORDBUTTONICON_YES]            = 7,
  [KeywordButtonIcon.KEYWORDBUTTONICON_NO]             = 8,
  [KeywordButtonIcon.KEYWORDBUTTONICON_BYE]            = 9,
}
-- LuaFormatter on

function controllerNpcTrader:getIconClip(id)
    local index = IconSpriteIndex[id] or 0
    local x = index * 32
    return x .. " 0 32 32"
end
