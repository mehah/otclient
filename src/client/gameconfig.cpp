/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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
#include <framework/core/resourcemanager.h>
#include <framework/graphics/fontmanager.h>
#include <framework/ini/ini.h>
#include <framework/util/color.h>
#include <sstream>
#include <iomanip>
#include <vector>

GameConfig g_gameConfig;

// Helper function to parse TTF font configuration
// Format: "path|size|stroke-width|stroke-color" or just "fontname" for bitmap fonts
static void loadTTFFont(const std::string& fontConfig, std::string& outFontName)
{
    // Check if it's a TTF configuration (contains .ttf or .otf)
    if (fontConfig.find(".ttf") == std::string::npos && fontConfig.find(".otf") == std::string::npos) {
        outFontName = fontConfig;
        return;
    }
    
    // Parse TTF configuration: path|size|stroke-width|stroke-color
    std::vector<std::string> parts;
    std::stringstream ss(fontConfig);
    std::string part;
    
    while (std::getline(ss, part, '|')) {
        part.erase(0, part.find_first_not_of(" \t"));
        part.erase(part.find_last_not_of(" \t") + 1);
        parts.push_back(part);
    }
    
    if (parts.empty()) {
        outFontName = fontConfig;
        return;
    }
    
    std::string fontPath = parts[0];
    int fontSize = parts.size() > 1 ? std::stoi(parts[1]) : 12;
    int strokeWidth = parts.size() > 2 ? std::stoi(parts[2]) : 0;
    Color strokeColor = parts.size() > 3 ? Color(parts[3]) : Color::black;
    
    if (g_fonts.importTTF(fontPath, fontSize, strokeWidth, strokeColor)) {
        std::string fontId = fontPath;
        size_t lastDot = fontId.find_last_of('.');
        if (lastDot != std::string::npos) fontId = fontId.substr(0, lastDot);
        size_t lastSlash = fontId.find_last_of("/\\");
        if (lastSlash != std::string::npos) fontId = fontId.substr(lastSlash + 1);
        
        fontId += "_" + std::to_string(fontSize);
        if (strokeWidth > 0) {
            std::ostringstream colorStream;
            colorStream << std::hex << std::setfill('0') 
                        << std::setw(2) << (int)strokeColor.r()
                        << std::setw(2) << (int)strokeColor.g()
                        << std::setw(2) << (int)strokeColor.b()
                        << std::setw(2) << (int)strokeColor.a();
            fontId += "_s" + std::to_string(strokeWidth) + "_" + colorStream.str();
        }
        
        outFontName = fontId;
        g_logger.info("Loaded TTF font: {} -> {}", fontConfig, fontId);
    } else {
        g_logger.error("Failed to load TTF font: {}", fontConfig);
        outFontName = fontConfig;
    }
}

