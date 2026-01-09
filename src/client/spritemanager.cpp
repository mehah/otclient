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

#include "spritemanager.h"

#include "game.h"
#include "gameconfig.h"
#include "framework/core/asyncdispatcher.h"
#include "framework/core/filestream.h"
#include "framework/core/graphicalapplication.h"
#include "framework/core/resourcemanager.h"
#include "framework/graphics/image.h"

#include <nlohmann/json_fwd.hpp>
#include "lzma.h"

// warnings related to protobuf
// https://android.googlesource.com/platform/external/protobuf/+/brillo-m9-dev/vsprojects/readme.txt

FileMetadata::FileMetadata(const FileStreamPtr& file) {
    offset = file->getU32();
    fileSize = file->getU32();
    fileName = file->getString();
    spriteId = std::stoi(fileName);
}

void LegacySpriteManager::reload() {
    if (g_app.isEncrypted())
        return;

    if (m_lastFileName.empty())
        return;

    load();
}

void LegacySpriteManager::load() {
    m_spritesFiles.resize(g_asyncDispatcher.get_thread_count());
    if (g_app.isLoadingAsyncTexture()) {
        for (auto& file : m_spritesFiles)
            file = std::make_unique<FileStream_m>(g_resources.openFile(m_lastFileName));
    } else (m_spritesFiles[0] = std::make_unique<FileStream_m>(g_resources.openFile(m_lastFileName)))->file->cache(true);
}

bool LegacySpriteManager::loadSpr(std::string file)
{
    m_spritesCount = 0;
    m_signature = 0;
    m_loaded = false;
    m_spritesHd = false;

    const auto cwmFile = g_resources.guessFilePath(file, "cwm");
    if (g_resources.fileExists(cwmFile)) {
        m_spritesHd = true;
        return loadCwmSpr(cwmFile);
    }

    const auto sprFile = g_resources.guessFilePath(file, "spr");
    if (g_resources.fileExists(sprFile)) {
        return loadRegularSpr(sprFile);
    }

    return false;
}

bool LegacySpriteManager::loadRegularSpr(std::string file)
{
    try {
        m_lastFileName = g_resources.guessFilePath(file, "spr");
        load();

        m_signature = getSpriteFile()->getU32();
        m_spritesCount = g_game.getFeature(Otc::GameSpritesU32) ? getSpriteFile()->getU32() : getSpriteFile()->getU16();
        m_spritesOffset = getSpriteFile()->tell();

        m_loaded = true;
        g_lua.callGlobalField("g_sprites", "onLoadSpr", file);
        return true;
    } catch (const stdext::exception& e) {
        g_logger.error("Failed to load sprites from '{}': {}", file, e.what());
        return false;
    }
}

bool LegacySpriteManager::loadCwmSpr(std::string file)
{
    m_cwmSpritesMetadata.clear();

    if (g_gameConfig.getSpriteSize() <= 32) {
        g_logger.error("Change your sprite size to 64x64 or larger for CWM support '{}'", file);
        return false;
    }

    try {
        m_lastFileName = g_resources.guessFilePath(file, "cwm");
        load();

        const auto& spritesFile = getSpriteFile();

        const uint8_t version = spritesFile->getU8();
        if (version != 0x01) {
            g_logger.error("Invalid CWM file version - {}", file);
            return false;
        }

        m_spritesCount = spritesFile->getU16();

        const uint32_t entries = spritesFile->getU32();
        m_cwmSpritesMetadata.reserve(entries);
        for (uint32_t i = 0; i < entries; ++i) {
            FileMetadata spriteMetadata{ spritesFile };
            m_cwmSpritesMetadata[spriteMetadata.getSpriteId()] = std::move(spriteMetadata);
        }

        m_spritesOffset = spritesFile->tell();

        if (m_spritesCount == 0) {
            g_logger.error("Failed to load sprites from '{}' - no sprites", file);
            return false;
        }

        m_loaded = true;
        g_lua.callGlobalField("g_sprites", "onLoadCWMSpr", file);
        return true;
    } catch (stdext::exception& e) {
        g_logger.error("Failed to load sprites from '{}': {}", file, e.what());
        return false;
    }
}

