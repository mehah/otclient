locale = {
  name = "en",
  charset = "cp1252",
  languageName = "English",

  formatNumbers = true,
  decimalSeperator = '.',
  thousandsSeperator = ',',

  translation = {}
}
modules.client_locales.installLocale(locale)

-- locale definitions
local locale = Locale("English", "en")
locale:authors("OTClient contributors")
locale:charset("cp1252")
locale:formatNumbers(true)
locale:decimalSeperator('.')
locale:thousandsSeperator(',')

---- translations ----

-- case convention: PascalCase
-- recommended naming order:
-- Module -> Element -> Child -> Action

-- example:
-- module: ItemSelector
-- element: Title
-- child: -
-- action: RemoveConfig
-- full string: ItemSelectorTitleRemoveConfig

-- example2:
-- module: Minimap
-- element: Window
-- child: Title
-- action: SetMark
-- full string: MinimapWindowTitleSetMark

-- UI: common buttons
locale:translate("UIButtonOk", "OK")
locale:translate("UIButtonCancel", "Cancel")
locale:translate("UIButtonYes", "Yes")
locale:translate("UIButtonNo", "No")
locale:translate("UIButtonOn", "ON")
locale:translate("UIButtonOff", "OFF")
locale:translate("UIButtonClose", "Close")
locale:translate("UIButtonHelp", "Help")
locale:translate("UIButtonSettings", "Settings")
locale:translate("UIButtonEdit", "Edit")
locale:translate("UIButtonRemove", "Remove")
locale:translate("UIButtonClear", "Clear")

-- UI: common form fields
locale:translate("FormFieldDescription", "Description")
locale:translate("FormFieldPosition", "Position")

-- UI: window titles misc
locale:translate("WindowTitleTextEdit", "Edit text")

-- UI: possibly unused
locale:translate("ButtonsWindowTitle", "Buttons")

-- item selector
locale:translate("ItemSelectorCountSubtype", "Count / SubType")
locale:translate("ItemSelectorItemID", "Item ID")
locale:translate("ItemSelectorWindowTitle", "Select Item")

-- minimap
locale:translate("MinimapWindowTitleSetMark", "Create Map Mark")
locale:translate("MinimapButtonCenter", "Center")

-- bot: main window
locale:translate("BotMainWindowTitle", "Config editor & manager")
locale:translate(
    "BotMainWindowText",
    "Config Manager\nYou can use config manager to share configs between different machines, especially smartphones. After you configure your config, you can upload it, then you'll get unique hash code which you can use on diffent machinge (for eg. mobile phone) to download it."
)
locale:translate("BotMainWindowConfigUploadLabel", "Upload config")
locale:translate("BotMainWindowConfigUploadButton", "Upload config")
locale:translate("BotMainWindowConfigUploadSelector", "Select config to upload")
locale:translate("BotMainWindowConfigDownloadLabel", "Download config")
locale:translate("BotMainWindowConfigDownloadButton", "Download config")
locale:translate("BotMainWindowConfigDownloadHashField", "Enter config hash code")
locale:translate("BotMainWindowInfoConfig", "Bot configs are stored in")
locale:translate("BotMainWindowOpenBotFolder", "Click here to open bot directory")
locale:translate(
    "BotMainWindowInfoDirectory",
    "Every directory in bot directory is treated as different config.\nTo create new config just create new directory."
)
locale:translate(
    "BotMainWindowInfoLoadingOrder",
    "Inside config directory put .lua and .otui files.\nEvery file will be loaded and executed in alphabetical order, .otui first and then .lua."
)
locale:translate(
    "BotMainWindowInfoReload",
    "To reload configs just press On and Off in bot window.\nTo learn more about bot click Tutorials button."
)
locale:translate("BotMainWindowDocumentation", "Documentation")
locale:translate("BotMainWindowTutorials", "Tutorials")
locale:translate("BotMainWindowScripts", "Scripts")
locale:translate("BotMainWindowForum", "Forum")
locale:translate("BotMainWindowDiscord", "Discord")

-- bot: config
locale:translate("BotConfigUploadPendingTitle", "Uploading config")
locale:translate("BotConfigUploadPendingText", "Uploading config %1. Please wait.")
locale:translate("BotConfigUploadFailTitle", "Config upload failed")
locale:translate("BotConfigUploadFailText", "Error while upload config %1:\n%2")
locale:translate("BotConfigUploadFailSize", "Config %1 is too big, maximum size is 1024KB. Now it has %2 KB.")
locale:translate("BotConfigUploadFailCompression", "Config %1 is invalid (can't be compressed)")
locale:translate("BotConfigUploadSuccessTitle", "Succesful config upload")
locale:translate("BotConfigUploadSuccessText", "Config %1 has been uploaded.\n%2")


