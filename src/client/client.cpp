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
#include "game.h"
#include "map.h"
#include "uimap.h"
#include "minimap.h"
#include "spriteappearances.h"
#include "spritemanager.h"

#include <framework/ui/ui.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/asyncdispatcher.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/shadermanager.h>
#include <framework/graphics/image.h>

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
    m_mapWidget = nullptr;

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

void Client::preLoad() {
    if (m_mapWidget) {
        m_mapWidget->updateMapRect();
        m_mapWidget->getMapView()->preLoad();
    }
}

void Client::draw(DrawPoolType type)
{
    if (!g_game.isOnline()) {
        m_mapWidget = nullptr;
        return;
    }

    if (type == DrawPoolType::MAP && !m_mapWidget)
        m_mapWidget = g_ui.getRootWidget()->recursiveGetChildById("gameMapPanel")->static_self_cast<UIMap>();

    if (!m_mapWidget)
        return;

    if (type == DrawPoolType::FOREGROUND_MAP)
        g_textDispatcher.poll();

    m_mapWidget->draw(type);
}

bool Client::canDraw(DrawPoolType type) const
{
    switch (type) {
        case DrawPoolType::FOREGROUND:
            return true;

        case DrawPoolType::MAP:
        case DrawPoolType::CREATURE_INFORMATION:
        case DrawPoolType::FOREGROUND_MAP:
            return g_game.isOnline();

        case DrawPoolType::LIGHT:
            return g_game.isOnline() && m_mapWidget && m_mapWidget->isDrawingLights();

        default:
            return false;
    }
}

bool Client::isLoadingAsyncTexture()
{
    return g_game.isUsingProtobuf();
}

bool Client::isUsingProtobuf()
{
    return g_game.isUsingProtobuf();
}

void Client::onLoadingAsyncTextureChanged(bool /*loadingAsync*/)
{
    g_sprites.reload();
}

void Client::doMapScreenshot(std::string file)
{
    if (!m_mapWidget)
        return;

    if (file.empty()) {
        file = "map_screenshot.png";
    }

    g_mainDispatcher.addEvent([file, mapRect = m_mapWidget->m_mapRect] {
        const auto& resolution = mapRect.size();
        const auto width = resolution.width();
        const auto height = resolution.height();
        const auto& pixels = std::make_shared<std::vector<uint8_t>>(width * height * 4 * sizeof(GLubyte), 0);
        const auto ajustY = g_graphics.getViewportSize().height() - mapRect.size().height();
        const auto border = 8;

        glReadPixels(mapRect.x(), mapRect.y() + ajustY - border, width, height, GL_RGBA, GL_UNSIGNED_BYTE, (GLubyte*)(pixels->data()));

        g_asyncDispatcher.detach_task([resolution, pixels, file] {
            for (int line = 0, h = resolution.height(), w = resolution.width(); line != h / 2; ++line) {
                std::swap_ranges(
                    pixels->begin() + 4 * w * line,
                    pixels->begin() + 4 * w * (line + 1),
                    pixels->begin() + 4 * w * (h - line - 1));
            }
            for (auto i = 3; i < pixels->size(); i += 4) {
                (*pixels)[i] = 255; // set alpha to 255
            }
            try {
                Image image(resolution, 4, pixels->data());
                image.savePNG(file);
            } catch (stdext::exception& e) {
                g_logger.error(std::string("Can't do screenshot: ") + e.what());
            }
        });
    });
}