#ifdef FRAMEWORK_EDITOR
void LegacySpriteManager::saveSpr(const std::string& fileName)
{
    if (!m_loaded)
        throw Exception("failed to save, spr is not loaded");

    static constexpr uint32_t SPRITE_SIZE = 32;
    static constexpr uint32_t SPRITE_DATA_SIZE = SPRITE_SIZE * SPRITE_SIZE * 4;

    try {
        const auto& fin = g_resources.createFile(fileName);
        if (!fin)
            throw Exception("failed to open file '{}' for write", fileName);

        fin->cache();

        fin->addU32(m_signature);
        if (g_game.getFeature(Otc::GameSpritesU32))
            fin->addU32(m_spritesCount);
        else
            fin->addU16(m_spritesCount);

        const uint32_t offset = fin->tell();
        uint32_t spriteAddress = offset + 4 * m_spritesCount;
        for (uint_fast32_t i = 1; i <= m_spritesCount; ++i)
            fin->addU32(0);

        for (uint_fast32_t i = 1; i <= m_spritesCount; ++i) {
            getSpriteFile()->seek((i - 1) * 4 + m_spritesOffset);
            const uint32_t fromAdress = getSpriteFile()->getU32();
            if (fromAdress != 0) {
                fin->seek(offset + (i - 1) * 4);
                fin->addU32(spriteAddress);
                fin->seek(spriteAddress);

                getSpriteFile()->seek(fromAdress);
                fin->addU8(getSpriteFile()->getU8());
                fin->addU8(getSpriteFile()->getU8());
                fin->addU8(getSpriteFile()->getU8());

                const uint16_t dataSize = getSpriteFile()->getU16();
                fin->addU16(dataSize);
                char spriteData[SPRITE_DATA_SIZE];
                getSpriteFile()->read(spriteData, dataSize);
                fin->write(spriteData, dataSize);

                spriteAddress = fin->tell();
            }
            //TODO: Check for overwritten sprites.
        }

        fin->flush();
        fin->close();
    } catch (const std::exception& e) {
        g_logger.error("Failed to save '{}': {}", fileName, e.what());
    }
}
#endif

ImagePtr LegacySpriteManager::getSpriteImage(const int id, bool& isLoading)
{
    const auto threadId = g_app.isLoadingAsyncTexture() ? stdext::getThreadId() : 0;
    if (const auto& sf = m_spritesFiles[threadId % m_spritesFiles.size()]) {
        if (sf->m_loadingState.exchange(SpriteLoadState::LOADING, std::memory_order_acq_rel) == SpriteLoadState::LOADING) {
            isLoading = true;
            return nullptr;
        }

        auto image = m_spritesHd ? getSpriteImageHd(id, sf->file) : getSpriteImage(id, sf->file);

        sf->m_loadingState.store(SpriteLoadState::LOADED, std::memory_order_release);

        return image;
    }

    return nullptr;
}

ImagePtr LegacySpriteManager::getSpriteImageHd(const int id, const FileStreamPtr& file)
{
    const auto it = m_cwmSpritesMetadata.find(id);
    if (it == m_cwmSpritesMetadata.end())
        return nullptr;

    const auto& metadata = it->second;

    std::string buffer(metadata.getFileSize(), 0);

    file->seek(m_spritesOffset + metadata.getOffset());
    file->read(buffer.data(), metadata.getFileSize());

    return Image::loadPNG(buffer.data(), buffer.size());
}

uint16_t readU16FromBuffer(const uint8_t* data, size_t& offset) {
    uint16_t val = data[offset] | (data[offset + 1] << 8);
    offset += 2;
    return val;
}

