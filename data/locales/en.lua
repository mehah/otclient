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

-- inserting arguments into translation strings:
-- %0 does not do anything
-- %1-%9 - arguments provided with the localize function

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

-- UI: common dialog options
locale:translate("ContextMenuCopyName", "Copy Name")

-- UI: system messages
locale:translate("Warning", "Warning")
locale:translate("Error", "Error")

-- date / time
-- for future
--[[
locale:translate("ClockAM", "AM")
locale:translate("ClockPM", "PM")
]]

-- weekday
locale:translate("Sunday", "Sunday")
locale:translate("Monday", "Monday")
locale:translate("Tuesday", "Tuesday")
locale:translate("Wednesday", "Wednesday")
locale:translate("Thursday", "Thursday")
locale:translate("Friday", "Friday")
locale:translate("Saturday", "Saturday")

-- month
locale:translate("January", "January")
locale:translate("February", "February")
locale:translate("March", "March")
locale:translate("April", "April")
locale:translate("May", "May")
locale:translate("June", "June")
locale:translate("July", "July")
locale:translate("August", "August")
locale:translate("September", "September")
locale:translate("October", "October")
locale:translate("November", "November")
locale:translate("December", "December")

--[[
-- for future
-- month alternative
-- (this is for grammatical purposes in other languages)
locale:translate("AltJanuary", "of January")
locale:translate("AltFebruary", "of February")
locale:translate("AltMarch", "of March")
locale:translate("AltApril", "of April")
locale:translate("AltMay", "of May")
locale:translate("AltJune", "of June")
locale:translate("AltJuly", "of July")
locale:translate("AltAugust", "of August")
locale:translate("AltSeptember", "of September")
locale:translate("AltOctober", "of October")
locale:translate("AltNovember", "of November")
locale:translate("AltDecember", "of December")

-- month name short
locale:translate("ShortJanuary", "Jan")
locale:translate("ShortFebruary", "Feb")
locale:translate("ShortMarch", "Mar")
locale:translate("ShortApril", "Apr")
locale:translate("ShortMay", "May")
locale:translate("ShortJune", "Jun")
locale:translate("ShortJuly", "Jul")
locale:translate("ShortAugust", "Aug")
locale:translate("ShortSeptember", "Sep")
locale:translate("ShortOctober", "Oct")
locale:translate("ShortNovember", "Nov")
locale:translate("ShortDecember", "Dec")

-- place suffixes (1st, 2nd, ..., nth)
-- (this is for grammatical purposes in other languages)
locale:translate("suffix_0", "th")
locale:translate("suffix_1", "st")
locale:translate("suffix_2", "nd")
locale:translate("suffix_3", "rd")
locale:translate("suffix_4", "th")
locale:translate("suffix_5", "th")
locale:translate("suffix_6", "th")
locale:translate("suffix_7", "th")
locale:translate("suffix_8", "th")
locale:translate("suffix_9", "th")
locale:translate("suffix_10", "th")
locale:translate("suffix_11", "th")
locale:translate("suffix_12", "th")
locale:translate("suffix_13", "th")
locale:translate("suffix_14", "th")
locale:translate("suffix_15", "th")
locale:translate("suffix_16", "th")
locale:translate("suffix_17", "th")
locale:translate("suffix_18", "th")
locale:translate("suffix_19", "th")
locale:translate("suffix_20", "th")
locale:translate("suffix_n1", "st")
locale:translate("suffix_n2", "nd")
locale:translate("suffix_n3", "rd")
locale:translate("suffix_n4", "th")
locale:translate("suffix_n5", "th")
locale:translate("suffix_n6", "th")
locale:translate("suffix_n7", "th")
locale:translate("suffix_n8", "th")
locale:translate("suffix_n9", "th")
locale:translate("suffix_n0", "th")
]]

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

-- text window (books and house list)
locale:translate("TextWindowDescriptionWriter", "You read the following, written by \n%1\n")
locale:translate("TextWindowDescriptionTime", "You read the following, written on \n%1.\n")
locale:transalte("TextWindowWrittenAt", "on %1.\n")
locale:translate("TextWindowEmpty", "It is empty.")
locale:translate("TextWindowWriteable", "You can enter new text.")
locale:translate("TextWindowShowText", "Show Text")
locale:translate("TextWindowEditText", "Edit Text")
locale:translate("TextWindowOneNamePerLine", "Enter one name per line.")
locale:translate("TextWindowDescriptionHouseList", "Edit List")

