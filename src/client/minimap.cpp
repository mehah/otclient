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

#include "minimap.h"
#include "tile.h"

#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/drawpool.h>
#include <framework/graphics/image.h>
#include <framework/graphics/texture.h>
#include <zlib.h>

Minimap g_minimap;

void MinimapBlock::clean()
{
    m_tiles.fill(MinimapTile());
    m_texture.reset();
    m_mustUpdate = false;
}

void MinimapBlock::update()
{
    if (!m_mustUpdate)
        return;

    if (m_image)
        m_image->resize(m_size);
    else
        m_image = new Image(m_size);

    bool shouldDraw = false;
    for (uint_fast8_t x = 0; x < MMBLOCK_SIZE; ++x) {
        for (uint_fast8_t y = 0; y < MMBLOCK_SIZE; ++y) {
            const uint8_t c = getTile(x, y).color;

            Color col = Color::alpha.rgba();
            if (c != UINT8_MAX) {
                col = Color::from8bit(c).rgba();
                shouldDraw = true;
            }
            m_image->setPixel(x, y, col);
        }
    }

    if (shouldDraw)
        if (m_texture)
            m_texture->updateImage(m_image);
        else
            m_texture = TexturePtr(new Texture(m_image, true));
    else
        m_texture.reset();

    m_mustUpdate = false;
}

void MinimapBlock::updateTile(int x, int y, const MinimapTile& tile)
{
    if (m_tiles[getTileIndex(x, y)].color != tile.color)
        m_mustUpdate = true;

    m_tiles[getTileIndex(x, y)] = tile;
}

void Minimap::init() {}
void Minimap::terminate() { clean(); }

void Minimap::clean()
{
    std::lock_guard lock(m_lock);
    for (uint_fast8_t i = 0; i <= MAX_Z; ++i)
        m_tileBlocks[i].clear();
}

void Minimap::draw(const Rect& screenRect, const Position& mapCenter, float scale, const Color& color)
{
    if (screenRect.isEmpty())
        return;

    const Rect& mapRect = calcMapRect(screenRect, mapCenter, scale);
    g_drawPool.addFilledRect(screenRect, color);

    if (MMBLOCK_SIZE * scale <= 1 || !mapCenter.isMapPosition()) {
        return;
    }

    const Point& blockOff = getBlockOffset(mapRect.topLeft());
    const Point& off = Point((mapRect.size() * scale).toPoint() - screenRect.size().toPoint()) / 2;
    const Point& start = screenRect.topLeft() - (mapRect.topLeft() - blockOff) * scale - off;

    const auto& oldClipRect = g_drawPool.getClipRect();
    g_drawPool.setClipRect(screenRect);
    for (int_fast32_t y = blockOff.y, ys = start.y; ys < screenRect.bottom(); y += MMBLOCK_SIZE, ys += MMBLOCK_SIZE * scale) {
        if (y < 0 || y >= 65536)
            continue;

        for (int_fast32_t x = blockOff.x, xs = start.x; xs < screenRect.right(); x += MMBLOCK_SIZE, xs += MMBLOCK_SIZE * scale) {
            if (x < 0 || x >= 65536)
                continue;

            Position blockPos(x, y, mapCenter.z);
            if (!hasBlock(blockPos))
                continue;

            MinimapBlock& block = getBlock(Position(x, y, mapCenter.z));
            block.update();

            const TexturePtr& tex = block.getTexture();
            if (tex) {
                Rect src(0, 0, MMBLOCK_SIZE, MMBLOCK_SIZE);
                Rect dest(Point(xs, ys), src.size() * scale);

                tex->setSmooth(scale < 1.0f);
                g_drawPool.addTexturedRect(dest, tex, src);
            }
        }
    }
    g_drawPool.setClipRect(oldClipRect);
}

Point Minimap::getTilePoint(const Position& pos, const Rect& screenRect, const Position& mapCenter, float scale)
{
    if (screenRect.isEmpty() || pos.z != mapCenter.z)
        return { -1 };

    const Rect mapRect = calcMapRect(screenRect, mapCenter, scale);
    const Point off = Point((mapRect.size() * scale).toPoint() - screenRect.size().toPoint()) / 2;
    const Point posoff = (Point(pos.x, pos.y) - mapRect.topLeft()) * scale;
    return posoff + screenRect.topLeft() - off + (Point(1) * scale) / 2;
}

Position Minimap::getTilePosition(const Point& point, const Rect& screenRect, const Position& mapCenter, float scale)
{
    if (screenRect.isEmpty())
        return {};

    const Rect mapRect = calcMapRect(screenRect, mapCenter, scale);
    const Point off = Point((mapRect.size() * scale).toPoint() - screenRect.size().toPoint()) / 2;
    const Point pos2d = (point - screenRect.topLeft() + off) / scale + mapRect.topLeft();
    return { pos2d.x, pos2d.y, mapCenter.z };
}