ImagePtr LegacySpriteManager::getSpriteImage(const int id, const FileStreamPtr& file)
{
    if (id == 0 || !file)
        return nullptr;

    try {
        file->seek(((id - 1) * 4) + m_spritesOffset);
        const uint32_t spriteAddress = file->getU32();
        if (spriteAddress == 0)
            return nullptr;

        file->seek(spriteAddress);
        file->skip(3); // Skip RGB color key

        const uint16_t pixelDataSize = file->getU16();
        const int spriteSize = g_gameConfig.getSpriteSize();
        const int totalPixels = spriteSize * spriteSize;
        const int maxWriteSize = totalPixels * 4;

        const bool useAlpha = g_game.getFeature(Otc::GameSpritesAlphaChannel);
        const uint8_t channels = useAlpha ? 4 : 3;

        static thread_local std::vector<uint8_t> spriteBuffer;
        spriteBuffer.resize(pixelDataSize);
        file->read(spriteBuffer.data(), pixelDataSize);

        size_t offset = 0;
        auto image = std::make_shared<Image>(Size(spriteSize));
        uint8_t* pixels = image->getPixelData();
        int writePos = 0;
        bool hasAlpha = false;
        int transparentCount = 0;

        static constexpr int MAX_PIXEL_BLOCK = 4096;
        static thread_local uint8_t tempBuffer[MAX_PIXEL_BLOCK * 4];

        while (offset + 4 <= pixelDataSize && writePos < maxWriteSize) {
            const uint16_t transparentPixels = readU16FromBuffer(spriteBuffer.data(), offset);
            const uint16_t coloredPixels = readU16FromBuffer(spriteBuffer.data(), offset);

            transparentCount += transparentPixels;

            const int transparentBytes = transparentPixels * 4;
            if (writePos + transparentBytes > maxWriteSize)
                break;

            std::memset(pixels + writePos, 0, transparentBytes);
            writePos += transparentBytes;

            const int actualColoredPixels = (coloredPixels > MAX_PIXEL_BLOCK) ? MAX_PIXEL_BLOCK : coloredPixels;
            const int bytesToRead = actualColoredPixels * channels;

            if (offset + bytesToRead > pixelDataSize)
                break;

            std::memcpy(tempBuffer, spriteBuffer.data() + offset, bytesToRead);
            offset += bytesToRead;

            if (useAlpha) {
                setPixelsRGBA(pixels, tempBuffer, writePos, actualColoredPixels, maxWriteSize, hasAlpha, transparentCount);
            } else {
                setPixelsRGB(pixels, tempBuffer, writePos, actualColoredPixels, maxWriteSize);
            }
        }

        if (writePos < maxWriteSize) {
            std::memset(pixels + writePos, 0, maxWriteSize - writePos);
            transparentCount += maxWriteSize - writePos;
        }

        if (hasAlpha || transparentCount > 4)
            image->setTransparentPixel(true);

        return image;
    } catch (const stdext::exception& e) {
        g_logger.error("Failed to get sprite id {}: {}", id, e.what());
        return nullptr;
    }
}

void LegacySpriteManager::setPixelsRGB(uint8_t* pixels, const uint8_t* tempBuffer, int& writePos, const int actualColoredPixels, const int maxWriteSize)
{
    for (int i = 0, src = 0; i < actualColoredPixels && writePos + 4 <= maxWriteSize; ++i, src += 3) {
        pixels[writePos + 0] = tempBuffer[src + 0];
        pixels[writePos + 1] = tempBuffer[src + 1];
        pixels[writePos + 2] = tempBuffer[src + 2];
        pixels[writePos + 3] = 0xFF;
        writePos += 4;
    }
}

void LegacySpriteManager::setPixelsRGBA(uint8_t* pixels, const uint8_t* tempBuffer, int& writePos, const int actualColoredPixels, const int maxWriteSize, bool& hasAlpha, int& transparentCount)
{
    for (int i = 0, src = 0; i < actualColoredPixels && writePos + 4 <= maxWriteSize; ++i, src += 4) {
        pixels[writePos + 0] = tempBuffer[src + 0];
        pixels[writePos + 1] = tempBuffer[src + 1];
        pixels[writePos + 2] = tempBuffer[src + 2];
        const uint8_t alpha = tempBuffer[src + 3];
        pixels[writePos + 3] = alpha;

        if (alpha != 0xFF) hasAlpha = true;
        else if (transparentCount <= 4 && alpha == 0x00) ++transparentCount;

        writePos += 4;
    }
}

using json = nlohmann::json;

Size SpriteSheet::getSpriteSize() const
{    
    // this array includes all possible combinations within 384x384 sheet
    // if you intend to change that, you will also have to modify the assets editor
    // CHANGING THIS MAY BREAK READING EXISTING SPRITESHEETS

    // tile sizes in spritesheets, see SpriteLayout for array key definitions
    static const std::array<Size, 36> sizes = {
        Size(32,32),  // 0
        Size(32,64),  // 1
        Size(64,32),  // 2
        Size(64,64),  // 3
        Size(32,96),  // 4
        Size(32,128), // 5
        Size(32,192), // 6
        Size(32,384), // 7
        Size(64,96),  // 8
        Size(64,128), // 9
        Size(64,192), // 10
        Size(64,384), // 11
        Size(96,32),  // 12
        Size(96,64),  // 13
        Size(96,96),  // 14
        Size(96,128), // 15
        Size(96,192), // 16
        Size(96,384), // 17
        Size(128,32),  // 18
        Size(128,64),  // 19
        Size(128,96),  // 20
        Size(128,128), // 21
        Size(128,192), // 22
        Size(128,384), // 23
        Size(192,32),  // 24
        Size(192,64),  // 25
        Size(192,96),  // 26
        Size(192,128), // 27
        Size(192,192), // 28
        Size(192,384), // 29
        Size(384,32),  // 30
        Size(384,64),  // 31
        Size(384,96),  // 32
        Size(384,128), // 33
        Size(384,192), // 34
        Size(384,384)  // 35
    };

    if (const auto idx = static_cast<size_t>(spriteLayout); idx < sizes.size())
        return sizes[idx];

    return sizes[0];
}

