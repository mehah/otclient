# OTCLient - Redemption
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs)
[![Discord Shield](https://discordapp.com/api/guilds/888062548082061433/widget.png?style=shield)](https://discord.gg/HZN8yJJSyC)
[![Build - Ubuntu](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-ubuntu.yml)
[![Build - Windows](https://github.com/mehah/otclient/actions/workflows/build-windows.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-windows.yml)

#### :heart:  If you are interested in supporting the project, go to this [link](https://www.paypal.com/donate/?business=CV9D5JF8E46LY&no_recurring=0&item_name=Thank+you+very+much+for+your+donation.&currency_code=BRL), any value is great help, thank you.

### Based on [edubart/otclient](https://github.com/edubart/otclient) Rev: [2.760](https://github.com/edubart/otclient/commit/fc39ee4adba8e780a2820bfda66fc942d74cedf4)


### Features

- C++20
- Refactored/Optimized Rendering System
- New Light System
- Auto Reload Module (Set true in [init.lua](https://github.com/mehah/otclient/blob/1026132e3dfa661807a1ff10ced2f4e09f1b7a7d/init.lua#L4) to enable)
- Idle Animation Support
- Highlight Mouse Target (press shift to select any object)
- Crosshair
- Floor Shadowing
- Floor View Mode (Normal, Fade, Locked, Always, Always with transparency)
- Anti-Aliasing Mode Options (Note: Smooth Retro will consume a little more GPU)
- Floating Effects Option
- Adjusted Path Finding
- Optimized Terminal
- Refactored Walk System
- Support for more mouse buttons, for example 4 and 5
- Module Controller System ([Code example](https://github.com/mehah/otclient/blob/cache-for-all/modules/game_minimap/minimap.lua))
- Some bugs fixed contained in [edubart/otclient](https://github.com/edubart/otclient)
- Client Config in [config.h](https://github.com/mehah/otclient/blob/cache-for-all/src/client/config.h)
- Client 12.85 - 12.92 support (protobuf)

##### Community (Features)
- Support Tibia 12.85/protobuf by [@Nekiro](https://github.com/nekiro)
- Floor Fading by [@Kondra](https://github.com/OTCv8)
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

 - Support HTTP/HTTPS/WS/WSS. Based on [@Kondra](https://github.com/OTCv8/otcv8-dev) make by [@alfuveam](https://github.com/alfuveam)

##### [Active Developers]
[@mehah](https://github.com/mehah) [@scopz](https://github.com/scopz) [@nekiro](https://github.com/nekiro)

<h2>

```diff
- Want to help? Just open a PR.
```

   </h2>

[![Build Status](https://github.com/mehah/otclient/actions/workflows/build-vcpkg.yml/badge.svg)](https://github.com/mehah/otclient/actions/workflows/build-vcpkg.yml) [![Join the chat at https://gitter.im/mehah/otclient](https://img.shields.io/badge/GITTER-join%20chat-green.svg)](https://gitter.im/mehah/otclient?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Open Source Helpers](https://www.codetriage.com/mehah/otclient/badges/users.svg)](https://www.codetriage.com/mehah/otclient)

### What is otclient?

Otclient is an alternative Tibia client for usage with otserv. It aims to be complete and flexible,
for that it uses LUA scripting for all game interface functionality and configurations files with a syntax
similar to CSS for the client interface design. Otclient works with a modular system, this means
that each functionality is a separated module, giving the possibility to users modify and customize
anything easily. Users can also create new mods and extend game interface for their own purposes.
Otclient is written in C++20 and heavily scripted in lua.

For a server to connect to, you can build your own with the [forgottenserver](https://github.com/otland/forgottenserver)
or connect to one listed on [otservlist](https://otservlist.org/).#

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
styleable user interface, transparency, multi language, in game lua terminal, an OpenGL 1.1/2.0 ES engine that make possible
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

Try to ask questions in [otland](http://otland.net/f494/), now we have a board for the project there,
or talk with us at the gitter chat.

### Bugs

Have found a bug? Please create an issue in our [bug tracker](https://github.com/mehah/otclient/issues)

### License

Otclient is made available under the MIT License, thus this means that you are free
to do whatever you want, commercial, non-commercial, closed or open.