Rect Minimap::getTileRect(const Position& pos, const Rect& screenRect, const Position& mapCenter, float scale)
{
    if (screenRect.isEmpty() || pos.z != mapCenter.z)
        return {};

    const int tileSize = SPRITE_SIZE * scale;
    Rect tileRect(0, 0, tileSize, tileSize);
    tileRect.moveCenter(getTilePoint(pos, screenRect, mapCenter, scale));
    return tileRect;
}

Rect Minimap::calcMapRect(const Rect& screenRect, const Position& mapCenter, float scale)
{
    const int w = screenRect.width() / scale, h = std::ceil(screenRect.height() / scale);
    Rect mapRect(0, 0, w, h);
    mapRect.moveCenter(Point(mapCenter.x, mapCenter.y));
    return mapRect;
}

void Minimap::updateTile(const Position& pos, const TilePtr& tile)
{
    MinimapTile minimapTile;
    if (tile) {
        minimapTile.color = tile->getMinimapColorByte();
        minimapTile.flags |= MinimapTileWasSeen;
        if (!tile->isWalkable(true))
            minimapTile.flags |= MinimapTileNotWalkable;
        if (!tile->isPathable())
            minimapTile.flags |= MinimapTileNotPathable;
        minimapTile.speed = std::min<int>(static_cast<int>(std::ceil(tile->getGroundSpeed() / 10.f)), UINT8_MAX);
    } else {
        minimapTile.flags |= MinimapTileNotWalkable | MinimapTileNotPathable;
    }

    if (minimapTile != MinimapTile()) {
        MinimapBlock& block = getBlock(pos);
        const Point offsetPos = getBlockOffset(Point(pos.x, pos.y));
        block.updateTile(pos.x - offsetPos.x, pos.y - offsetPos.y, minimapTile);
        block.justSaw();
    }
}

const MinimapTile& Minimap::getTile(const Position& pos)
{
    static MinimapTile nulltile;
    if (pos.z <= MAX_Z && hasBlock(pos)) {
        MinimapBlock& block = getBlock(pos);
        const Point offsetPos = getBlockOffset(Point(pos.x, pos.y));
        return block.getTile(pos.x - offsetPos.x, pos.y - offsetPos.y);
    }
    return nulltile;
}

std::pair<MinimapBlock_ptr, MinimapTile> Minimap::threadGetTile(const Position& pos)
{
    std::lock_guard lock(m_lock);
    static MinimapTile nulltile;

    if (pos.z <= MAX_Z && hasBlock(pos)) {
        MinimapBlock_ptr block = m_tileBlocks[pos.z][getBlockIndex(pos)];
        if (block) {
            const Point offsetPos = getBlockOffset(Point(pos.x, pos.y));
            return std::make_pair(block, block->getTile(pos.x - offsetPos.x, pos.y - offsetPos.y));
        }
    }
    return std::make_pair(nullptr, nulltile);
}

bool Minimap::loadImage(const std::string& fileName, const Position& topLeft, float colorFactor)
{
    // non pathable colors
    static Color nonPathableColors[] = {
       "#ffff00"sv, // yellow
    };

    // non walkable colors
    static Color nonWalkableColors[] = {
       "#000000"sv, // oil, black
       "#006600"sv, // trees, dark green
       "#ff3300"sv, // walls, red
       "#666666"sv, // mountain, grey
       "#ff6600"sv, // lava, orange
       "#00ff00"sv, // positon
       "#ccffff"sv, // ice, very light blue
    };

    if (colorFactor <= .01f)
        colorFactor = 1.f;

    try {
        const ImagePtr image = Image::load(fileName);

        const uint8_t waterc = Color::to8bit("#3300cc"sv);

        for (int_fast32_t y = -1; ++y < image->getHeight();) {
            for (int_fast32_t x = -1; ++x < image->getWidth();) {
                Color color = *(uint32_t*)image->getPixel(x, y);
                uint8_t c = Color::to8bit(color * colorFactor);
                int flags = 0;

                if (c == waterc || color.a() == 0) {
                    flags |= MinimapTileNotWalkable;
                    c = UINT8_MAX; // alpha
                }

                if (flags != 0) {
                    for (Color& col : nonWalkableColors) {
                        if (col == color) {
                            flags |= MinimapTileNotWalkable;
                            break;
                        }
                    }
                }

                if (flags != 0) {
                    for (Color& col : nonPathableColors) {
                        if (col == color) {
                            flags |= MinimapTileNotPathable;
                            break;
                        }
                    }
                }

                if (c == UINT8_MAX)
                    continue;

                Position pos(topLeft.x + x, topLeft.y + y, topLeft.z);
                MinimapBlock& block = getBlock(pos);
                const Point offsetPos = getBlockOffset(Point(pos.x, pos.y));
                MinimapTile& tile = block.getTile(pos.x - offsetPos.x, pos.y - offsetPos.y);
                if (!(tile.flags & MinimapTileWasSeen)) {
                    tile.color = c;
                    tile.flags = flags;
                    block.mustUpdate();
                }
            }
        }
        return true;
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to load OTMM minimap: %s", e.what()));
        return false;
    }
}