int SpriteSheet::getSpritesPerSheet() const
{
    const Size& size = getSpriteSize();
    const int spritesPerColumn = SpriteSheet::SIZE / size.height();

    return getColumns() * spritesPerColumn;
}

bool ProtobufSpriteManager::loadSpriteSheet(const SpriteSheetPtr& sheet) const
{
    if (sheet->m_loadingState.load(std::memory_order_acquire) == SpriteLoadState::LOADING)
        return false;

    if (sheet->data)
        return true;

    if (sheet->m_loadingState.exchange(SpriteLoadState::LOADING, std::memory_order_acq_rel) == SpriteLoadState::LOADING)
        return false;

    try {
        const auto& path = fmt::format("{}{}", getPath(), sheet->file);
        if (!g_resources.fileExists(path))
            return false;

        const auto& fin = g_resources.openFile(path);
        fin->cache(true);

        thread_local static std::array<uint8_t, LZMA_UNCOMPRESSED_SIZE> decompressBuffer;

        /*
           CIP's header, always 32 (0x20) bytes.
           Header format:
           [0x00, X):          A variable number of NULL (0x00) bytes. The amount of pad-bytes can vary depending on how many
                               bytes the "7-bit integer encoded LZMA file size" take.
           [X, X + 0x05):      The constant byte sequence [0x70 0x0A 0xFA 0x80 0x24]
           [X + 0x05, 0x20]:   LZMA file size (Note: excluding the 32 bytes of this header) encoded as a 7-bit integer
       */

        while (fin->getU8() == 0x00);
        fin->skip(4);
        while ((fin->getU8() & 0x80) == 0x80);

        const uint8_t lclppb = fin->getU8();

        lzma_options_lzma options{};
        options.lc = lclppb % 9;

        const int remainder = lclppb / 9;
        options.lp = remainder % 5;
        options.pb = remainder / 5;

        uint32_t dictionarySize = 0;
        for (uint8_t i = 0; i < 4; ++i) {
            dictionarySize += fin->getU8() << (i * 8);
        }

        options.dict_size = dictionarySize;

        fin->skip(8); // cip compressed size

        lzma_stream stream = LZMA_STREAM_INIT;

        const lzma_filter filters[2] = {
            lzma_filter{LZMA_FILTER_LZMA1, &options},
            lzma_filter{LZMA_VLI_UNKNOWN, nullptr}
        };

        if (lzma_ret ret = lzma_raw_decoder(&stream, filters); ret != LZMA_OK) {
            throw stdext::exception(fmt::format("failed to initialize lzma raw decoder result: {}", ret));
        }

        stream.next_in = &fin->m_data[fin->tell()];
        stream.avail_in = fin->size() - fin->tell();
        stream.next_out = decompressBuffer.data();
        stream.avail_out = decompressBuffer.size();

        const auto result = lzma_code(&stream, LZMA_RUN);
        lzma_end(&stream);

        if (result != LZMA_STREAM_END)
            throw stdext::exception("LZMA decompression failed");

        // pixel offset
        const uint8_t* bmpOffsetPtr = decompressBuffer.data() + 10;
        const uint32_t bmpDataOffset =
            bmpOffsetPtr[0] |
            (bmpOffsetPtr[1] << 8) |
            (bmpOffsetPtr[2] << 16) |
            (bmpOffsetPtr[3] << 24);

        // validate offset
        if (bmpDataOffset + BYTES_IN_SPRITE_SHEET > LZMA_UNCOMPRESSED_SIZE)
            throw stdext::exception("sprite sheet image offset out of bounds");

        uint8_t* bufferStart = decompressBuffer.data() + bmpDataOffset;

        // swap BGR ? RGB and fix magenta
        for (int i = 0; i < BYTES_IN_SPRITE_SHEET; i += 4) {
            std::swap(bufferStart[i], bufferStart[i + 2]); // B <-> R

            const uint32_t rgb = bufferStart[i] | (bufferStart[i + 1] << 8) | (bufferStart[i + 2] << 16);
            if (rgb == 0xFF00FF) {
                bufferStart[i + 0] = 0x00;
                bufferStart[i + 1] = 0x00;
                bufferStart[i + 2] = 0x00;
                bufferStart[i + 3] = 0x00;
            }
        }

        // vertical flip
        constexpr int halfHeight = SpriteSheet::SIZE / 2;
        uint8_t tempLine[SPRITE_SHEET_WIDTH_BYTES];
        for (int y = 0; y < halfHeight; ++y) {
            uint8_t* top = bufferStart + y * SPRITE_SHEET_WIDTH_BYTES;
            uint8_t* bottom = bufferStart + (SpriteSheet::SIZE - 1 - y) * SPRITE_SHEET_WIDTH_BYTES;

            std::memcpy(tempLine, top, SPRITE_SHEET_WIDTH_BYTES);
            std::memcpy(top, bottom, SPRITE_SHEET_WIDTH_BYTES);
            std::memcpy(bottom, tempLine, SPRITE_SHEET_WIDTH_BYTES);
        }

        sheet->data = std::make_unique<uint8_t[]>(BYTES_IN_SPRITE_SHEET);
        std::memcpy(sheet->data.get(), bufferStart, BYTES_IN_SPRITE_SHEET);

        sheet->m_loadingState.store(SpriteLoadState::LOADED, std::memory_order_release);
        return true;
    } catch (const std::exception& e) {
        sheet->m_loadingState.store(SpriteLoadState::NONE, std::memory_order_release);
        g_logger.error("Failed to load single sprite sheet '{}': {}", sheet->file, e.what());
        return false;
    }
}

