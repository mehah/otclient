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

#include "gameconfig.h"
#include <framework/otml/otml.h>
#include <framework/graphics/fontmanager.h>
#include <framework/core/resourcemanager.h>

GameConfig g_gameConfig;

GameConfig::GameConfig() :
    m_creatureNameFont(g_fonts.getDefaultFont()), m_animatedTextFont(g_fonts.getDefaultFont()),
    m_staticTextFont(g_fonts.getDefaultFont()), m_widgetTextFont(g_fonts.getDefaultFont()) {}

void GameConfig::init()
{
    try {
        const auto& file = g_resources.guessFilePath("/data/config", "otml");

        const auto& doc = OTMLDocument::parse(file);
        for (const auto& node : doc->children()) {
            if (node->tag() == "game") {
                loadGameNode(node);
            } else if (node->tag() == "font") {
                loadFontNode(node);
            }
        }
    } catch (const std::exception& e) {
        g_logger.error(stdext::format("Failed to read dat otml '%s': %s'", "data/config", e.what()));
    }
}

void GameConfig::terminate() {
    m_creatureNameFont = nullptr;
    m_animatedTextFont = nullptr;
    m_staticTextFont = nullptr;
    m_widgetTextFont = nullptr;
}

void GameConfig::loadFonts() {
    m_creatureNameFont = g_fonts.getFont(m_creatureNameFontName);
    m_animatedTextFont = g_fonts.getFont(m_animatedTextFontName);
    m_staticTextFont = g_fonts.getFont(m_staticTextFontName);
    m_widgetTextFont = g_fonts.getFont(m_widgetTextFontName);
}

void GameConfig::loadGameNode(const OTMLNodePtr& node) {
    for (const auto& node2 : node->children()) {
        if (node->tag() == "sprite-size")
            m_spriteSize = node->value<uint8_t>();
        else if (node->tag() == "last-supported-version")
            m_lastSupportedVersion = node->value<uint16_t>();
        else if (node->tag() == "map")
            loadMapNode(node);
        else if (node->tag() == "tile")
            loadTileNode(node);
        else if (node->tag() == "creature")
            loadCreatureNode(node);
        else if (node->tag() == "render")
            loadRenderNode(node);
    }
}

void GameConfig::loadFontNode(const OTMLNodePtr& node) {
    for (const auto& node2 : node->children()) {
        if (node->tag() == "widget")
            m_widgetTextFontName = node->value();
        else if (node->tag() == "static-text")
            m_staticTextFontName = node->value();
        else if (node->tag() == "animated-text")
            m_animatedTextFontName = node->value();
        else if (node->tag() == "creature-text")
            m_creatureNameFontName = node->value();
    }
}

void GameConfig::loadMapNode(const OTMLNodePtr& node) {
    for (const auto& node2 : node->children()) {
        if (node->tag() == "viewport")
            m_mapViewPort = node->value<uint8_t>();
        else if (node->tag() == "max-z")
            m_mapMaxZ = node->value<uint8_t>();
        else if (node->tag() == "sea-floor")
            m_mapSeaFloor = node->value<uint8_t>();
        else if (node->tag() == "underground-floor")
            m_mapUndergroundFloorRange = node->value<uint8_t>();
        else if (node->tag() == "aware-underground-floor-range")
            m_mapAwareUndergroundFloorRange = node->value<uint8_t>();
    }
}

void GameConfig::loadTileNode(const OTMLNodePtr& node) {
    if (node->tag() == "max-elevation")
        m_tileMaxElevation = node->value<uint8_t>();
    else if (node->tag() == "max-things")
        m_tileMaxThings = node->value<uint8_t>();
    else if (node->tag() == "transparent-floor-view-range")
        m_tileTransparentFloorViewRange = node->value<uint8_t>();
}

void GameConfig::loadCreatureNode(const OTMLNodePtr& node) {
    if (node->tag() == "force-new-walking-formula")
        m_forceNewWalkingFormula = node->value<bool>();
    else if (node->tag() == "shield-blink-ticks")
        m_shieldBlinkTicks = node->value<uint16_t>();
    else if (node->tag() == "volatile-square-duration")
        m_volatileSquareDuration = node->value<uint16_t>();
    else if (node->tag() == "adjust-creature-information-based-crop-size")
        m_adjustCreatureInformationBasedCropSize = node->value<bool>();
}

void GameConfig::loadRenderNode(const OTMLNodePtr& node) {
    if (node->tag() == "invisible-ticks-per-frame")
        m_invisibleTicksPerFrame = node->value<uint16_t>();
    else if (node->tag() == "item-ticks-per-frame")
        m_itemTicksPerFrame = node->value<uint16_t>();
    else if (node->tag() == "effect-ticks-per-frame")
        m_effectTicksPerFrame = node->value<uint16_t>();
    else if (node->tag() == "missile-ticks-per-frame")
        m_missileTicksPerFrame = node->value<uint16_t>();
    else if (node->tag() == "animated-text-duration")
        m_animatedTextDuration = node->value<uint16_t>();
    else if (node->tag() == "static-duration-per-character")
        m_staticDurationPerCharacter = node->value<uint16_t>();
    else if (node->tag() == "min-static-text-duration")
        m_minStatictextDuration = node->value<uint16_t>();
};