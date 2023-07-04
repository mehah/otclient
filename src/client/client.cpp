/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "client.h"
#include <framework/core/resourcemanager.h>
#include "game.h"
#include "map.h"
#include "minimap.h"
#include "shadermanager.h"
#include "spriteappearances.h"
#include "spritemanager.h"

Client g_client;

void Client::init(std::vector<std::string>& /*args*/)
{
    // register needed lua functions
    registerLuaFunctions();

    g_gameConfig.init();
    g_map.init();
    g_minimap.init();
    g_game.init();
    g_shaders.init();
    g_sprites.init();
    g_spriteAppearances.init();
    g_things.init();
}

void Client::terminate()
{
#ifdef FRAMEWORK_EDITOR
    g_creatures.terminate();
#endif
    g_game.terminate();
    g_map.terminate();
    g_minimap.terminate();
    g_things.terminate();
    g_sprites.terminate();
    g_spriteAppearances.terminate();
    g_shaders.terminate();
    g_gameConfig.terminate();
}