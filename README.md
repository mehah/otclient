# New Layout OTC Client

New layout based on tibia 13

## Demo

https://github.com/Nottinghster/otclient/releases/tag/3.X.NewLayout

## Screenshots

![image](https://github.com/Nottinghster/otclient/assets/114332266/e15b7533-4a85-44f9-b9f9-9c0430411332)
![image](https://github.com/Nottinghster/otclient/assets/114332266/5ec61647-1099-4511-aca5-a351d4cc4f93)




## Features

- Layout tibia 13
- Calendar
- Outfit windows 13 soon
- Cooldown spell on top of the game_console like tibia 13
- ....

## Current bugs
**solved**
- [x] **Game_topmenu.** fix: Fps and ping https://github.com/Nottinghster/otclient/pull/8
- [x] **Game_Console** fix: preventing the text cursor from appearing when starting to write.  [87becf4](https://github.com/Nottinghster/otclient/commit/87becf4e2fcc7f7c494f87fae4f0d4b426f68749)
- [x] **corelib/ui/uiminiwindows** "droppedWidget" nil L224 https://github.com/Nottinghster/otclient/issues/10
- [x]  **game_containers** Panel nil L161 https://github.com/Nottinghster/otclient/issues/9
- [x] **Game_bot** Fix width mini windows bot [ad52ef0](https://github.com/Nottinghster/otclient/commit/ad52ef06dad02afc8276e3508fbe864dfb0cc38b)
- [x] **Game_entergame** MOTD old protocol
- [x] **Game_mainpanel** fix: combat control  chase. [#12](https://github.com/Nottinghster/otclient/pull/12)
- [x] **Game_topMenu** (onStatesChange) icons state [a350e7c](https://github.com/Nottinghster/otclient/commit/a350e7cc36dbf907675d57f2037ef86810482a62)
- [x] **Game_topmenu** missing Boton "manager account", "manager clients" [919444b](https://github.com/Nottinghster/otclient/commit/919444b6cecadbbad2d48a54a445079d17e83561)
- [x] **Game_mainpanel** Inventario fix ico state [ed9af33](https://github.com/Nottinghster/otclient/commit/ed9af33a6ed41f10e698d7017939e21bc5eedda6)
- [x] **Game_mainpanel** Hide icon "expert pvp modes" in minize panel for old protocole [2e6b171](https://github.com/Nottinghster/otclient/commit/2e6b17196a6112202ce0969aea0f8697f8f4db8e)
- [x] **data\images** Missing UI of tibia 13 ( close , minimize , scroll) [a94aebc](https://github.com/Nottinghster/otclient/commit/a94aebc730c36a34f44261918512596d337aa8d5)
- [x] **game_skills** Fix Ico location like clipsof [2ab0361](https://github.com/Nottinghster/otclient/commit/2ab03612d15a9ca4cc1f1db146e395d6d835d2e2)
- [x] **Game_entergame** problems with token label when no cache, (first open client) [3da57e3](https://github.com/Nottinghster/otclient/commit/3da57e364b10a89339decb2f20c6556e33db919a)
------------
**in process**
- [ ] **Miniwindows**
- [ ] **Game_mainpanel.** compatibility with extended view #7
- [ ] **Game_mainpanel** fix function inventoryController:onTerminate()
- [ ] **Game_outfit** of tibia 13 SOON
- [ ] **Game_bot** get the slot5 requested by quiver_label and quiver_manager
- [ ] **Client_bottom** default information if array services is not enabled
- [ ] font similar to tibia 13 (Verdana10px bold ? )




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

![image](https://github.com/Nottinghster/otclient/assets/114332266/01f7493e-de73-4a03-9c75-5c25f3f1493a)

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
| addLeftButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/2e3a8188-5be8-429e-8ee4-1139acf91c55)   |
| addLeftToggleButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/ce18e5c0-8ee3-4db0-b1cd-7bcd709fe2aa)   |
| addRightButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/0ce9d9d0-98eb-4ae4-8cae-af26edcef055)  |
| addRightToggleButton    |![image](https://github.com/Nottinghster/otclient/assets/114332266/6b16c163-1a9a-4a6e-859a-66a350840219)   |
| addLeftGameButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/0f029efd-76a6-4b98-9392-6fc312588c08)   |
| addLeftGameToggleButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/beb6d11a-9216-4d95-8246-2a2b72d9dd9d)   |
| addRightGameButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/c834060d-0675-4aae-a231-f527ff371693)   |
| addRightGameToggleButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/f221ccfb-3843-4c6a-a570-d70eb02628c9)   |
| addTopRightRegularButton    | ![image](https://github.com/Nottinghster/otclient/assets/114332266/e2adffb1-ed38-402b-acc4-1ad1d1a2db16)   |
| addTopRightToggleButton   | ![image](https://github.com/Nottinghster/otclient/assets/114332266/12e3acc9-b61a-457a-b857-b5bfb5179436)  |



## Author

- @ marcosvf132

## Contributing

We need people to test in versions higher than 8.6  and another who is skilled with PHP 

![429529469_10161745299305712_3655895523259386066_n](https://github.com/Nottinghster/otclient/assets/114332266/8ad690f2-b10c-49c5-93a2-7fe89b944101)
