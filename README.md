<h1><img src="https://github.com/mehah/otclient/blob/main/data/images/clienticon.png?raw=true" width="32" alt="logo"/> OTClient - Redemption</h1>

[![Discord Shield](https://discordapp.com/api/guilds/888062548082061433/widget.png?style=shield)](https://discord.gg/HZN8yJJSyC)
[![Build - Ubuntu](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml)
[![Build - Windows](https://github.com/mehah/otclient/actions/workflows/build-windows.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-windows.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)




## 📋 Table of Contents

1. ![Logo](https://raw.githubusercontent.com/mehah/otclient/main/src/otcicon.ico)  [What is otclient?](#whatisotclient)
2. 🚀 [Features](#features)
6. <img height="16" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/android/android.png" alt="Android"> [The Mobile Project](#themobileproject)
3. 🔨 [Compiling](#compiling)
4. 🐳 [Docker](#docker)
5. 🩺 [Need help?](#need-help?)
6. 📑 [Bugs?](#bugs)
7. ❤️  [Roadmap](#roadmap)
8. 💯 [Support Protocol](#supportprotocol)
9. ©️  [License](#license)
10. ❤️ [Contributors](#contributors)

## <a name="whatisotclient">![Logo](https://raw.githubusercontent.com/mehah/otclient/main/src/otcicon.ico)  What is otclient?</a>

Otclient is an alternative Tibia client for usage with otserv. It aims to be complete and flexible, for that it uses LUA scripting for all game interface functionality and configurations files with a syntax similar to CSS for the client interface design. Otclient works with a modular system, this means that each functionality is a separated module, giving the possibility to users modify and customize anything easily. Users can also create new mods and extend game interface for their own purposes. Otclient is written in C++20 and heavily scripted in lua.

For a server to connect to, you can build your own with the forgottenserver or canary.

> \[!NOTE]
>
>Based on [edubart/otclient](https://github.com/edubart/otclient) Rev: [2.760](https://github.com/edubart/otclient/commit/fc39ee4adba8e780a2820bfda66fc942d74cedf4)

## <a name="features">🚀 Features</a>
Beyond of it's flexibility with scripts, otclient comes with tons of other features that make possible the creation of new client side stuff in otserv that was not possible before. These include, sound system, graphics effects with shaders, modules/addons system, animated textures, styleable user interface, transparency, multi language, in game lua terminal, an OpenGL 2.0 ES engine that make possible to port to mobile platforms. Otclient is also flexible enough to create tibia tools like map editors just using scripts, because it wasn't designed to be just a client, instead otclient was designed to be a combination of a framework and tibia APIs.


- <details>
  <summary>Details of optimizations with respect to OTClient by edubart: </summary>


  - C++20 ( v17 , Unity build and Manifest Mode (vcpkg.json) ) build in x32 and x64

  - <details>
    <summary>Asynchronous texture loading</summary>

      - **i ) Description**: with this the spr file is not cached, consequently, less ram is consumed.

      - **ii ) Video**


      https://github.com/kokekanon/otclient.readme/assets/114332266/f3b7916a-d6ed-46f5-b516-30421de4616d


    </details>

  - <details>
    <summary>Multi-threading</summary>

      -**i ) Description**:

    [Main Thread]
    - Sound
    - Particles
    - Load Textures (files)
    - Windows Events (keyboard, mouse, ...)
    - Draw texture

    [Thread 2]
    - Connection
    - Events (g_dispatcher)
    - Collect information on what will be drawn on the Map

    [Thread 3]
    - Collect information on what will be drawn in the UI


      - **ii ) Imagen:**
      ![multinucleo](https://github.com/kokekanon/otclient.readme/assets/114332266/95fb15ac-553f-4eca-937d-8c8f49990f3e)

    </details>

  - <details>
    <summary>Less memory usage</summary>

      - **i ) Description**: 
        ```async autoreload
        highlightingPtr to stackPos
        new async dispatcher (using bs thread_pool)
        optimized updateChildrenIndexStates & updateLayout
        removed ThingTypePtr
        scoped object to raw pointer
        shaderPtr to shaderId
        and multiple optimizations
        ```


    </details>

  - <details>
    <summary>New Lighting System with Fading</summary>

      - **i ) Video**


      https://github.com/kokekanon/otclient.readme/assets/114332266/de8ffd14-af8c-4cc0-b5b1-2e166243bffc


    </details>

  - Walking System Improvements


  - Supports sequenced packages and compression

  - Asserts load (Tibia 13)

  - <details>
    <summary>Improvements UIWidgets</summary>

      - **i ) Description:**<br><br>
      [UIWidget] Improvements in the UI algorithm, with that we had a better performance in >add, remove and reposition widgets, it is possible to see these improvements >through the battle module.<br><br>
   



      - **ii ) Video**


      https://github.com/kokekanon/otclient.readme/assets/114332266/eed1464a-ae4d-4cd6-9f22-c719b4f09766


    </details>
  - <details>
    <summary>Force Effect Optimization</summary>

      - **i ) Description :** will avoid drawing effects on certain occasions

    </details>
    
  - updated libraries


</details>

- <details>
   <summary>Auto Reload Module</summary>

   Activate `g_modules.enableAutoReload()`  ([init.lua](https://github.com/mehah/otclient/blob/main/init.lua#L114))


   https://github.com/kokekanon/otclient.readme/assets/114332266/0c382d93-6217-4efa-8f22-b51844801df4


</details>


- <details>
   <summary>Attached Effects System (to create aura, wings...)</summary>

    - Compatible with .Apng
      - ThingCategoryEffect
      - ThingCategoryCreature 
      - ThingExternalTexture: are images in Png | Apng

    - [Wiki](https://github.com/mehah/otclient/wiki/Tutorial-Attached-Effects)  

    - Example Code:
    (code sample: [effects.lua](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/effects.lua), [code test](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/attachedeffects.lua#L1))
    - Example specific settings for lookType X   [outfit_618.lua](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/configs/outfit_618.lua)

      - you have an AttachdEffect X, it has a standard offset, but in the daemon it's all skewed, so you use ThingConfig to adjust the effect specifically for the desired looktype.

</details>

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Attached%20Effect/Creature/001_Bone.gif?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Attached%20Effect/Creature/002_aura.gif?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Attached%20Effect/Creature/003_particula.gif?raw=true" width="250" alt="Space Invaders" style="max-width: 250px;"> |
|-------------------------------------------|---------------|-------------------------|
| ThingCategory Attached Effect | Texture(Png) Attached Effect | <center> Particule </center> |


- Floor Shadowing
- Highlight Mouse Target (press shift to select any object)
- Floor View Mode (Normal, Fade, Locked, Always, Always with transparency)
- Floating Effects Option
- Refactored Walk System
- Support for more mouse buttons, for example 4 and 5
- <details>
   <summary>Module Controller System</summary>

   a safer way to create modules, without the need to unbind keys, disconnect events, or destroy widgets.

    ([Code example](https://github.com/mehah/otclient/blob/cache-for-all/modules/game_minimap/minimap.lua))

</details>

- Client 12.85 ~ 12.92, 13.00 ~ 13.40 support (protobuf)
- Market has been rewritten compatible with tfs and canary
- Async Texture Loading
- <details>
    <summary>Anti-Aliasing Mode Options</summary>
  - note : (Note: Smooth Retro will consume a little more GPU)
  
  - **i ) Gif**
       ![vvff](https://github.com/kokekanon/otclient.readme/assets/114332266/5a411525-7d5a-4b16-8bb6-2c6462152d39)

     

</details>

- <details>
   <summary> Support Negative Offset (.dat)  </summary>
  
  - compatible with [ObjectBuilderV0.5.5](https://github.com/punkice3407/ObjectBuilder/releases/tag/v0.5.5)
  
   - need enable this feature:

      g_game.enableFeature(GameNegativeOffset)
     
   - Video

   https://github.com/kokekanon/otclient.readme/assets/114332266/16aaa78b-fc55-4c6e-ae63-7c4063c5b032


</details>

- <details>
   <summary>Creature Information By UIWidget</summary>
   
  - to enable: [setup.otml](https://github.com/mehah/otclient/blob/e2c5199e52bd86f573c9bb582d7548cfe7a8b026/data/setup.otml#L20)
  - To style: [modules/game_creatureinformation](https://github.com/mehah/otclient/tree/main/modules/game_creatureinformation)
  - Note: There is a performance degradation compared to direct programming with Draw Pool, by about ~20%, testing was performed with 60 monsters attacking each other.

  https://github.com/kokekanon/otclient.readme/assets/114332266/c2567f3f-136e-4e11-964f-3ade89c0056b


</details>

- Drawpool 3
- Tile Widget [Wiki](https://github.com/mehah/otclient/wiki/Tutorial-Attached-Effects)

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Attached%20Effect/Tile/001_attachedeffect.gif?raw=true" width="250" alt="Haskanoid Video" style="max-width:250px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Attached%20Effect/Tile/002_widget.png?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/raw/main/Picture/Attached%20Effect/Tile/003_particulas.gif?raw=true" width="310" alt="Space Invaders" style="max-width: 310px;"> |
|-------------------------------------------|---------------|-------------------------|
|<center>Title Attached Effect</center> | <center> Title Widget </center>| <center>Title Particule</center> |


- <details>
   <summary>Support HTML/CSS syntax</summary>
  
  https://github.com/user-attachments/assets/9f20814f-0aed-4b70-8852-334ac745ec11

  https://github.com/user-attachments/assets/3ac8473c-8e90-4639-b815-ef183c7e2adf
  
  Note: Module example:
   - [Shader](https://github.com/mehah/otclient/tree/main/modules/game_shaders)
   - [Blessing](https://github.com/mehah/otclient/pull/825)
</details>

- Support DirectX

- <details>
   <summary>Garbage Collection </summary>
  <br>
  Garbage collector is used to check what is no longer being used and remove it from memory. (lua, texture, drawpool, thingtype)
</details>



##### 🙋 Community (Features)
- Mobile Support [@tuliomagalhaes](https://github.com/tuliomagalhaes) & [@BenDol](https://github.com/BenDol) & [@SkullzOTS](https://github.com/SkullzOTS) 

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Android/001_ingame.png?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Android/001_interface.png?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Android/003_patrikq.jpg?raw=true" width="270" alt="Space Invaders" style="max-width: 270px;"> |
|-------------------------------------------|---------------|-------------------------|
| Interface | Density Pixel | Joystick (patrykq) |

- Support Tibia 12.85/protobuf by [@Nekiro](https://github.com/nekiro)


- <details>
   <summary>Support Discord RPC by @SkullzOTS (Doesn't work with CMAKE)</summary>

  - by [@SkullzOTS](https://github.com/SkullzOTS)

  - To enable just go to [config.h](https://github.com/mehah/otclient/blob/main/src/framework/config.h#L43), set 1 in ENABLE_DISCORD_RPC and configure the others definitions

  - You can see the step by step in [YouTube](https://www.youtube.com/watch?v=zCHYtRlD58g)

</details>

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Discord/001.png?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Discord/002_ingame.png?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Discord/003_future.png?raw=true" width="200" alt="Space Invaders" style="max-width: 200px;"> |
|-------------------------------------------|---------------|-------------------------|
| Example interface | Example in game | future discord-game-sdk  |


- Action Bar by [@DipSet](https://github.com/Dip-Set1)
- Access to widget children via widget.childId by [@Hugo0x1337](https://github.com/Hugo0x1337)
- Shader System Fix (CTRL + Y) by [@FreshyPeshy](https://github.com/FreshyPeshy)

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/001_creature.gif?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/003_map.gif?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/002_mount.gif?raw=true" width="200" alt="Space Invaders" style="max-width: 200px;"> |
|-------------------------------------------|---------------|-------------------------|
| Creature | Map | Mount |

- Refactored Battle Module by [@andersonfaaria](https://github.com/andersonfaaria)

- Health&Mana Circle by [@EgzoT](https://github.com/EgzoT), [@GustavoBlaze](https://github.com/GustavoBlaze), [@Tekadon58](https://github.com/Tekadon58) ([GITHUB Project](https://github.com/EgzoT/-OTClient-Mod-health_and_mana_circle))
- Tibia Theme 1.2 by Zews ([Forum Thread](https://otland.net/threads/otc-tibia-theme-v1-2.230988/))
- Add option ADJUST_CREATURE_INFORMATION_BASED_ON_CROP_SIZE in [config.h](https://github.com/mehah/otclient/blob/main/data/setup.otml#L24) by [@SkullzOTS](https://github.com/SkullzOTS)
- <details>
   <summary>Encryption System by @Mrpox (Note: This implementation is unsafe)</summary>
   
   by [@Mrpox](https://github.com/Mrpox)
    - To enable just go to [config.h](https://github.com/mehah/otclient/blob/main/src/framework/config.h#L33), set 1 in ENABLE_ENCRYPTION and change password on ENCRYPTION_PASSWORD
  - To enable Encrypting by "--encrypt" change ENABLE_ENCRYPTION_BUILDER to 1 (by [@TheMaoci](https://github.com/TheMaoci)). This allows to remove code of creating encrypted files off the production build
  - To generate an encryption, just run the client with flag "--encrypt SET_YOUR_PASSWORD_HERE" and don't forget to change the password.
  - you can also skip adding password to --encrypt command it automatically will be taken from [config.h](https://github.com/mehah/otclient/blob/main/src/framework/config.h#L38) file (by [@TheMaoci](https://github.com/TheMaoci))

</details>

- Support HTTP/HTTPS/WS/WSS. by [@alfuveam](https://github.com/alfuveam)
- <details>
   <summary>Client Updater by @conde2</summary>

  - by [@conde2](https://github.com/conde2)
  - Paste the API folder in your www folder (https://github.com/mehah/otclient/tree/main/tools/api)
  - Create a folder called "files" in your www folder and paste init.lua, modules, data, and exe files
  - Uncomment and change this line (https://github.com/mehah/otclient/blob/main/init.lua#L6)


</details>

- <details>
   <summary>Colored text @conde2</summary>

  - by [@conde2](https://github.com/conde2)
  - widget:setColoredText("{Colored text, #ff00ff} normal text")

</details>


- <details>
   <summary>QR Code support, with auto generate it from string [@conde2]</summary>

  - by [@conde2](https://github.com/conde2)
  - UIQrCode: 
    - code-border: 2
    - code: Hail OTClient Redemption - Conde2 Dev

</details>
  
- <details>
   <summary>Typing Icon by @SkullzOTS</summary>

  - by [@SkullzOTS](https://github.com/SkullzOTS)
  - To enable just go to [setup.otml](https://github.com/mehah/otclient/blob/main/data/setup.otml) and set draw-typing: true

</details>
<p align="center">
 <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/typing%20ico/001.gif?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> 

</p>

- <details>
   <summary>Smooth Walk Elevation Feature by @SkullzOTS</summary>

  - by [@SkullzOTS](https://github.com/SkullzOTS)
  - View Feature: [Gyazo](https://i.gyazo.com/af0ed0f15a9e4d67bd4d0b2847bd6be7.gif)
  - To enable just go to [modules/game_features/features.lua](https://github.com/mehah/otclient/blob/main/modules/game_features/features.lua#L5), and uncomment line 5 (g_game.enableFeature(GameSmoothWalkElevation)).

</details>
<p align="center">
 <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/smooth/001_smooth.gif?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> 

</p>

- Lua Debugger for VSCode [see wiki](https://github.com/mehah/otclient/wiki/Lua-Debugging-(VSCode)) [@BenDol](https://github.com/BenDol)
- Tutorial to Use OTC in TFS main [see wiki](https://github.com/mehah/otclient/wiki/Tutorial-to-Use-OTC-in-TFS-main)

- 3D Sound and Sound Effects! by [@Codinablack](https://github.com/codinablack)


| Example 1 | Example 2 | Example 3 |
|---------|---------|---------|
| <video src="https://github.com/kokekanon/otclient.readme/assets/114332266/4547907a-8eb9-42f5-b445-901cb5270509" width="200" controls></video> | <video src="https://github.com/kokekanon/otclient.readme/assets/114332266/0bb4739f-e902-4370-85dc-e796564aac8e" width="200" controls></video> | <video src="https://github.com/kokekanon/otclient.readme/assets/114332266/95db3fa1-a793-4ab7-86a3-e21a8543a23c" width="200" controls></video> |






- <details>
   <summary>Layout based on tibia 13 by @marcosvf132</summary>

  - by [@marcosvf132](https://github.com/marcosvf132)
  - Game_shop v8
  - Minimap WorldTime

    - tfs c++(old): `void ProtocolGame::sendWorldTime()`
    - tfs lua(new) : `function Player.sendWorldTime(self, time)`
    - Canary: `void ProtocolGame::sendTibiaTime(int32_t time)`

  - Outfit windows compatible with attachEffect , shader
    - Canary : 
    - 1.4.2 : 
      - https://github.com/kokekanon/TFS-1.4.2-Compatible-Aura-Effect-Wings-Shader-MEHAH/commit/77f80d505b01747a7c519e224d11c124de157a8f
    - Downgrade :
      - https://github.com/kokekanon/forgottenserver-downgrade/pull/2
      - https://github.com/kokekanon/forgottenserver-downgrade/pull/7
      - https://github.com/kokekanon/forgottenserver-downgrade/pull/9
  - Calendar
  - client_bottommenu (activate the array "Services.status" in init.lua)

  put this  
  `./otclient/tools/api/status.php` in your
  `C:/UniServerZ/www/api/` 

  if not work try ,active **curl**:



  ![image](https://github.com/Nottinghster/otclient/assets/114332266/99ad2ce7-d70f-47f4-aa19-083140fb5814)

  ![image](https://github.com/Nottinghster/otclient/assets/114332266/84349388-a458-4eb5-b1d6-cce5693cfd5a)


</details>


| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Layout%2013/001_interface.png?raw=true" width="300" alt="Haskanoid Video" style="max-width:300px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Layout%2013/002_ingame.png?raw=true" width="300" alt="Peoplemon by Alex Stuart" style="max-width: 300px;"> |
|-------------------------------------------|---------------|
|<center> Interface </center> | <center>In-game</center> |
- Imbuement tracker by [@Reyaleman](https://github.com/reyaleman)
- Blessing
- Screenshot
- Highscores
- Store (compatible with 13.32 - 13.40)
- QuickLoot
- Groups Vip

- <details>
   <summary>Browser Client by @OTArchive</summary>

  - by [@OTArchive](https://github.com/OTArchive)
  - wiki: https://github.com/OTArchive/otclient-web/wiki/Guia-%E2%80%90-OTClient-Redemption-Web
  
  - https://github.com/user-attachments/assets/e8ab58c7-1be3-4c76-bc6d-bd831e846826

</details>

##### 💸 Sponsored  (Features)
- Bot V8  ([@luanluciano93](https://github.com/luanluciano93), [@SkullzOTS](https://github.com/SkullzOTS), [@kokekanon](https://github.com/kokekanon), [@FranciskoKing](https://github.com/FranciskoKing), [@Kizuno18](https://github.com/Kizuno18))
  - Is adapted in 85%
  - To enable it, it is necessary to remove/off the BOT_PROTECTION flag.
  - [VS Solution](https://github.com/mehah/otclient/blob/68e4e1b94c2041bd235441244156e6477058250c/vc17/settings.props#L9) / [CMAKE](https://github.com/mehah/otclient/blob/68e4e1b94c2041bd235441244156e6477058250c/src/CMakeLists.txt#L13)

- Shader with Framebuffer  ([@SkullzOTS](https://github.com/SkullzOTS), [@Mryukiimaru](https://github.com/Mryukiimaru), [@JeanTheOne](https://github.com/JeanTheOne), [@KizaruHere](https://github.com/KizaruHere))

| <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/Framebuffer/001_creature.gif?raw=true" width="200" alt="Haskanoid Video" style="max-width:200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/Framebuffer/002_items.gif?raw=true" width="200" alt="Peoplemon by Alex Stuart" style="max-width: 200px;"> | <img src="https://github.com/kokekanon/OTredemption-Picture-NODELETE/blob/main/Picture/Shader/Framebuffer/003_UICreature.gif?raw=true" width="110" alt="Space Invaders" style="max-width: 110px;"> |
|-------------------------------------------|---------------|-------------------------|
| <center>Creature.</center> |<center> Items</center> |<center> UICreature </center> |

- Full Cyclopedia ([@luanluciano93](https://github.com/luanluciano93), [@kokekanon](https://github.com/kokekanon), [@MUN1Z](https://github.com/MUN1Z) ,[@qatari](https://github.com/qatari) )

##### [OTClient V8](https://github.com/OTCv8) (Features)
- Lighting System
- Floor Fading
- Path Finding
- Module Shop
- Module Oufit
- Placeholder
- UIGraph
- keybinds
  
## <a name="themobileproject"><img height="32" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/android/android.png" alt="Android"> The Mobile Project </a>
The Mobile Project
This is a fork of edubart's otclient. The objective of this fork it's to develop a runnable otclient on mobiles devices.

Tasks that need to do:
- [x] Compile on Android devices
- [ ] Compile on Apple devices
- [ ] Adapt the UI reusing the existing lua code

Current compiling tutorials:
* [Compiling for Android](https://github.com/mehah/otclient/wiki/Compiling-on-Android)


## <a name="compiling">🔨 Compiling</a>

[If you are interested in compiling this project, just go to the wiki.](https://github.com/mehah/otclient/wiki)



## <a name="docker">🐳 Docker</a>

In order to build the app for production, run the following command :

1) To build the image:
```bash
docker build -t mehah/otclient .
```
2) To run the built image:

```sh
# Disable access control for the X server.
xhost +

# Run the container image with the required bindings to the host devices and volumes.
docker run -it --rm \
  --env DISPLAY \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  --device /dev/dri \
  --device /dev/snd mehah/otclient /bin/bash

# Enable access control for the X server.
xhost -
```



## <a name="need-help?">🩺 Need help?</a>

Try to ask questions in [discord](https://discord.gg/HZN8yJJSyC)

## <a name="bugs">📑 Bugs?</a>

Have found a bug? Please create an issue in our [bug tracker](https://github.com/mehah/otclient/issues)

> \[!TIP]
>
> if using Nostalrius 7.2, Nekiro TFS-1.5-Downgrades-7.72 OR any protocol below 860 that the walking system is **stuttering**. set 
[force-new-walking-formula: true](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L21) in setup.otml
>
> In Old Protocol , if you consider that the speed of the item is too fast, modify [item-ticks-per-frame: 75](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L32)  in setup.otml

## <a name="roadmap">❤️ Roadmap</a>

| TO-DO list            	| Status                            	| PR   	|
|-----------------------	|-----------------------------------	|------	|
| Android compatibility 	| ![](https://geps.dev/progress/50) 	| [Branch](https://github.com/mehah/otclient/tree/mobile-working) 	|
| Familiar outfit       	| ![](https://geps.dev/progress/30) 	| [#39](https://github.com/Nottinghster/otclient/pull/39) 	|
| wheel of destiny            	| ![](https://geps.dev/progress/1) 	| None	|
| Forge            	| ![](https://geps.dev/progress/1) 	| None	|
| Analyzer              	| ![](https://geps.dev/progress/10)   |  [#802](https://github.com/mehah/otclient/pull/802)    	|
| fix: Extended view new-layout | ![](https://geps.dev/progress/0)   |   None   	|
| Sound tibia 13 | ![](https://geps.dev/progress/0)   |   None   	|

## <a name="supportprotocol">💯 Support Protocol</a>


| Protocol / version   	| Description                 	| Required Feature                                    	| Compatibility 	|
|---------------------	|-----------------------------	|-----------------------------------------------------	|---------------	|
| TFS <br> (7.72)      	| Downgrade nekiro /<br> Nostalrius 	|                  [force-new-walking-formula: true](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L21)        <br>   [item-ticks-per-frame: 75](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L32)                          	| ✅            	|
| TFS 0.4 <br> (8.6)       	| Fir3element                	|  [item-ticks-per-frame: 75](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L32)                                 	| ✅             	|
| TFS 1.5  <br> (8.0 / 8.60) 	| Downgrade nekiro / <br>MillhioreBT     	| [force-new-walking-formula: true](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L21)        <br>   [item-ticks-per-frame: 75](https://github.com/mehah/otclient/blob/cf7badda978de88cb3724615688e3d9da2ff4207/data/setup.otml#L32)        	| ✅             	|
| TFS 1.4.2 <br> (10.98)   	| Release Otland              	|                                              	| ✅             	|
| TFS 1.6  <br>(13.10)     	| Main repo <br> otland (2024)     	| [See wiki](https://github.com/mehah/otclient/wiki/Tutorial-to-Use-OTC-in-TFS-main) 	| ✅             	|
| Canary 13.21        	| OpenTibiaBr               	| [Assets , Enable HTTP login and port 80](https://docs.opentibiabr.com/opentibiabr/projects/otclient-redemption#how-to-connect-on-canary-with-otclient-redemption)            	| ✅             	|
| Canary 13.32        	| OpenTibiaBr              	| [Assets ,  Enable HTTP login and port 80](https://docs.opentibiabr.com/opentibiabr/projects/otclient-redemption#how-to-connect-on-canary-with-otclient-redemption)           	| ✅             	|
| Canary 13.40        	| OpenTibiaBr              	| [Assets ,  Enable HTTP login and port 80](https://docs.opentibiabr.com/opentibiabr/projects/otclient-redemption#how-to-connect-on-canary-with-otclient-redemption)           	| ✅             	|




## <a name="license">©️ License</a>

Otclient is made available under the MIT License [MIT License](http://opensource.org/licenses/MIT) .thus this means that you are free to do whatever you want, commercial, non-commercial, closed or open

## <a name="contributors">❤️ Contributors</a>

If you are interested in supporting the project, go to this [link](https://www.paypal.com/donate/?business=CV9D5JF8E46LY&no_recurring=0&item_name=Thank+you+very+much+for+your+donation.&currency_code=BRL), any value is great help, thank you.