-- things
locale:translate("ThingsAssetLoadingFailed", "Couldn't load assets")
locale:translate("ThingsStaticDataLoadingFailed", "Couldn't load staticdata")
locale:translate("ThingsProtocolSpritesWarning", "Loading sprites instead of protobuf is unstable, use it at your own risk!")
locale:translate("ThingsDatLoadingFailed", "Unable to load dat file, please place a valid dat in '%1.dat'")
locale:translate("ThingsSprLoadingFailed", "Unable to load spr file, please place a valid spr in '%1.spr'")

-- unjustified kills panel
locale:translate("UnjustifiedPanelTitle", "Unjustified Points")
locale:translate("UnjustifiedPanelOpenPvP", "Open PvP")
locale:translate("UnjustifiedPanelOpenPvPSituations", "Open PvP Situations")
locale:translate("UnjustifiedPanelSkullTime", "Skull Time")

-- updater
locale:translate("UpdaterTitle", "Updater")
locale:translate("UpdaterChangeURL", "Change updater URL")
locale:translate("UpdaterCheckInProgress", "Checking for updates")
locale:translate("UpdaterMessageFileDownload", "Downloading:\n%1")
locale:translate("UpdaterMessageFileDownloadRetry", "Downloading (%1 retry):\n%2")
locale:translate("UpdaterError", "Updater Error")
locale:translate("UpdaterTimeout", "Timeout")
locale:translate("UpdaterMessagePending", "Updating client (may take few seconds)")
locale:translate("UpdaterMessageUpdatingFiles", "Updating %1 files")

-- viplist
locale:translate("VipListNoGroup", "No Group")
locale:translate("VipListPanelTitle", "VIP List")
locale:translate("VipListDialogVipAdd", "Add new VIP")
locale:translate("VipListDialogVipEdit", "Edit VIP")
locale:translate("VipListDialogVipEditDescription", "Description")
locale:translate("VipListDialogShowOffline", "Show Offline")
locale:translate("VipListDialogHideOffline", "Hide Offline")
locale:translate("VipListDialogShowGroups", "Show Groups")
locale:translate("VipListDialogHideGroups", "Hide Groups")
locale:translate("VipListDialogPlayerEdit", "Edit %1")
locale:translate("VipListDialogPlayerRemove", "Remove %1")
locale:translate("VipListDialogPlayerOpenChat", "Message to %1")
locale:translate("VipListDialogGroupAdd", "Add new group")
locale:translate("VipListDialogGroupEdit", "Edit group %1")
locale:translate("VipListDialogGroupRemove", "Remove group %1")
locale:translate("VipListPrivateChatInvite", "Invite to private chat")
locale:translate("VipListPrivateChatExclude", "Exclude from private chat")
locale:translate("VipListMessagePlayerLoggedIn", "%1 has logged in.")
locale:translate("VipListMessagePlayerLoggedOut", "%1 has logged out.")
locale:translate("VipListSortName", "Sort by name")
locale:translate("VipListSortType", "Sort by type")
locale:translate("VipListSortStatus", "Sort by status")
locale:translate("VipListGroupLimitTitle", "Maximum of User-Created Groups Reached")
locale:translate("VipListGroupLimitMessage", "You have already reached the maximum of groups you can create yourself.")
locale:translate("VipListWindowTitleGroupEdit", "Edit VIP group")
locale:translate("VipListWindowFormGroupName", "Please enter a group name")
locale:translate("VipListWindowTitleVipAdd", "Add to VIP list")
locale:translate("VipListLabelMemberOfGroups", "Member of the following groups")
locale:translate("VipListLabelNotifyOnLogin", "Notify-Login")
locale:translate("VipListCheckboxNotifyOnLogin", "Notify on login")
locale:translate("VipListCheckboxEmpty", "Empty")
locale:translate("VipListLabelCharacterName", "Please enter a character name")
locale:translate("VipListLabelGroupName", "Please enter a group name")

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
