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

#include "discord.h"

#if ENABLE_DISCORD_RPC == 1
#include <client/game.h>
#include <client/localplayer.h>
#include <framework/core/eventdispatcher.h>
#include <time.h>

const static int64_t EP_TIME = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();

Discord g_discord;

void Discord::init()
{
    DiscordEventHandlers Handle;
    memset(&Handle, 0, sizeof(Handle));
    Discord_Initialize(RPC_API_KEY, &Handle, 1, NULL);
    update();
}

void Discord::update()
{
    std::string info;
    if (g_game.isOnline()) {
#if SHOW_CHARACTER_NAME_RPC == 1
        info = "Name: " + g_game.getCharacterName();
#endif

#if SHOW_CHARACTER_LEVEL_RPC == 1
        const auto& level = std::to_string(g_game.getLocalPlayer()->getLevel());
        info += info.empty() ? "Level: " + level : "[" + level + "]";
#endif

#if SHOW_CHARACTER_WORLD_RPC == 1
        if (!info.empty()) info += "\n";
        info += "World: " + g_game.getWorldName();
#endif
    } else {
        info = std::string{ OFFLINE_RPC_TEXT };
    }

    if (info.empty())
        info = "Adjust in config.h";

    DiscordRichPresence discordPresence;
    memset(&discordPresence, 0, sizeof(discordPresence));
    discordPresence.state = STATE_RPC_TEXT;
    discordPresence.details = info.c_str();
    discordPresence.startTimestamp = EP_TIME;
    discordPresence.endTimestamp = 0;
    discordPresence.largeImageKey = RPC_LARGE_IMAGE;
    discordPresence.largeImageText = RPC_LARGE_TEXT;
    Discord_UpdatePresence(&discordPresence);
    g_dispatcher.scheduleEvent([this] { update(); }, 30000);
}

#endif