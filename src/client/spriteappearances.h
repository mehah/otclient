/*
 * Copyright (c) 2022 Nekiro <https://github.com/nekiro>
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

#pragma once

#include "gameconfig.h"
#include <framework/core/declarations.h>
#include <framework/graphics/declarations.h>
#include <framework/luaengine/luaobject.h>

enum class SpriteLayout
{
    ONE_BY_ONE = 0,
    ONE_BY_TWO = 1,
    TWO_BY_ONE = 2,
    TWO_BY_TWO = 3
};

class SpriteSheet
{
public:
    static constexpr uint16_t SIZE = 384;

    SpriteSheet(int firstId, int lastId, SpriteLayout spriteLayout, const std::string& file) : firstId(firstId), lastId(lastId), spriteLayout(spriteLayout), file(file) {}

    Size getSpriteSize() const
    {
        Size size(g_gameConfig.getSpriteSize(), g_gameConfig.getSpriteSize());

        switch (spriteLayout) {
            case SpriteLayout::ONE_BY_ONE: break;
            case SpriteLayout::ONE_BY_TWO: size.setHeight(64); break;
            case SpriteLayout::TWO_BY_ONE: size.setWidth(64); break;
            case SpriteLayout::TWO_BY_TWO: size.resize(64, 64); break;
            default: break;
        }

        return size;
    }

    // 64 pixel width == 6 columns each 64x or 32 pixels, 12 columns
    int getColumns() const { return SIZE / getSpriteSize().width(); }

    int firstId = 0;
    int lastId = 0;

    SpriteLayout spriteLayout = SpriteLayout::ONE_BY_ONE;
    std::mutex m_mutex;
    std::unique_ptr<uint8_t[]> data;
    std::string file;
};

//@bindsingleton g_spriteAppearances
class SpriteAppearances
{
public:
    void init();
    void terminate();

    void unload();

    void setSpritesCount(int count) { m_spritesCount = count; }
    int getSpritesCount() const { return m_spritesCount; }

    void setPath(const std::string& path) { m_path = path; }
    std::string getPath() const { return m_path; }

    bool loadSpriteSheet(const SpriteSheetPtr& sheet) const;
    void saveSheetToFileBySprite(int id, const std::string& file);
    void saveSheetToFile(const SpriteSheetPtr& sheet, const std::string& file);
    SpriteSheetPtr getSheetBySpriteId(int id, bool load = true);

    void addSpriteSheet(const SpriteSheetPtr& sheet) { m_sheets.emplace_back(sheet); }

    ImagePtr getSpriteImage(int id);
    void saveSpriteToFile(int id, const std::string& file);

private:
    uint32_t m_spritesCount{ 0 };
    std::vector<SpriteSheetPtr> m_sheets;
    std::string m_path;
};

extern SpriteAppearances g_spriteAppearances;
