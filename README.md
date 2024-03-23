# New Layout OTC Client

New layout based on tibia 13

## Demo

https://github.com/Nottinghster/otclient/releases/tag/3.X.NewLayout

## Screenshots

![image](https://github.com/Nottinghster/otclient/assets/114332266/e15b7533-4a85-44f9-b9f9-9c0430411332)
![image](https://github.com/Nottinghster/otclient/assets/114332266/a591a4c2-0604-4427-aea1-6394b245ea8f)

## Features

- Layout tibia 13
- Calendar
- Outfit windows 13 soon
- ...

## Current bugs

- [x] **Game_topmenu.** fix: Fps and ping
- [x] **Game_Console** fix: preventing the text cursor from appearing when starting to write.
- [ ] **Game_mainpanel.** compatibility with extended view #7
- [ ] **Game_entergame** MOTD old protocol
- [ ] **Game_entergame** problems with token label when no cache, (first open client)
- [ ] **Game_topmenu** missing Boton "manager account", "manager clients"
- [ ] **Game_mainpanel** fix function inventoryController:onTerminate()
- [ ] **Game_mainpanel** Hide icon "bless" in minize panel for old protocole
- [ ] **Game_mainpanel** Inventario fix ico state
- [ ] **Game_outfit** of tibia 13 SOON
- [ ] **Game_mainpanel** (inventary) Fix Ico game skills like clipsof
- [ ] **Game_bot** Fix width mini windows bot
- [ ] **Game_bot** get the slot5 requested by quiver_label and quiver_manager
- [ ] **Game_topMenu** (onStatesChange) icons state
- [ ] **Game_mainpanel** Missing UI of tibia 13 ( close , minimize , scroll)
- [ ] **Characterlist** Add checkbox "show outift" button
- [ ] **Client_bottom** default information if array services is not enabled
- [ ] **game_containers** Panel nil L161
- [ ] **corelib/ui/uiminiwindows** "droppedWidget" nil L224

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

![](https://geps.dev/progress/0) game_console

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

![](https://geps.dev/progress/90) game_skills

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
  - [ ] Incorrect Tab(key) order.
  - [ ] MOTD
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

- Status: Incomplete
- Bugs:
  - [ ] Issue : preventing the cursor from appearing when starting to write.
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
  - [ ] Issue : Hide icon "bless" in minize panel

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
  - [ ] Issue : Ico game skills like clipsof
  - [ ] Issue
- **Notes: NEED FIX LOCATION ICONS AND SIZE**

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

---

## Author

- @ marcosvf132
