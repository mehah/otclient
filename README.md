# New Layout OTC Client

New layout based on tibia 13

## Demo

https://github.com/Nottinghster/otclient/releases/tag/3.X.NewLayout

## Screenshots

![image](https://github.com/Nottinghster/otclient/assets/114332266/e15b7533-4a85-44f9-b9f9-9c0430411332)
![1](https://github.com/Nottinghster/otclient/assets/7372287/2b722f7e-b2b6-44f8-9893-9c6a1a77ee69)
![GIF 29-03-2024 11-16-44](https://github.com/Nottinghster/otclient/assets/7372287/b7160f27-57c8-428f-a06e-d9e0610699af)

## Features

- Layout tibia 13
- Calendar
- Cooldown spell on top of the game_console like tibia 13
- game_shop of v8 compatible with attachEffect and shader
- Outfit windows v8 is the most similar to tibia 13 compatible with attachEffect , shader 

## Current bugs
**solved**
- [x] **Game_entergame** MOTD old protocol
- [x] **Game_topmenu.** fix: Fps and ping https://github.com/Nottinghster/otclient/pull/8
- [x] **Game_Console** fix: preventing the text cursor from appearing when starting to write.  [87becf4](https://github.com/Nottinghster/otclient/commit/87becf4e2fcc7f7c494f87fae4f0d4b426f68749)
- [x] **Corelib/ui/uiminiwindows** "droppedWidget" nil L224 https://github.com/Nottinghster/otclient/issues/10
- [x] **Game_containers** Panel nil L161 https://github.com/Nottinghster/otclient/issues/9
- [x] **Game_bot** Fix width mini windows bot [ad52ef0](https://github.com/Nottinghster/otclient/commit/ad52ef06dad02afc8276e3508fbe864dfb0cc38b)
- [x] **Game_mainpanel** fix: combat control  chase. [#12](https://github.com/Nottinghster/otclient/pull/12)
- [x] **Game_topMenu** (onStatesChange) icons state [a350e7c](https://github.com/Nottinghster/otclient/commit/a350e7cc36dbf907675d57f2037ef86810482a62)
- [x] **Game_topmenu** missing Boton "manager account", "manager clients" [919444b](https://github.com/Nottinghster/otclient/commit/919444b6cecadbbad2d48a54a445079d17e83561)
- [x] **Game_mainpanel** Inventario fix ico state [ed9af33](https://github.com/Nottinghster/otclient/commit/ed9af33a6ed41f10e698d7017939e21bc5eedda6)
- [x] **Game_mainpanel** Hide icon "expert pvp modes" in minize panel for old protocole [2e6b171](https://github.com/Nottinghster/otclient/commit/2e6b17196a6112202ce0969aea0f8697f8f4db8e)
- [x] **Data\images** Missing UI of tibia 13 ( close , minimize , scroll) [a94aebc](https://github.com/Nottinghster/otclient/commit/a94aebc730c36a34f44261918512596d337aa8d5)
- [x] **Game_skills** Fix Ico location like clipsof [2ab0361](https://github.com/Nottinghster/otclient/commit/2ab03612d15a9ca4cc1f1db146e395d6d835d2e2) - [4611fe2](https://github.com/Nottinghster/otclient/commit/4611fe28bb0ecaa7b3d0cb5a4c9576e2d91a6223) - [51f99e8](https://github.com/Nottinghster/otclient/commit/51f99e8fec86b9026a1071d58b4197650b5783c5)
- [x] **Game_entergame** problems with token label when no cache, (first open client) [3da57e3](https://github.com/Nottinghster/otclient/commit/3da57e364b10a89339decb2f20c6556e33db919a)
- [x] **Client_bottom** default information if array services is not enabled [25d0e45](https://github.com/Nottinghster/otclient/commit/25d0e4526a41228e3391d9a7706c18b645b3219c)
- [x] **Game_mainpanel**  To make use of the store button. (button below the inventory) [b52f153](https://github.com/Nottinghster/otclient/commit/b52f15386c3a1fbca2b5760ae6aae0bcef0e5a47) - [ae44616](https://github.com/Nottinghster/otclient/commit/ae44616702a181e89dad9e04ca61b627d6d1ad46) - [0b38a12](https://github.com/Nottinghster/otclient/commit/0b38a12438d5d2cebb6529d4de023c049d29f247)
- [x] **Game_shader** offset panel combobox of shader because collides with the ping []()
- [x] **Game_container** container like tibia 13. [71ee1a8](https://github.com/Nottinghster/otclient/commit/71ee1a8bdf25ab713656fd3ad28673d094f22a0c)
- [x] **Statsbar//Game_mainpanel** Bug states onStatesChange bug [f82f2f0](https://github.com/Nottinghster/otclient/commit/f82f2f0df58c6944714a3670429e1d99ee1fc1b2)
- [x] **Game_mainPanel//minimap** Create a function in C++ of **g_game onChangeWorldTime** for minimap. [a8b55ea](https://github.com/Nottinghster/otclient/commit/a8b55ea748c9be7abadb5936b36399d7961598eb)
- [x] **Game_interface//statsbar** if you set to "hide" , close and open the client. the "compact" statsbar is displayed.( "hide" style bar is not saved) [83cde71](https://github.com/Nottinghster/otclient/commit/83cde710bd4ab34792569f528fe1609489563a79)
- [x] **Game_bot** get the slot5 requested by quiver_label and quiver_manager
- [x] **Game_mainpanel//game_interface** incorrect g_game.getClientVersion() .lua .otui [#13](https://github.com/Nottinghster/otclient/issues/13) - [170a089](https://github.com/Nottinghster/otclient/commit/170a089e3aa1ee806ef1299c4b10ab3508a8c9a9)
- [x] **Game_mainpanel//inventary** fix function inventoryController:onTerminate() - [53fcbb4](https://github.com/Nottinghster/otclient/commit/53fcbb4c065df0b2c0a16c47bf79e99e86b0493d#diff-9c2eaf0f9aece4afc40f30e75559dc5113cb3ddc75ecf66ddd5ce7d17a0935d5)
- [x] **Game_outfit** v8 is the most similar to tibia 13 compatible with attachEffect , shader (no test yet title and health bars) [#25](https://github.com/Nottinghster/otclient/pull/25)
- [x] **Game_mainpanel//minimap** bug: minimap .white cross out of bounds [#15](https://github.com/Nottinghster/otclient/issues/15) - [6644075](https://github.com/Nottinghster/otclient/commit/6644075a65913e2abed981b4dd1c376178ffa74a)
- [x] **Sources//game_outfit** outfit not centralized in outfit window (crops)  [#35](https://github.com/Nottinghster/otclient/issues/35) - [307fe15](https://github.com/Nottinghster/otclient/commit/307fe1575fed2e768a388faf7df6aa50e1254fb5)
------------
**in process**
- [ ] **data/styles/** Using a unique font similar to Tibia 13 (i think is Verdana10px bold ? )
- [ ] **data/styles/** Using the vertical and horizontal scrollbars of Tibia 13. ![image](https://github.com/Nottinghster/otclient/assets/114332266/623f01c9-41cf-4763-88e5-449cf7127f5e)
- [ ] **game_actionbar** Adapt the v8 game_actionbar with vertical and horizontal panels. (closer to Tibia 13), with options in client_options.
- [ ] **github** revert all commits of "feat: compatibility with 13.32"
- [ ] **.otui** Some of the windows are not draggable (client_options)
- [ ] check if there are duplicated functions, or even clean some codes
     - data/styles/ .otui (unused UI)
     - game_outfit rename functions, use local functions to obtain a widget
     - topmenu/Mainpanel incorrectly named functions and some of them repeated

## FAQ

### **1.- what is game_mainpanel ?**

![image](https://cdn.discordapp.com/attachments/1188251464603283526/1223263276834492536/image.png?ex=661937b4&is=6606c2b4&hm=2d8e6da381b083cb1c153220a7e7847fbddcb4a8876f8006367dcbb1c1746d09&)

union inventory , minimap, combat control

### **2.- where is minimap ?**

game_mainpanel LXX

### **3.-where is inventary ?**

game_mainpanel LXX

### **4.- what is client_bottommenu ?**

![image](https://github.com/Nottinghster/otclient/assets/114332266/19928bf5-76d5-4cfd-a43a-8514a024daf6)

> note test in : uniServer Z php version 82

### **5.- I have problems with bottons of my custom modules**

old function

    modules.client_topmenu.addRightGameToggleButton

new function

    modules.game_mainpanel.addToggleButton

![image](https://github.com/Nottinghster/otclient/assets/114332266/2891f3fe-524d-4cae-8bd3-272e1607b1d6)

### **6.- why is this not displayed ?**

![image](https://github.com/Nottinghster/otclient/assets/114332266/d1104f03-1726-4c25-9698-84c465369514)
![image](https://github.com/Nottinghster/otclient/assets/114332266/3fdad239-963c-4464-a811-3cfde41b8938)
![image](https://github.com/Nottinghster/otclient/assets/114332266/532cd93e-f589-4f3e-ac58-94d45c4fcd58)

activate the array "Services.status" in init.lua

and put this

`./otclient/tools/api/status.php`

in your

`C:/UniServerZ/www/api/`


if not work try ,active **curl**:

![image](https://github.com/Nottinghster/otclient/assets/114332266/99ad2ce7-d70f-47f4-aa19-083140fb5814)

![image](https://github.com/Nottinghster/otclient/assets/114332266/84349388-a458-4eb5-b1d6-cce5693cfd5a)

### **7.- where do I edit this?**
![image](https://github.com/Nottinghster/otclient/assets/114332266/346fb845-7441-45c2-ac49-f11b2bf8535a)

.\otclient\data\styles\30-statsbar.otui

.\otclient\modules\game_interface\widgets\statsbar.lua

### **7.5.-How do I hide top menu?**
![image](https://github.com/Nottinghster/otclient/assets/114332266/ceca0186-f65b-448b-ab72-ab4cef368f46)

### **8.- Where is the array Icons?**


```
Icons[PlayerStates.Poison] = {
    tooltip = tr('You are poisoned'),
    path = '/images/game/states/poisoned',
    id = 'condition_poisoned'
}
```

.\otclient\modules\gamelib\player.lua


# 9 .- why does the time not work on the mini map?

![image](https://github.com/Nottinghster/otclient/assets/114332266/dd15198b-28ea-433e-841e-5a917f766e09) ![image](https://github.com/Nottinghster/otclient/assets/114332266/3f5e1b3b-130d-436a-8072-6d989a001e4f)

check these functions on your server

old tfs: void ProtocolGame::sendWorldTime()

new tfs : function Player.sendWorldTime(self, time)

Canary: void ProtocolGame::sendTibiaTime(int32_t time)


## info
I know there are errors in naming regarding the location, but it's RETROCOMPATIBILITY, and it's also beta.
There are some duplicates and others that need to have their names changed.
| Function | Image |
|-----------|-----------|
| addLeftButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/117ed15b-6d40-4e17-911b-f54129c1bc93)   |
| addLeftToggleButton  (icon)  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/606f5ec0-409d-4dfa-bb38-e57e6b4b0fd8)   |
| addRightButton  **  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/92161803-e743-4b4a-898d-8cffc74d2f5d)  |
| addRightToggleButton(icon)  **  |![image](https://github.com/Nottinghster/otclient/assets/114332266/228089b8-f0c2-49fa-8398-42e82492b612)  |
| addTopRightRegularButton **   | ![image](https://github.com/Nottinghster/otclient/assets/114332266/50103b0f-819e-4eda-8efe-34caa29fec98)  |
| addTopRightToggleButton (icons)**  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/37e7f3a8-3486-40ef-bbb0-f6b71ccd8e57)  |
| addLeftGameButton  ***  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/eb6666c8-2597-448f-915c-0190db706bbc)   |
| addLeftGameToggleButton  ***  |![image](https://github.com/Nottinghster/otclient/assets/114332266/a8eb6714-cf9c-4d76-81a4-ed9547402d08)  |
| addRightGameButton  ***  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/c7bab85c-86f2-4ead-b23f-b141723729ba)  |
| addRightGameToggleButton ***  | ![image](https://github.com/Nottinghster/otclient/assets/114332266/af39b255-7afb-4142-8ed5-c143ac6f6237)  |
| addStoreButton | ![image](https://github.com/Nottinghster/otclient/assets/114332266/e597d6a6-740e-470b-801c-edf3ebce2168)  |

**is intended to eliminate 2
*** for backward compatibility, it is retained


## Author

- @ marcosvf132

## Contributing

We need people to test in versions higher than 8.6  and another who is skilled with PHP 

![429529469_10161745299305712_3655895523259386066_n](https://github.com/Nottinghster/otclient/assets/114332266/8ad690f2-b10c-49c5-93a2-7fe89b944101)

### Example Feature

<table style="border-collapse: collapse; width: 100%;" border="1">
  <tbody>
    <tr>
      <td style="width: 50%; ">
        <strong><center> Feature</center></strong>
      </td>
      <td style="width: 50%;"><center><strong> Gif</strong></center></td>
    </tr>
    <tr>
      <td style="width: 50%;">
        <pre><code class="lua"><p><strong>Attach Effect</strong></p>
local player = g_game.getLocalPlayer()
player:attachEffect(
  g_attachedEffects.getById(2)
  )
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/782e0fcf-b1cf-451e-b102-d7e7943bd50b" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
        <strong><p>QR</p></strong>
        <pre><code class="lua">UIWidget
  size: 200 200
  anchors.centerIn: parent
  qr-code: mehah
  qr-code-border: 2
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/a9ea3ce9-2a02-4b39-9b5f-7308db16e710" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
        <p>Reload module</p>
        <pre><code class="lua">g_modules.enableAutoReload()
</code></pre>
      </td>
      <td style="width: 50%;"><video src="https://github.com/Nottinghster/otclient/assets/114332266/bdd01687-1671-4150-8354-10a9c340c480" width="640" height="360" controls></video></td>
    </tr>
    <tr>
      <td style="width: 50%;">
        <strong><p>Shaders</p></strong>
item :
        <pre><code class="lua">local item = ItemWidget:getItem()
item:setShader("Outfit - Outline")
</code></pre>
Player :
  <pre><code class="lua">local player= g_game.getLocalPlayer()
player:setShader("Outfit - Outline")
</code></pre>
Map :
<pre><code class="lua">local map = modules.game_interface.getMapPanel()
map:setShader('Map - Party')
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/021119e2-d6e7-41e1-8a83-d07efcce452b" /></br>
      <img style="max-width: 100%; height: auto;" src="https://github.com/kokekanon/otclient.readme/assets/114332266/e1f2e593-d87d-4ec3-9e72-7e478a3acdba" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
       <strong> <p>Discord RPC</p></strong>
        <pre><code>- To enable just go to
  set 1 in ENABLE_DISCORD_RPC 
  and configure the others definitions
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/cd93e5e6-4e2a-4dd2-b66b-6e28408363d6" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
       <strong> <p>Typing Icon</strong></p>
        <pre><code>
To enable just go to setup.otml 
and set draw-typing: true
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/3e7c00bb-94ea-458f-9b07-43b622c8253c" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
       <strong> <p>Colored text</p></strong>
        <pre><code class="lua">
widget:setColoredText("
{" .. variable .. ", #C6122E} / 
{Colored text, #ff00ff} normal text")
</code></pre>
      </td>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/9ea52de2-c193-4951-9454-ddc58685c65c" /></td>
    </tr>
    <tr>
      <td style="width: 50%;">
        <p><strong>Smooth Walk Elevation</strong></p>
        Enable on <p><a href="https://github.com/mehah/otclient/blob/main/modules/game_features/features.lua#L5">game_features</a></p>
        <pre><code class="lua">
g_game.enableFeature(GameSmoothWalkElevation)</td>
</code></pre>
      <td style="width: 50%;"><img style="max-width: 100%; height: auto;" src="https://github.com/Nottinghster/otclient/assets/114332266/208bd4e4-3a76-4e2f-960e-7761d0fb7aed" /></td>
    </tr>
  </tbody>
</table>
