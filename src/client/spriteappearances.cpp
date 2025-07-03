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

#include "spriteappearances.h"
#include "game.h"
#include <framework/core/filestream.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/image.h>

#include <algorithm>
#include <framework/core/asyncdispatcher.h>
#include <nlohmann/json.hpp>

#include "lzma.h"

constexpr size_t BYTES_IN_SPRITE_SHEET = 384 * 384 * 4;
constexpr size_t LZMA_UNCOMPRESSED_SIZE = BYTES_IN_SPRITE_SHEET + 122;
constexpr size_t LZMA_PROPS_SIZE = 5;
constexpr size_t LZMA_HEADER_SIZE = LZMA_PROPS_SIZE + 8;

 // warnings related to protobuf
 // https://android.googlesource.com/platform/external/protobuf/+/brillo-m9-dev/vsprojects/readme.txt

using json = nlohmann::json;

SpriteAppearances g_spriteAppearances;

void SpriteAppearances::init()
{
    // in tibia 12.81 there is currently 3482 sheets
    m_sheets.reserve(4000);
}

void SpriteAppearances::terminate()
{
    unload();
}

#pragma pack(push,1)
struct BmpHeader {
  uint16_t type;
  uint32_t fileSize;
  uint16_t r1, r2;
  uint32_t dataOffset;
  uint32_t dibHeaderSize;
  int32_t  width;
  int32_t  height;
  uint16_t planes;
  uint16_t bpp;
};
#pragma pack(pop)

bool SpriteAppearances::loadSpriteSheet(const SpriteSheetPtr& sheet) const
{
    if (sheet->data)
        return true;

    std::scoped_lock lock(sheet->m_mutex);

    try {
        const auto& fullPath = fmt::format("{}{}", getPath(), sheet->file);
        if (!g_resources.fileExists(fullPath)) {
            return false;
        }

        auto fin = g_resources.openFile(fullPath);
        fin->cache(true);

        /*
           CIP's header, always 32 (0x20) bytes.
           Header format:
           [0x00, X):          A variable number of NULL (0x00) bytes.
           [X, X + 0x05):      The constant byte sequence [0x70 0x0A 0xFA 0x80 0x24]
           [X + 0x05, 0x20]:   LZMA file size (excluding these 32 bytes) encoded as a 7-bit integer
        */

        auto decompressed = std::make_unique<uint8_t[]>(LZMA_UNCOMPRESSED_SIZE);

        // Skip CIP header
        while (fin->getU8() == 0x00);
        fin->skip(4);
        while ((fin->getU8() & 0x80) == 0x80);

        const uint8_t lclppb = fin->getU8();
        lzma_options_lzma options{};
        options.lc = lclppb % 9;
        options.lp = (lclppb / 9) % 5;
        options.pb = (lclppb / 9) / 5;

        uint32_t dictSize = 0;
        for (int i = 0; i < 4; ++i) {
            dictSize |= fin->getU8() << (8 * i);
        }
        options.dict_size = dictSize;

        fin->skip(8); // Compressed size in header

        // Initialize decoder raw LZMA1
        lzma_stream strm = LZMA_STREAM_INIT;
        const lzma_filter filters[2] = {
            { LZMA_FILTER_LZMA1, &options },
            { LZMA_VLI_UNKNOWN, nullptr }
        };
        if (lzma_raw_decoder(&strm, filters) != LZMA_OK) {
            throw stdext::exception("lzma_raw_decoder failed");
        }

        // Prepare input
        const size_t off = fin->tell();
        const size_t remaining = fin->size() - off;
        strm.next_in = fin->m_data.data() + off;
        strm.avail_in = remaining;
        strm.next_out = decompressed.get();
        strm.avail_out = LZMA_UNCOMPRESSED_SIZE;

        lzma_ret ret = lzma_code(&strm, LZMA_FINISH);
        lzma_end(&strm);
        if (ret != LZMA_STREAM_END) {
            throw stdext::exception(fmt::format("lzma_code failed: {}", ret));
        }

        auto hdr = reinterpret_cast<const BmpHeader*>(decompressed.get());
        if (hdr->type != 0x4D42 || hdr->bpp != 32) {
            throw std::runtime_error("invalid BMP in sprite sheet");
        }

        sheet->widthPx   = hdr->width;
        sheet->heightPx  = std::abs(hdr->height);
        sheet->rowStride = sheet->widthPx * 4;

        uint8_t* pixelPtr = decompressed.get() + hdr->dataOffset;
        const size_t pixelBytes = size_t(sheet->rowStride) * sheet->heightPx;

        // reverse channels (B <-> R)
        for (size_t i = 0; i < pixelBytes; i += 4) {
            std::swap(pixelPtr[i], pixelPtr[i + 2]);
        }

        // flip vertically
        for (int y = 0; y < sheet->heightPx / 2; ++y) {
            auto* top    = pixelPtr + y * sheet->rowStride;
            auto* bottom = pixelPtr + (sheet->heightPx - 1 - y) * sheet->rowStride;
            std::swap_ranges(top, top + sheet->rowStride, bottom);
        }

        // fix magenta
        for (size_t offb = 0; offb < pixelBytes; offb += 4) {
            uint32_t px;
            std::memcpy(&px, pixelPtr + offb, 4);
            if ((px & 0x00FFFFFFu) == 0x00FF00FFu) {
                std::fill(pixelPtr + offb, pixelPtr + offb + 4, 0);
            }
        }

        sheet->data = std::make_unique<uint8_t[]>(pixelBytes);
        std::memcpy(sheet->data.get(), pixelPtr, pixelBytes);

        return true;
    } catch (const std::exception& e) {
        g_logger.error("Failed to load sprite sheet '{}': {}", sheet->file, e.what());
        return false;
    }
}