void GameConfig::init()
{
    const std::string& fileName = "/data/setup";

    try {
        auto ini = INIDocument::parse(fileName);
        
        if (ini->hasSection("game"))
            loadGameSection(ini->getSection("game"));
        if (ini->hasSection("map"))
            loadMapSection(ini->getSection("map"));
        if (ini->hasSection("tile"))
            loadTileSection(ini->getSection("tile"));
        if (ini->hasSection("creature"))
            loadCreatureSection(ini->getSection("creature"));
        if (ini->hasSection("player"))
            loadPlayerSection(ini->getSection("player"));
        if (ini->hasSection("render"))
            loadRenderSection(ini->getSection("render"));
        if (ini->hasSection("font"))
            loadFontSection(ini->getSection("font"));
        
        g_logger.info("Loaded game configuration from INI file: {}", ini->getSource());
    } catch (const std::exception& e) {
        g_logger.error("Failed to load setup.ini file: {}", e.what());
        g_logger.warning("Using default configuration values.");
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

    if (m_widgetTextFont)
        g_fonts.setDefaultWidgetFont(m_widgetTextFont);
}

void GameConfig::loadGameSection(const INISectionPtr& section) {
    m_spriteSize = section->getInt("sprite-size", m_spriteSize);
    m_lastSupportedVersion = section->getInt("last-supported-version", m_lastSupportedVersion);
    m_drawTyping = section->getBool("draw-typing", m_drawTyping);
    m_typingIcon = section->get("typing-icon", m_typingIcon);
}

void GameConfig::loadMapSection(const INISectionPtr& section) {
    std::string viewport = section->get("viewport", "");
    if (!viewport.empty()) {
        std::istringstream iss(viewport);
        int w, h;
        iss >> w >> h;
        m_mapViewPort = Size(w, h);
    }
    m_mapMaxZ = section->getInt("max-z", m_mapMaxZ);
    m_mapSeaFloor = section->getInt("sea-floor", m_mapSeaFloor);
    m_mapUndergroundFloorRange = section->getInt("underground-floor", m_mapUndergroundFloorRange);
    m_mapAwareUndergroundFloorRange = section->getInt("aware-underground-floor-range", m_mapAwareUndergroundFloorRange);
}

void GameConfig::loadTileSection(const INISectionPtr& section) {
    m_tileMaxElevation = section->getInt("max-elevation", m_tileMaxElevation);
    m_tileMaxThings = section->getInt("max-things", m_tileMaxThings);
    m_tileTransparentFloorViewRange = section->getInt("transparent-floor-view-range", m_tileTransparentFloorViewRange);
}

void GameConfig::loadCreatureSection(const INISectionPtr& section) {
    m_drawInformationByWidget = section->getBool("draw-information-by-widget-beta", m_drawInformationByWidget);
    m_forceNewWalkingFormula = section->getBool("force-new-walking-formula", m_forceNewWalkingFormula);
    m_shieldBlinkTicks = section->getInt("shield-blink-ticks", m_shieldBlinkTicks);
    m_volatileSquareDuration = section->getInt("volatile-square-duration", m_volatileSquareDuration);
    m_adjustCreatureInformationBasedCropSize = section->getBool("adjust-creature-information-based-crop-size", m_adjustCreatureInformationBasedCropSize);
    m_useCropSizeForUIDraw = section->getBool("use-crop-size-for-ui-draw", m_useCropSizeForUIDraw);
    m_creatureDiagonalWalkSpeed = section->getDouble("diagonal-walk-speed", m_creatureDiagonalWalkSpeed);
}

void GameConfig::loadPlayerSection(const INISectionPtr& section) {
    m_playerDiagonalWalkSpeed = section->getDouble("diagonal-walk-speed", m_playerDiagonalWalkSpeed);
}

void GameConfig::loadRenderSection(const INISectionPtr& section) {
    m_drawCoveredThings = section->getBool("draw-covered-things", m_drawCoveredThings);
    m_invisibleTicksPerFrame = section->getInt("invisible-ticks-per-frame", m_invisibleTicksPerFrame);
    m_itemTicksPerFrame = section->getInt("item-ticks-per-frame", m_itemTicksPerFrame);
    m_effectTicksPerFrame = section->getInt("effect-ticks-per-frame", m_effectTicksPerFrame);
    m_missileTicksPerFrame = section->getInt("missile-ticks-per-frame", m_missileTicksPerFrame);
    m_animatedTextDuration = section->getInt("animated-text-duration", m_animatedTextDuration);
    m_staticDurationPerCharacter = section->getInt("static-duration-per-character", m_staticDurationPerCharacter);
    m_minStatictextDuration = section->getInt("min-static-text-duration", m_minStatictextDuration);
}

void GameConfig::loadFontSection(const INISectionPtr& section) {
    if (section->hasKey("widget"))
        loadTTFFont(section->get("widget"), m_widgetTextFontName);
    if (section->hasKey("static-text"))
        loadTTFFont(section->get("static-text"), m_staticTextFontName);
    if (section->hasKey("animated-text"))
        loadTTFFont(section->get("animated-text"), m_animatedTextFontName);
    if (section->hasKey("creature-text"))
        loadTTFFont(section->get("creature-text"), m_creatureNameFontName);
}