void Minimap::saveImage(const std::string&, const Rect&)
{
    //TODO
}

bool Minimap::loadOtmm(const std::string& fileName)
{
    try {
        const FileStreamPtr fin = g_resources.openFile(fileName);
        if (!fin)
            stdext::throw_exception("unable to open file");

        fin->cache();

        const uint32_t signature = fin->getU32();
        if (signature != OTMM_SIGNATURE)
            stdext::throw_exception("invalid OTMM file");

        const uint16_t start = fin->getU16();
        const uint16_t version = fin->getU16();
        fin->getU32(); // flags

        switch (version) {
            case 1:
            {
                fin->getString(); // description
                break;
            }
            default:
                stdext::throw_exception("OTMM version not supported");
        }

        fin->seek(start);

        constexpr uint32_t blockSize = MMBLOCK_SIZE * MMBLOCK_SIZE * sizeof(MinimapTile);
        std::vector<uint8_t> compressBuffer(compressBound(blockSize));
        std::vector<uint8_t> decompressBuffer(blockSize);

        while (true) {
            Position pos;
            pos.x = fin->getU16();
            pos.y = fin->getU16();
            pos.z = fin->getU8();

            // end of file or file is corrupted
            if (!pos.isValid() || pos.z >= MAX_Z + 1)
                break;

            MinimapBlock& block = getBlock(pos);
            const uint16_t len = fin->getU16();
            fin->read(compressBuffer.data(), len);

            unsigned long destLen = blockSize;
            const int ret = uncompress(decompressBuffer.data(), &destLen, compressBuffer.data(), len);

            if (ret != Z_OK || destLen != blockSize)
                break;

            memcpy(reinterpret_cast<uint8_t*>(&block.getTiles()), decompressBuffer.data(), blockSize);
            block.mustUpdate();
            block.justSaw();
        }

        fin->close();
        return true;
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to load OTMM minimap: %s", e.what()));
        return false;
    }
}

void Minimap::saveOtmm(const std::string& fileName)
{
    try {
        stdext::timer saveTimer;

        const FileStreamPtr fin = g_resources.createFile(fileName);
        fin->cache();

        //TODO: compression flag with zlib
        const uint32_t flags = 0;

        // header
        fin->addU32(OTMM_SIGNATURE);
        fin->addU16(0); // data start, will be overwritten later
        fin->addU16(OTMM_VERSION);
        fin->addU32(flags);

        // version 1 header
        fin->addString("OTMM 1.0"); // description

        // go back and rewrite where the map data starts
        const uint32_t start = fin->tell();
        fin->seek(4);
        fin->addU16(start);
        fin->seek(start);

        constexpr uint32_t blockSize = MMBLOCK_SIZE * MMBLOCK_SIZE * sizeof(MinimapTile),
            COMPRESS_LEVEL = 3;
        std::vector<uint8_t> compressBuffer(compressBound(blockSize));

        for (uint_fast8_t z = 0; z <= MAX_Z; ++z) {
            for (auto& it : m_tileBlocks[z]) {
                const int index = it.first;
                MinimapBlock& block = *it.second;
                if (!block.wasSeen())
                    continue;

                const Position pos = getIndexPosition(index, z);
                fin->addU16(pos.x);
                fin->addU16(pos.y);
                fin->addU8(pos.z);

                unsigned long len = blockSize;
                const int ret = compress2(compressBuffer.data(), &len, (uint8_t*)&block.getTiles(), blockSize, COMPRESS_LEVEL);
                assert(ret == Z_OK);
                fin->addU16(len);
                fin->write(compressBuffer.data(), len);
            }
        }

        // end of file
        const Position invalidPos;
        fin->addU16(invalidPos.x);
        fin->addU16(invalidPos.y);
        fin->addU8(invalidPos.z);

        fin->flush();

        fin->close();
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to save OTMM minimap: %s", e.what()));
    }
}
