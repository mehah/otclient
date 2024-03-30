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
- Outfit windows 13 soon
- Cooldown spell on top of the game_console like tibia 13
- game_shop of v8 compatible with attachEffect and shader


## Current bugs
**solved**
- [x] **Game_entergame** MOTD old protocol
- [x] **Game_topmenu.** fix: Fps and ping https://github.com/Nottinghster/otclient/pull/8
- [x] **Game_Console** fix: preventing the text cursor from appearing when starting to write.  [87becf4](https://github.com/Nottinghster/otclient/commit/87becf4e2fcc7f7c494f87fae4f0d4b426f68749)
- [x] **corelib/ui/uiminiwindows** "droppedWidget" nil L224 https://github.com/Nottinghster/otclient/issues/10
- [x]  **game_containers** Panel nil L161 https://github.com/Nottinghster/otclient/issues/9
- [x] **Game_bot** Fix width mini windows bot [ad52ef0](https://github.com/Nottinghster/otclient/commit/ad52ef06dad02afc8276e3508fbe864dfb0cc38b)
- [x] **Game_mainpanel** fix: combat control  chase. [#12](https://github.com/Nottinghster/otclient/pull/12)
- [x] **Game_topMenu** (onStatesChange) icons state [a350e7c](https://github.com/Nottinghster/otclient/commit/a350e7cc36dbf907675d57f2037ef86810482a62)
- [x] **Game_topmenu** missing Boton "manager account", "manager clients" [919444b](https://github.com/Nottinghster/otclient/commit/919444b6cecadbbad2d48a54a445079d17e83561)
- [x] **Game_mainpanel** Inventario fix ico state [ed9af33](https://github.com/Nottinghster/otclient/commit/ed9af33a6ed41f10e698d7017939e21bc5eedda6)
- [x] **Game_mainpanel** Hide icon "expert pvp modes" in minize panel for old protocole [2e6b171](https://github.com/Nottinghster/otclient/commit/2e6b17196a6112202ce0969aea0f8697f8f4db8e)
- [x] **data\images** Missing UI of tibia 13 ( close , minimize , scroll) [a94aebc](https://github.com/Nottinghster/otclient/commit/a94aebc730c36a34f44261918512596d337aa8d5)
- [x] **game_skills** Fix Ico location like clipsof [2ab0361](https://github.com/Nottinghster/otclient/commit/2ab03612d15a9ca4cc1f1db146e395d6d835d2e2) - [4611fe2](https://github.com/Nottinghster/otclient/commit/4611fe28bb0ecaa7b3d0cb5a4c9576e2d91a6223) - [51f99e8](https://github.com/Nottinghster/otclient/commit/51f99e8fec86b9026a1071d58b4197650b5783c5)
- [x] **Game_entergame** problems with token label when no cache, (first open client) [3da57e3](https://github.com/Nottinghster/otclient/commit/3da57e364b10a89339decb2f20c6556e33db919a)
- [x] **Client_bottom** default information if array services is not enabled [25d0e45](https://github.com/Nottinghster/otclient/commit/25d0e4526a41228e3391d9a7706c18b645b3219c)
- [x]  **Game_mainpanel**  To make use of the store button. (button below the inventory) [b52f153](https://github.com/Nottinghster/otclient/commit/b52f15386c3a1fbca2b5760ae6aae0bcef0e5a47) - [ae44616](https://github.com/Nottinghster/otclient/commit/ae44616702a181e89dad9e04ca61b627d6d1ad46) - [0b38a12](https://github.com/Nottinghster/otclient/commit/0b38a12438d5d2cebb6529d4de023c049d29f247)
- [x] **game_shader** offset panel combobox of shader because collides with the ping []()
- [x] **game_container** container like tibia 13. [71ee1a8](https://github.com/Nottinghster/otclient/commit/71ee1a8bdf25ab713656fd3ad28673d094f22a0c)
------------
**in process**
- [ ] **Statsbar//Game_mainpanel** Bug states onStatesChange bug
- [ ] **Game_mainpanel//minimap** bug: minimap .white cross out of bounds [#15](https://github.com/Nottinghster/otclient/issues/15)
- [ ] **Game_mainpanel//game_interface** incorrect g_game.getClientVersion() .lua .otui [#13](https://github.com/Nottinghster/otclient/issues/13)
- [ ] **Game_mainpanel//game_interface mode(2)** compatibility with extended view  [#7](https://github.com/Nottinghster/otclient/issues/7)
- [ ] **Game_mainpanel//inventary** fix function inventoryController:onTerminate()
- [ ] **Game_outfit** of tibia 13 SOON
- [ ] **Game_bot** get the slot5 requested by quiver_label and quiver_manager
- [ ] **data/styles/** Using a unique font similar to Tibia 13 (i think is Verdana10px bold ? )
- [ ] **data/styles/** Using the vertical and horizontal scrollbars of Tibia 13. ![image](https://github.com/Nottinghster/otclient/assets/114332266/623f01c9-41cf-4763-88e5-449cf7127f5e)
- [ ] **game_actionbar** Adapt the v8 game_actionbar with vertical and horizontal panels. (closer to Tibia 13), with options in client_options.
- [ ] **game_mainPanel//minimap** Create a function in C++ of **g_game onChangeWorldTime** for minimap.
- [ ] **game_interface//statsbar** if you set to "hide" , close and open the client. the "compact" statsbar is displayed.( "hide" style bar is not saved)
- [ ] **.otui** Some of the windows are not draggable (client_options)
- [ ] check if there are duplicated functions, or even clean some codes
     - data/styles/ .otui (unused UI)
     - topmenu/Mainpanel incorrectly named functions and some of them repeated



## Overall Status

<details>
<summary>Overall Status</summary>

![](https://geps.dev/progress/100) = compatibility terminated

![](https://geps.dev/progress/99) = unmodified, test require

![](https://geps.dev/progress/0) = not reviewed yet

---

## ./modules

![](https://geps.dev/progress/99) client `--unmodified, test required`

![](https://geps.dev/progress/99) client_background `--unmodified, test required`

![](https://geps.dev/progress/80) client_bottommenu

![](https://geps.dev/progress/90) client_entergame

![](https://geps.dev/progress/99) client_locales `--unmodified, test required`

![](https://geps.dev/progress/0) client_options

![](https://geps.dev/progress/90) client_serverlist

![](https://geps.dev/progress/99) client_styles `--unmodified, test required`

![](https://geps.dev/progress/99) client_terminal `--unmodified, test required`

![](https://geps.dev/progress/90) client_topmenu

![](https://geps.dev/progress/0) corelib

![](https://geps.dev/progress/0) gamelib

![](https://geps.dev/progress/0) game_actionbar

![](https://geps.dev/progress/99) game_attachedeffects `--unmodified, test required`

![](https://geps.dev/progress/90) game_battle

![](https://geps.dev/progress/99) game_bugreport `--unmodified, test required`

![](https://geps.dev/progress/100) game_console

![](https://geps.dev/progress/99) game_containers `--unmodified, test required`

![](https://geps.dev/progress/99) game_cooldown `--unmodified, test required`

![](https://geps.dev/progress/99) game_features

![](https://geps.dev/progress/0) game_healthcircle

![](https://geps.dev/progress/0) game_hotkeys

![](https://geps.dev/progress/99) game_imbuing `--unmodified, test required`

![](https://geps.dev/progress/0) game_interface

![](https://geps.dev/progress/10) game_mainpanel

![](https://geps.dev/progress/99) game_market `--unmodified, test required`

![](https://geps.dev/progress/99) game_modaldialog `--unmodified, test required`

![](https://geps.dev/progress/0) game_npctrade `--unmodified, test required`

![](https://geps.dev/progress/0) game_outfit `--unmodified, test required`

![](https://geps.dev/progress/0) game_playerdeath `--unmodified, test required`

![](https://geps.dev/progress/0) game_playermount `--unmodified, test required`

![](https://geps.dev/progress/0) game_playertrade `--unmodified, test required`

![](https://geps.dev/progress/0) game_prey \*\*1

![](https://geps.dev/progress/99) game_questlog `--unmodified, test required`

![](https://geps.dev/progress/0) game_ruleviolation `--unmodified, test required`

![](https://geps.dev/progress/0) game_shaders `--unmodified, test required`

![](https://geps.dev/progress/100) game_skills

![](https://geps.dev/progress/99) game_spelllist `--unmodified, test required`

![](https://geps.dev/progress/99) game_stash `--unmodified, test required`

![](https://geps.dev/progress/99) game_tasks `--unmodified, test required`

![](https://geps.dev/progress/0) game_textmessage

![](https://geps.dev/progress/99) game_textwindow `--unmodified, test required`

![](https://geps.dev/progress/99) game_things `--unmodified, test required`

![](https://geps.dev/progress/99) game_unjustifiedpoints `--unmodified, test required` \*\*1

![](https://geps.dev/progress/99) game_viplist `--unmodified, test required` \*\*1

![](https://geps.dev/progress/99) startup

![](https://geps.dev/progress/99) updater `--unmodified, test required`

</details>

## Detailed Module Analysis

<details>
### client

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_background

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_bottommenu

- Status: Incomplete
- Bugs:
  - [x] Issue : http post support #6
  - [ ] Issue : miss fix outfit boosted

### client_entergame

- Status: Incomplete
- Bugs:
  - [x] Incorrect Tab(key) order.
  - [x] MOTD
  - [ ] Test v13
  - [x] bug login quickly unfinished http post

### client_locales

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_options

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_serverlist

- Status: Incomplete
- Bugs:
  - [ ] Issue : Bug in main repo mehah
  - [ ] Issue

### client_styles

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_terminal

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### client_topmenu

- Status: Incomplete
- Bugs:
  - [x] Issue : http post support #6
  - [ ] Issue : miss "manager account", "manager clients"

### corelib

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### gamelib

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_actionbar

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_attachedeffects

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_battle

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_bugreport

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_console

- Status: Completed
- Bugs:
  - [x] Issue : preventing the cursor from appearing when starting to write.
  - [x] Issue : Fix enter for enable WASD
  - [x] Issue :add "isEnabledWASD" missing funcion bot #6

### game_containers

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_cooldown

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_features

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_healthcircle

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_hotkeys

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_imbuing

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_interface

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_mainpanel

- Status: Incomplete
- Bugs:
  - [x] Issue : Cap, soul not work
  - [x] Issue : Inventary , hide icons "bless" in old protocol
  - [x] Issue : Conditions icons are not coded
  - [x] Issue : When you attack and chase mode is follow, there's error in terminal (need auto Chase option turned on)
  - [ ] Issue : fix function inventoryController:onTerminate()
  - [x] Issue : Hide icon "bless" in minize panel

**NOTE: **

- correct the version of the if function "bless"

### game_market

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_modaldialog

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_npctrade

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_outfit

- Status: Incomplete
- Bugs:
  - [ ] Issue : compatibility with v8
  - [ ] Issue

### game_playerdeath

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_playermount

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_playertrade

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_prey

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_questlog

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_ruleviolation

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_shaders

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_skills

- Status: Incomplete
- Bugs:
  - [x] Issue : Ico game skills like clipsof

### game_spelllist

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_stash

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_tasks

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_textmessage

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_textwindow

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_things

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_unjustifiedpoints

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### game_viplist

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### startup

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

### updater

- Status: Incomplete
- Bugs:
  - [ ] Issue
  - [ ] Issue

## MOD

## ![](https://geps.dev/progress/90)

### ./Mod/bot

- Status: Incomplete
- Bugs:
  - [ ] Issue: Fix width mini windows
  - [ ] Issue: get the slot5 requested by quiver_label and quiver_manager

## Data

---

### ./data/images

![](https://geps.dev/progress/80)

- Status: Incomplete
- Bugs:
  - [ ] Issue: Fix Bot icon top menu
  - [ ] Issue fix: icons state
  - [ ] close , minimize , scroll ico

### ./data/Style

![](https://geps.dev/progress/0)

- Status: Incomplete
- Bugs:
  - [ ] Issue:
  - [ ] Issue

</details>

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
