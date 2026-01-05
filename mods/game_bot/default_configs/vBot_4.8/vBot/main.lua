local version = "4.8"
local currentVersion
local available = false

UI.Label("vBot v".. version .." \n Vithrax#5814")
UI.Button("Official OTCv8 Discord!", function() g_platform.openUrl("https://discord.gg/yhqBE4A") end)
UI.Separator()

schedule(5000, function()

    if not available then return end
    if currentVersion ~= version then

        UI.Separator()
        UI.Label("New vBot is available for download! v"..currentVersion)
        UI.Button("Go to vBot GitHub Page", function() g_platform.openUrl("https://github.com/Vithrax/vBot") end)
        UI.Separator()

    end

end)
