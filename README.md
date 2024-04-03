# OTCLient - Redemption
[![Discord Shield](https://discordapp.com/api/guilds/888062548082061433/widget.png?style=shield)](https://discord.gg/HZN8yJJSyC)
[![Build - Ubuntu](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml)
[![Build - Windows](https://github.com/mehah/otclient/actions/workflows/build-windows.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-windows.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

#### :heart:  If you are interested in supporting the project, go to this [link](https://www.paypal.com/donate/?business=CV9D5JF8E46LY&no_recurring=0&item_name=Thank+you+very+much+for+your+donation.&currency_code=BRL), any value is great help, thank you.

### Based on [edubart/otclient](https://github.com/edubart/otclient) Rev: [2.760](https://github.com/edubart/otclient/commit/fc39ee4adba8e780a2820bfda66fc942d74cedf4)

#### [Note: for those who are with the walking system stuttering...](https://github.com/mehah/otclient/blob/main/data/setup.otml#L18)

### Features

- C++20
- Refactored/Optimized Rendering System
- Auto Reload Module ([init.lua](https://github.com/mehah/otclient/blob/main/init.lua#L90))
- Attached Effects System (to create aura, wings...) (code sample: [effects.lua](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/effects.lua), [outfit_618.lua](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/configs/outfit_618.lua), [code test](https://github.com/mehah/otclient/blob/main/modules/game_attachedeffects/attachedeffects.lua#L1))
- Idle Animation Support
- Highlight Mouse Target (press shift to select any object)
- Crosshair
- Floor Shadowing
- Floor View Mode (Normal, Fade, Locked, Always, Always with transparency)
- Anti-Aliasing Mode Options (Note: Smooth Retro will consume a little more GPU)
- Floating Effects Option
- Optimized Terminal
- Refactored Walk System
- Support for more mouse buttons, for example 4 and 5
- Module Controller System ([Code example](https://github.com/mehah/otclient/blob/cache-for-all/modules/game_minimap/minimap.lua))
- Some bugs fixed contained in [edubart/otclient](https://github.com/edubart/otclient)
- Client 12.85 ~ 12.92, 13.00 ~ 13.21 support (protobuf)
- Market has been rewritten to work only [Canary](https://github.com/opentibiabr/canary)
- Async Texture Loading
- Tile Widget
- Creature Information By UIWidget
  - to enable: [setup.otml](https://github.com/mehah/otclient/blob/e2c5199e52bd86f573c9bb582d7548cfe7a8b026/data/setup.otml#L20)
  - To style: [modules/game_creatureinformation](https://github.com/mehah/otclient/tree/main/modules/game_creatureinformation)
  - Note: There is a performance degradation compared to direct programming with Draw Pool, by about ~20%, testing was performed with 60 monsters attacking each other.

##### Community (Features)
- Mobile Support [@tuliomagalhaes](https://github.com/tuliomagalhaes) & [@BenDol](https://github.com/BenDol)
- Support Tibia 12.85/protobuf by [@Nekiro](https://github.com/nekiro)
- Support Discord RPC by [@SkullzOTS](https://github.com/SkullzOTS) (Doesn't work with CMAKE)
- Action Bar by [@DipSet](https://github.com/Dip-Set1)
- Access to widget children via widget.childId by [@Hugo0x1337](https://github.com/Hugo0x1337)
- Shader System Fix (CTRL + Y) by [@FreshyPeshy](https://github.com/FreshyPeshy)
- Refactored Battle Module by [@andersonfaaria](https://github.com/andersonfaaria)
- Health&Mana Circle by [@EgzoT](https://github.com/EgzoT), [@GustavoBlaze](https://github.com/GustavoBlaze), [@Tekadon58](https://github.com/Tekadon58) ([GITHUB Project](https://github.com/EgzoT/-OTClient-Mod-health_and_mana_circle))
- Tibia Theme 1.2 by Zews ([Forum Thread](https://otland.net/threads/otc-tibia-theme-v1-2.230988/))
- Add option ADJUST_CREATURE_INFORMATION_BASED_ON_CROP_SIZE in [config.h](https://github.com/mehah/otclient/blob/cache-for-all/src/client/config.h) by [@SkullzOTS](https://github.com/SkullzOTS)
- Encryption System by [@Mrpox](https://github.com/Mrpox) (Note: This implementation is unsafe)
  - To enable just go to [config.h](https://github.com/mehah/otclient/blob/cache-for-all/src/client/config.h), set 1 in ENABLE_ENCRYPTION and change password on ENCRYPTION_PASSWORD
  - To enable Encrypting by "--encrypt" change ENABLE_ENCRYPTION_BUILDER to 1 (by [@TheMaoci](https://github.com/TheMaoci)). This allows to remove code of creating encrypted files off the production build
  - To generate an encryption, just run the client with flag "--encrypt SET_YOUR_PASSWORD_HERE" and don't forget to change the password.
  - you can also skip adding password to --encrypt command it automatically will be taken from [config.h](https://github.com/mehah/otclient/blob/cache-for-all/src/client/config.h) file (by [@TheMaoci](https://github.com/TheMaoci))
- Support HTTP/HTTPS/WS/WSS. by [@alfuveam](https://github.com/alfuveam)
- Discord RPC by [@SkullzOTS](https://github.com/SkullzOTS)
  - To enable just go to [config.h](https://github.com/mehah/otclient/blob/main/src/client/config.h), set 1 in ENABLE_DISCORD_RPC and configure the others definitions
  - You can see the step by step in [YouTube](https://www.youtube.com/watch?v=zCHYtRlD58g)
- Client Updater by [@conde2](https://github.com/conde2)
  - Paste the API folder in your www folder (https://github.com/mehah/otclient/tree/main/tools/api)
  - Create a folder called "files" in your www folder and paste init.lua, modules, data, and exe files
  - Uncomment and change this line (https://github.com/mehah/otclient/blob/main/init.lua#L6)
- Colored text [@conde2](https://github.com/conde2)
  - widget:setColoredText("{Colored text, #ff00ff} normal text")
- QR Code support, with auto generate it from string  [@conde2]
  - UIQrCode: 
    - code-border: 2
    - code: Hail OTClient Redemption - Conde2 Dev
- Typing Icon by [@SkullzOTS](https://github.com/SkullzOTS)
  - To enable just go to [setup.otml](https://github.com/mehah/otclient/blob/main/data/setup.otml) and set draw-typing: true
- Smooth Walk Elevation Feature by [@SkullzOTS](https://github.com/SkullzOTS)
  - View Feature: [Gyazo](https://i.gyazo.com/af0ed0f15a9e4d67bd4d0b2847bd6be7.gif)
  - To enable just go to [modules/game_features/features.lua](https://github.com/mehah/otclient/blob/main/modules/game_features/features.lua#L5), and uncomment line 5 (g_game.enableFeature(GameSmoothWalkElevation)).
- Lua Debugger for VSCode [see wiki](https://github.com/mehah/otclient/wiki/Lua-Debugging-(VSCode)) [@BenDol](https://github.com/BenDol)
  
##### Sponsored  (Features)
- Shader with Framebuffer | ([@SkullzOTS](https://github.com/SkullzOTS), [@Mryukiimaru](https://github.com/Mryukiimaru), [@JeanTheOne](https://github.com/JeanTheOne), [@KizaruHere](https://github.com/KizaruHere))
- Bot V8 | ([@luanluciano93](https://github.com/luanluciano93), [@SkullzOTS](https://github.com/SkullzOTS), [@kokekanon](https://github.com/kokekanon), [@FranciskoKing](https://github.com/FranciskoKing), [@Kizuno18](https://github.com/Kizuno18))
  - Is adapted in 85%
  - To enable it, it is necessary to remove/off the BOT_PROTECTION flag.
  - [VS Solution](https://github.com/mehah/otclient/blob/68e4e1b94c2041bd235441244156e6477058250c/vc17/settings.props#L9) / [CMAKE](https://github.com/mehah/otclient/blob/68e4e1b94c2041bd235441244156e6477058250c/src/CMakeLists.txt#L13)


##### [OTClient V8](https://github.com/OTCv8) (Features)
- Lighting System
- Floor Fading
- Path Finding
<h2>

```diff
- Want to help? Just open a PR.
```

   </h2>

### What is otclient?

Otclient is an alternative Tibia client for usage with otserv. It aims to be complete and flexible,
for that it uses LUA scripting for all game interface functionality and configurations files with a syntax
similar to CSS for the client interface design. Otclient works with a modular system, this means
that each functionality is a separated module, giving the possibility to users modify and customize
anything easily. Users can also create new mods and extend game interface for their own purposes.
Otclient is written in C++20 and heavily scripted in lua.

For a server to connect to, you can build your own with the [forgottenserver](https://github.com/otland/forgottenserver)
or [canary](https://github.com/opentibiabr/canary).

## The Mobile Project
This is a fork of edubart's otclient. The objective of this fork it's to develop a runnable otclient on mobiles devices.

Tasks that need to do:
- [X] Compile on Android devices
- [ ] Compile on Apple devices
- [ ] Adapt the UI reusing the existing lua code

Current compiling tutorials:
* [Compiling for Android](https://github.com/mehah/otclient/wiki/Compiling-on-Android)

### Where do I download?

Compiled for Windows can be found here (but can be outdated):

- [Windows Builds](https://github.com/mehah/otclient/releases)

**NOTE:** You will need to download spr/dat files on your own and place them in `data/things/VERSION/` (i.e: `data/things/1098/Tibia.spr`)

### Features

Beyond of it's flexibility with scripts, otclient comes with tons of other features that make possible
the creation of new client side stuff in otserv that was not possible before. These include,
sound system, graphics effects with shaders, modules/addons system, animated textures,
styleable user interface, transparency, multi language, in game lua terminal, an OpenGL 2.0 ES engine that make possible
to port to mobile platforms. Otclient is also flexible enough to
create tibia tools like map editors just using scripts, because it wasn't designed to be just a
client, instead otclient was designed to be a combination of a framework and tibia APIs.

### Compiling

[If you are interested in compiling this project, just go to the wiki.](https://github.com/mehah/otclient/wiki)

### Build and run with Docker

To build the image:

```sh
docker build -t mehah/otclient .
```

To run the built image:

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

### Need help?

Try to ask questions in [discord](https://discord.gg/HZN8yJJSyC)

### Bugs

Have found a bug? Please create an issue in our [bug tracker](https://github.com/mehah/otclient/issues)

### License

Otclient is made available under the MIT License, thus this means that you are free
to do whatever you want, commercial, non-commercial, closed or open.
