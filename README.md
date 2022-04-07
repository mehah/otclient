# OpenTibiaBR - OTClient

[![Discord Channel](https://img.shields.io/discord/528117503952551936.svg?style=flat-square&logo=discord)](https://discord.gg/3NxYnyV)
[![GitHub issues](https://img.shields.io/github/issues/opentibiabr/otclient)](https://github.com/opentibiabr/otclient/issues)
[![GitHub pull request](https://img.shields.io/github/issues-pr/opentibiabr/otclient)](https://github.com/opentibiabr/otclient/pulls)
[![Contributors](https://img.shields.io/github/contributors/opentibiabr/otclient.svg?style=flat-square)](https://github.com/opentibiabr/otclient/graphs/contributors)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/opentibiabr/otclient/blob/develop/LICENSE)

![GitHub repo size](https://img.shields.io/github/repo-size/opentibiabr/otclient)

## Builds

[![Build - MacOS](https://github.com/opentibiabr/otclient/actions/workflows/build-macos.yml/badge.svg)](https://github.com/opentibiabr/otclient/actions/workflows/build-macos.yml)
[![Build - Ubuntu](https://github.com/opentibiabr/otclient/actions/workflows/build-ubuntu.yml/badge.svg)](https://github.com/opentibiabr/otclient/actions/workflows/build-ubuntu.yml)
[![Build - Windows](https://github.com/opentibiabr/otclient/actions/workflows/build-windows.yml/badge.svg)](https://github.com/opentibiabr/otclient/actions/workflows/build-windows.yml)

### Based on [mehah/otclient](https://github.com/mehah/otclient) Rev: [3.490](https://github.com/mehah/otclient/commit/c4433f3dba1e2790038495ab056848e3344190ac)

### Features

- C++20
- Refactored/Optimized Rendering System
- New Light System
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
- Module Controller System [Code example](https://github.com/mehah/otclient/blob/main/modules/game_minimap/minimap.lua)
- Some bugs fixed contained in [edubart/otclient](https://github.com/edubart/otclient)
- Client Config in [config.h](https://github.com/mehah/otclient/blob/main/src/client/config.h)

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

##### [Credits]
[@mehah](https://github.com/mehah) [@scopz](https://github.com/scopz)

### What is otclient?

Otclient is an alternative Tibia client for usage with otserv. It aims to be complete and flexible,
for that it uses LUA scripting for all game interface functionality and configurations files with a syntax
similar to CSS for the client interface design. Otclient works with a modular system, this means
that each functionality is a separated module, giving the possibility to users modify and customize
anything easily. Users can also create new mods and extend game interface for their own purposes.
Otclient is written in C++20 and heavily scripted in lua.

### Where do I download?

Compiled for MacOS, Ubuntu and Windows can be found here:
* [MacOS](https://github.com/opentibiabr/otclient/actions/workflows/build-macos.yml)
* [Ubuntu](https://github.com/opentibiabr/otclient/actions/workflows/build-ubuntu.yml)
* [Windows](https://github.com/opentibiabr/otclient/actions/workflows/build-windows.yml)

Compatible assets with [otservbr-global](https://github.com/opentibiabr/otservbr-global) and [canary](https://github.com/opentibiabr/canary):
* [Client 12.85](https://github.com/dudantas/tibia-client/archive/refs/heads/12.85.11525.zip)

**NOTE:** You will need to download all assets files on your own and place them in `data/things/1285/`.

### Compiling

In short, if you need to compile OTClient, follow these tutorials:
* [Compiling on Debian/Ubuntu](https://github.com/opentibiabr/otclient/wiki/Compiling-on-Debian-or-Ubuntu)
* [Compiling on Windows](https://github.com/opentibiabr/otclient/wiki/Compiling-on-Windows)

### Build and run with Docker

To build the image:

```sh
docker build -t opentibiabr/otclient .
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
  --device /dev/snd opentibiabr/otclient /bin/bash

# Enable access control for the X server.
xhost -
```

### Need help?

Try to ask questions in our [discord](https://discord.gg/3NxYnyV)

### Bugs

Have found a bug? Please create an issue in our [bug tracker](https://github.com/opentibiabr/otclient/issues)

### Contributing

We encourage you to contribute to otclient! You can make pull requests of any improvement in [pull requests](https://github.com/opentibiabr/otclient/pulls)

### Contact

[![Discord Channel](https://img.shields.io/discord/528117503952551936.svg?label=discord)](https://discord.gg/3NxYnyV)

### License

Otclient is made available under the MIT License, thus this means that you are free
to do whatever you want, commercial, non-commercial, closed or open.