SpriteSheetPtr ProtobufSpriteManager::getSheetBySpriteId(const int id, bool& isLoading, const bool load /* = true */)
{
    if (id == 0) {
        return nullptr;
    }

    // find sheet
    const auto sheetIt = std::ranges::find_if(m_sheets, [=](const SpriteSheetPtr& sheet) {
        return id >= sheet->firstId && id <= sheet->lastId;
    });

    if (sheetIt == m_sheets.end())
        return nullptr;

    const auto& sheet = *sheetIt;

    if (load && !loadSpriteSheet(sheet)) {
        isLoading = sheet->m_loadingState == SpriteLoadState::LOADING;
        return nullptr;
    }

    return sheet;
}

ImagePtr ProtobufSpriteManager::getSpriteImage(const int id, bool& isLoading)
{
    try {
        const auto& sheet = getSheetBySpriteId(id, isLoading, true);
        if (!sheet) {
            return nullptr;
        }

        const Size& size = sheet->getSpriteSize();

        const auto& image = std::make_shared<Image>(size);
        uint8_t* pixelData = image->getPixelData();

        const int spriteOffset = id - sheet->firstId;
        const int allColumns = sheet->getColumns();
        if (
            const int spritesPerSheet = sheet->getSpritesPerSheet();
            spriteOffset < 0 || spriteOffset >= spritesPerSheet
        ) {
            g_logger.error("Sprite id {} is out of bounds for sheet {} (offset {}, max {})", id, sheet->file, spriteOffset, spritesPerSheet);
            return nullptr;
        }
        const int spriteRow = std::floor(static_cast<float>(spriteOffset) / static_cast<float>(allColumns));
        const int spriteColumn = spriteOffset % allColumns;

        const int spriteWidthBytes = size.width() * 4;

        for (int height = size.height() * spriteRow, offset = 0; height < size.height() + (spriteRow * size.height()); height++, offset++) {
            std::memcpy(&pixelData[offset * spriteWidthBytes], &sheet->data[(height * SPRITE_SHEET_WIDTH_BYTES) + (spriteColumn * spriteWidthBytes)], spriteWidthBytes);
        }

        if (!image->hasTransparentPixel()) {
            image->checkTransparentPixels();
        }

        return image;
    } catch (const stdext::exception& e) {
        g_logger.error("Failed to get sprite id {}: {}", id, e.what());
        return nullptr;
    }
}

void ProtobufSpriteManager::saveSpriteToFile(const int id, const std::string& file)
{
    if (const auto& sprite = ISpriteManager::getSpriteImageById(id)) {
        sprite->savePNG(file);
    }
}

void ProtobufSpriteManager::saveSheetToFileBySprite(const int id, const std::string& file)
{
    if (const auto& sheet = getSheetBySpriteId(id)) {
        Image image({ SpriteSheet::SIZE }, 4, sheet->data.get());
        image.savePNG(file);
    }
}

void ProtobufSpriteManager::saveSheetToFile(const SpriteSheetPtr& sheet, const std::string& file)
{
    Image image({ SpriteSheet::SIZE }, 4, sheet->data.get());
    image.savePNG(file);
}