void SpriteAppearances::unload()
{
    m_spritesCount = 0;
    m_sheets.clear();
}

SpriteSheetPtr SpriteAppearances::getSheetBySpriteId(const int id, const bool load /* = true */)
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

    if (load && !loadSpriteSheet(sheet))
        return nullptr;

    return sheet;
}

ImagePtr SpriteAppearances::getSpriteImage(const int id)
{
    try {
        const auto& sheet = getSheetBySpriteId(id);
        if (!sheet) {
            return nullptr;
        }

        const Size& size = sheet->getSpriteSize();

        const auto& image = std::make_shared<Image>(size);
        uint8_t* pixelData = image->getPixelData();

        const int spriteOffset = id - sheet->firstId;
        const int allColumns = sheet->getColumns();
        const int spriteHeight = size.height();
        const int maxRows = sheet->heightPx / spriteHeight;
        const int spriteRow = std::floor(static_cast<float>(spriteOffset) / static_cast<float>(allColumns));
        const int spriteColumn = spriteOffset % allColumns;

        if (spriteColumn < 0 || spriteColumn >= allColumns ||
                spriteRow    < 0 || spriteRow    >= maxRows)
        {
            g_logger.error(
                "Sprite OOB! file={} layout={} sheet={}×{} sprite={}×{} "
                "id={} firstId={} lastId={} offset={} > row={},column={} cols={}, rows={}",
                sheet->file,
                static_cast<int>(sheet->spriteLayout),
                sheet->widthPx, sheet->heightPx,
                size.width(), size.height(),
                id, sheet->firstId, sheet->lastId,
                spriteOffset, spriteRow, spriteColumn,
                allColumns, maxRows
            );
            return nullptr;
        }

        const int spriteWidthBytes = size.width() * 4;
        const size_t rowBytes = sheet->rowStride;
        const int startRow = spriteRow * spriteHeight;
        for (int y = 0; y < spriteHeight; ++y) {
            size_t srcOffset = size_t(startRow + y) * rowBytes
                            + size_t(spriteColumn) * spriteWidthBytes;
            uint8_t* dst = pixelData + size_t(y) * spriteWidthBytes;

            assert(srcOffset + spriteWidthBytes <= size_t(rowBytes) * sheet->heightPx);

            std::memcpy(dst,
                        sheet->data.get() + srcOffset,
                        spriteWidthBytes);
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
        g_logger.error("Failed to get sprite id {}: {}", id, e.what());
        return nullptr;
    }
}

void SpriteAppearances::saveSpriteToFile(const int id, const std::string& file)
{
    if (const auto& sprite = getSpriteImage(id)) {
        sprite->savePNG(file);
    }
}

void SpriteAppearances::saveSheetToFileBySprite(const int id, const std::string& file)
{
    if (const auto& sheet = getSheetBySpriteId(id)) {
        Image image({ SpriteSheet::SIZE }, 4, sheet->data.get());
        image.savePNG(file);
    }
}

void SpriteAppearances::saveSheetToFile(const SpriteSheetPtr& sheet, const std::string& file)
{
    Image image({ SpriteSheet::SIZE }, 4, sheet->data.get());
    image.savePNG(file);
}