locale:translate("BotConfigDownloadTitle", "Download Config")
locale:translate("BotConfigDownloadText", "Downloading config with hash %1. Please wait.")
locale:translate("BotConfigDownloadErrorTitle", "Config download error")
locale:translate("BotConfigDownloadErrorHash", "Enter correct config hash")
locale:translate("BotConfigDownloadErrorFailed", "Config with hash %1 cannot be downloaded")

-- bot: common strings
locale:translate("BotUnnamedConfig", "Unnamed Config")
locale:translate("BotRemoveConfig", "Remove Config")

-- bot: waypoints editor
locale:translate("WaypointsEditorTitle", "Waypoints editor")
locale:translate(
    "WaypointsEditorMessageRemoveConfig",
    "Do you want to remove current waypoints config?"
)
locale:translate("WaypointsEditorTitleAddFunction", "Add function")
locale:translate("WaypointsEditorErrorInvalidGoto", "Waypoints: invalid use of goto function")
locale:translate("WaypointsEditorErrorInvalidUse", "Waypoints: invalid use of use function")
locale:translate("WaypointsEditorErrorInvalidUseWith", "Waypoints: invalid use of usewith function")
locale:translate("WaypointsEditorErrorExecution", "Waypoints function execution error")

-- bot: looting
locale:translate("BotLootingBlacklist", "Loot every item, except these")
locale:translate("BotLootingAddItem", "Drag item or click on any of empty slot")
locale:translate("BotLootingConfigLootAll", "Loot every item")
locale:translate("BotLootingEditorTitle", "Looting editor")
locale:translate(
    "BotLootingEditorMessageRemoveConfig",
    "Do you want to remove current looting config?"
)

-- bot: attacking
locale:translate("BotAttackingButton", "AttackBot")
locale:translate("BotAttackingTitleEditMonster", "Edit monster")
locale:translate(
    "BotAttackingMessageRemoveConfig",
    "Do you want to remove current attacking config?"
)

-- bot: equipper
locale:translate("BotEquipperBossList", "Boss list")
locale:translate("BotEquipperMethodOrder", "More important methods come first.")
locale:translate("BotEquipperEQManager", "EQ Manager")

-- bot: botserver
locale:translate("BotServerWindowTitle", "BotServer")
locale:translate("BotServerWindowLabelData", "BotServer Data")
locale:translate("BotServerButton", "BotServer")

-- bot: cavebot
locale:translate("BotCavePing", "Server ping")
locale:translate("BotCaveWalkDelay", "Walk delay")
locale:translate("BotCaveMapClick", "Use map click")
locale:translate("BotCaveMapClickDelay", "Map click delay")
locale:translate("BotCaveIgnoreFields", "Ignore fields")
locale:translate("BotCaveSkipBlocked", "Skip blocked path")
locale:translate("BotCaveUseDelay", "Delay after use")

-- bot: other
locale:translate("BotSupplies", "Supplies")
locale:translate("BotHealerOptions", "Healer Options")
locale:translate("BotTitleHealBot", "HealBot")
locale:translate("BotFriendHealer", "Friend Healer")
locale:translate("BotSelfHealer", "Self Healer")
locale:translate("BotPushMaxSettings", "Pushmax Settings")
locale:translate("BotPushMaxButton", "PUSHMAX")
locale:translate("BotPlayerList", "Player List")
locale:translate("BotInfoMethodOrder", "More important methods come first (Example: Exura gran above Exura)")
locale:translate("BotButtonMinimiseAll", "Minimise All")
locale:translate("BotButtonReopenAll", "Reopen All")
locale:translate("BotButtonOpenMinimised", "Open Minimised")
locale:translate("BotButtonConditions", "Conditions")
locale:translate("BotButtonComboBot", "ComboBot")
locale:translate("BotWindowTitleExtras", "Extras")
locale:translate("BotWindowTitleDropper", "Dropper")
locale:translate("BotWindowTitleDepositer", "Depositer Panel")
locale:translate("BotWindowTitleContainerNames", "Container Names")
locale:translate("BotWindowTitleConditionManager", "Condition Manager")
locale:translate("BotWindowTitleComboOptions", "Combo Options")
locale:translate("BotAlarms", "Alarms")
locale:translate("BotHelpTutorials", "Help & Tutorials")
locale:translate("BotCreatureEditorHint_1", "You can use * (any characters) and ? (any character) in target name")
locale:translate("BotCreatureEditorHint_2", "You can also enter multiple targets, separate them by ,")
locale:translate("BotMinimapOptionCreateMark", "Create mark")
locale:translate("BotMinimapOptionAddGoTo", "Add CaveBot GoTo")
locale:translate("BotStatusWaiting", "Status: waiting")
locale:translate("BotMiniWindowTitle", "Bot")
locale:translate("BotMainPanelToggleButton", "Bot")

-- register
locale:register()
