#include "game.h"
#include "discord.h"
#include "localplayer.h"
#include <framework/core/eventdispatcher.h>
#include <time.h>
#include <sstream>

static int64_t eptime = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
extern Game g_game;

void Discord::Initialize()
{
    DiscordEventHandlers Handle;
    memset(&Handle, 0, sizeof(Handle));
    Discord_Initialize(RPC_API_KEY, &Handle, 1, NULL);
    Update();
}

void Discord::Update()
{
    char* details;
    if (g_game.isOnline()) {
        std::ostringstream level;
        level << g_game.getLocalPlayer()->getLevel();
		std::string info = "Adjust in config.h";
#if SHOW_CHARACTER_NAME_RPC == 1 && SHOW_CHARACTER_LEVEL_RPC == 0 && SHOW_CHARACTER_WORLD_RPC == 0
		info = "Name: " + g_game.getCharacterName();
#elif SHOW_CHARACTER_NAME_RPC == 0 && SHOW_CHARACTER_LEVEL_RPC == 1 && SHOW_CHARACTER_WORLD_RPC == 0
		info = "Level: " + level.str();
#elif SHOW_CHARACTER_NAME_RPC == 0 && SHOW_CHARACTER_LEVEL_RPC == 0 && SHOW_CHARACTER_WORLD_RPC == 1
		info = "World: " + g_game.getWorldName();
#elif SHOW_CHARACTER_NAME_RPC == 1 && SHOW_CHARACTER_LEVEL_RPC == 1 && SHOW_CHARACTER_WORLD_RPC == 0
		info = "Name: " + g_game.getCharacterName() + " | Level: " + level.str();
#elif SHOW_CHARACTER_NAME_RPC == 1 && SHOW_CHARACTER_LEVEL_RPC == 0 && SHOW_CHARACTER_WORLD_RPC == 1
		info = "Name: " + g_game.getCharacterName() + " | World: " + g_game.getWorldName();
#elif SHOW_CHARACTER_NAME_RPC == 0 && SHOW_CHARACTER_LEVEL_RPC == 1 && SHOW_CHARACTER_WORLD_RPC == 1
		info = "Level: " + level.str() + " | World: " + g_game.getWorldName();
#elif SHOW_CHARACTER_NAME_RPC == 1 && SHOW_CHARACTER_LEVEL_RPC == 1 && SHOW_CHARACTER_WORLD_RPC == 1
        info = g_game.getCharacterName() + " [" + level.str() + "] " + " | World: " + g_game.getWorldName();
#endif
        details = const_cast<char*>(info.c_str());
    }
    else {
        std::string notOnlineMsg = OFFLINE_RPC_TEXT;
        details = const_cast<char*>(notOnlineMsg.c_str());
    }

    DiscordRichPresence discordPresence;
    memset(&discordPresence, 0, sizeof(discordPresence));
    discordPresence.state = STATE_RPC_TEXT;
    discordPresence.details = details;
    discordPresence.startTimestamp = eptime;
    discordPresence.endTimestamp = NULL;
    discordPresence.largeImageKey = RPC_LARGE_IMAGE;
    discordPresence.largeImageText = RPC_LARGE_TEXT;
    Discord_UpdatePresence(&discordPresence);
    g_dispatcher.scheduleEvent([this] {Update(); }, 30000);
}