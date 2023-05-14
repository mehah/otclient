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

#include <client/client.h>
#include <framework/core/application.h>
#include <framework/core/resourcemanager.h>
#include <framework/luaengine/luainterface.h>

#if ENABLE_DISCORD_RPC == 1
#include <framework/discord/discord.h>
#endif

#ifdef FRAMEWORK_NET
#include <framework/net/protocolhttp.h>
#endif

int main(int argc, const char* argv[])
{
    std::vector<std::string> args(argv, argv + argc);

    // setup application name and version
    g_app.setName("OTClient - Redemption");
    g_app.setCompactName("otclient");
    g_app.setOrganizationName("otbr");

    // process args encoding
    g_platform.init(args);

    // initialize resources
#ifdef ANDROID
    g_resources.init(nullptr);
#else
    g_resources.init(args[0].data());
#endif

#if ENABLE_ENCRYPTION == 1 && ENABLE_ENCRYPTION_BUILDER == 1
    if (std::find(args.begin(), args.end(), "--encrypt") != args.end()) {
        g_lua.init();
        g_resources.runEncryption(args.size() >= 3 ? args[2] : ENCRYPTION_PASSWORD);
        std::cout << "Encryption complete" << std::endl;
#ifdef WIN32
        MessageBoxA(NULL, "Encryption complete", "Success", 0);
#endif
        return 0;
    }
#endif

    if (g_resources.launchCorrect(args)) {
        return 0; // started other executable
    }

    // find script init.lua and run it
    if (!g_resources.discoverWorkDir("init.lua"))
        g_logger.fatal("Unable to find work directory, the application cannot be initialized.");

#if ENABLE_DISCORD_RPC == 1
    g_discord.init();
#endif

    // initialize application framework and otclient
    g_app.init(args, ASYNC_DISPATCHER_MAX_THREAD);
    g_client.init(args);
#ifdef FRAMEWORK_NET
    g_http.init();
#endif

#ifdef ANDROID
    // Unzip Android assets/data.zip
    g_androidManager.unZipAssetData();
#endif

    if (!g_lua.safeRunScript("init.lua"))
        g_logger.fatal("Unable to run script init.lua!");

    // the run application main loop
    g_app.run();

    // unload modules
    g_app.deinit();

    // terminate everything and free memory
    Client::terminate();
    g_app.terminate();
#ifdef FRAMEWORK_NET
    g_http.terminate();
#endif
    return 0;
}