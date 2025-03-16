# Record On Client

`modules/client_entergame/characterlist.lua`
https://github.com/mehah/otclient/blob/5bf0e87ff4393d300c02e9185f18e8cea9f52a90/modules/client_entergame/characterlist.lua#L48
Add an argument to the function `g_game.loginWorld` , which represents the name and extension.

Ex: `os.time() .. '.cam'`
```diff
-   g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort, charInfo.characterName, G.authenticatorToken, G.sessionKey)
+   g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort, charInfo.characterName, G.authenticatorToken, G.sessionKey, os.time() .. '.cam')
```

# Record On TFS by gesior
1) Add these changes https://github.com/gesior/tmp-cams-system
2) the server will create the .cam file
3) move the created file from the tfs/records folder to the OTC/records folder

# Play Record
In terminal : 
```lua
g_game.setClientVersion(1098)         
g_game.setProtocolVersion(g_game.getClientProtocolVersion(1098))         
```

```lua
g_game.playRecord("test1098.cam")
EnterGame.hide()
```
