-- main tab
VERSION = "1.3"

UI.Label("Config version: " .. VERSION)

UI.Separator()



UI.Separator()

UI.Button("Discord", function()
  g_platform.openUrl("https://discord.gg/yhqBE4A")
end)

UI.Button("Forum", function()
  g_platform.openUrl("http://otclient.net/")
end)

UI.Button("Help & Tutorials", function()
  g_platform.openUrl("http://bot.otclient.ovh/")
end)
