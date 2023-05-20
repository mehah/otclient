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

#include "spritemanager.h"
#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/image.h>
#include "game.h"
#include "spriteappearances.h"
#include <framework/core/graphicalapplication.h>

SpriteManager g_sprites;

void SpriteManager::init() { }
void SpriteManager::terminate() { unload(); }

void SpriteManager::reload() {
    if (g_app.isEncrypted())
        return;

    if (m_lastFileName.empty())
        return;

    if (m_spritesFile)
        m_spritesFile->close();

    m_spritesFile = g_resources.openFile(m_lastFileName);
    if (!g_app.isLoadingAsyncTexture())
        m_spritesFile->cache();
}

bool SpriteManager::loadSpr(std::string file)
{
    m_spritesCount = 0;
    m_signature = 0;
    m_loaded = false;
    try {
        m_lastFileName = g_resources.guessFilePath(file, "spr");
        m_spritesFile = g_resources.openFile(m_lastFileName);

        if (!g_app.isLoadingAsyncTexture())
            m_spritesFile->cache();

        if (g_app.isEncrypted()) {
            ResourceManager::decrypt(m_spritesFile->m_data.data(), m_spritesFile->m_data.size());
        }

        m_signature = m_spritesFile->getU32();
        m_spritesCount = g_game.getFeature(Otc::GameSpritesU32) ? m_spritesFile->getU32() : m_spritesFile->getU16();
        m_spritesOffset = m_spritesFile->tell();
        m_loaded = true;
        g_lua.callGlobalField("g_sprites", "onLoadSpr", file);
        return true;
    } catch (const stdext::exception& e) {
        g_logger.error(stdext::format("Failed to load sprites from '%s': %s", file, e.what()));
        return false;
    }
}

#ifdef FRAMEWORK_EDITOR
void SpriteManager::saveSpr(const std::string& fileName)
{
    if (!m_loaded)
        throw Exception("failed to save, spr is not loaded");

    try {
        const auto& fin = g_resources.createFile(fileName);
        if (!fin)
            throw Exception("failed to open file '%s' for write", fileName);

        fin->cache();

        fin->addU32(m_signature);
        if (g_game.getFeature(Otc::GameSpritesU32))
            fin->addU32(m_spritesCount);
        else
            fin->addU16(m_spritesCount);

        const uint32_t offset = fin->tell();
        uint32_t spriteAddress = offset + 4 * m_spritesCount;
        for (int i = 1; i <= m_spritesCount; ++i)
            fin->addU32(0);

        for (int i = 1; i <= m_spritesCount; ++i) {
            m_spritesFile->seek((i - 1) * 4 + m_spritesOffset);
            const uint32_t fromAdress = m_spritesFile->getU32();
            if (fromAdress != 0) {
                fin->seek(offset + (i - 1) * 4);
                fin->addU32(spriteAddress);
                fin->seek(spriteAddress);

                m_spritesFile->seek(fromAdress);
                fin->addU8(m_spritesFile->getU8());
                fin->addU8(m_spritesFile->getU8());
                fin->addU8(m_spritesFile->getU8());

                const uint16_t dataSize = m_spritesFile->getU16();
                fin->addU16(dataSize);
                char spriteData[SPRITE_DATA_SIZE];
                m_spritesFile->read(spriteData, dataSize);
                fin->write(spriteData, dataSize);

                spriteAddress = fin->tell();
            }
            //TODO: Check for overwritten sprites.
        }

        fin->flush();
        fin->close();
    } catch (const std::exception& e) {
        g_logger.error(stdext::format("Failed to save '%s': %s", fileName, e.what()));
    }
}
#endif

void SpriteManager::unload()
{
    m_spritesCount = 0;
    m_signature = 0;
    m_spritesFile = nullptr;
}

ImagePtr SpriteManager::getSpriteImage(int id)
{
    if (g_game.getClientVersion() >= 1281 && !g_game.getFeature(Otc::GameLoadSprInsteadProtobuf)) {
        return g_spriteAppearances.getSpriteImage(id);
    }

    if (g_app.isLoadingAsyncTexture())
        return getSpriteImage(id, g_resources.openFile(m_lastFileName));

    std::scoped_lock l(m_mutex);
    return getSpriteImage(id, m_spritesFile);
}

ImagePtr SpriteManager::getSpriteImage(int id, const FileStreamPtr& file) {
    if (id == 0 || !file)
        return nullptr;

    try {
        file->seek(((id - 1) * 4) + m_spritesOffset);

        const uint32_t spriteAddress = file->getU32();

        // no sprite? return an empty texture
        if (spriteAddress == 0)
            return nullptr;

        file->seek(spriteAddress);

        // skip color key
        file->getU8();
        file->getU8();
        file->getU8();

        const uint16_t pixelDataSize = file->getU16();

        const auto& image = std::make_shared<Image>(Size(g_gameConfig.getSpriteSize()));

        uint8_t* pixels = image->getPixelData();
        int writePos = 0;
        int read = 0;
        const bool useAlpha = g_game.getFeature(Otc::GameSpritesAlphaChannel);
        const uint8_t channels = useAlpha ? 4 : 3;
        // decompress pixels
        const uint16_t spriteDataSize = g_gameConfig.getSpriteSize() * g_gameConfig.getSpriteSize() * 4;

        while (read < pixelDataSize && writePos < spriteDataSize) {
            const uint16_t transparentPixels = file->getU16();
            const uint16_t coloredPixels = file->getU16();

            for (int i = 0; i < transparentPixels && writePos < spriteDataSize; ++i) {
                pixels[writePos + 0] = 0x00;
                pixels[writePos + 1] = 0x00;
                pixels[writePos + 2] = 0x00;
                pixels[writePos + 3] = 0x00;
                writePos += 4;
            }

            for (int i = 0; i < coloredPixels && writePos < spriteDataSize; ++i) {
                pixels[writePos + 0] = file->getU8();
                pixels[writePos + 1] = file->getU8();
                pixels[writePos + 2] = file->getU8();

                const uint8_t alphaColor = useAlpha ? file->getU8() : 0xFF;
                if (alphaColor != 0xFF)
                    image->setTransparentPixel(true);

                pixels[writePos + 3] = alphaColor;

                writePos += 4;
            }

            read += 4 + (channels * coloredPixels);
        }

        // Error margin for 4 pixel transparent
        if (!image->hasTransparentPixel() && writePos + 4 < spriteDataSize)
            image->setTransparentPixel(true);

        // fill remaining pixels with alpha
        while (writePos < spriteDataSize) {
            pixels[writePos + 0] = 0x00;
            pixels[writePos + 1] = 0x00;
            pixels[writePos + 2] = 0x00;
            pixels[writePos + 3] = 0x00;
            writePos += 4;
        }

        if (!image->hasTransparentPixel()) {
            // The image must be more than 4 pixels transparent to be considered transparent.
            uint8_t cntTrans = 0;
            for (const uint8_t pixel : image->getPixels()) {
                if (pixel == 0x00 && ++cntTrans > 4) {
                    image->setTransparentPixel(true);
                    break;
                }
            }
        }

        return image;
    } catch (const stdext::exception& e) {
        g_logger.error(stdext::format("Failed to get sprite id %d: %s", id, e.what()));
        return nullptr;
    }
}