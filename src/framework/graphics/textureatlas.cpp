#include "framebuffer.h"
#include "textureatlas.h"

#include "painter.h"

constexpr uint8_t SMOOTH_PADDING = 2;

TextureAtlas::TextureAtlas(Fw::TextureAtlasType type, int size, bool smoothSupport) :
    m_type(type),
    m_size({ std::min<int>(size, 8192) }) {
    createNewLayer(false);
    if (smoothSupport)
        createNewLayer(true);
}

void TextureAtlas::removeTexture(uint32_t id, bool smooth) {
    auto it = m_texturesCached.find(id);
    if (it == m_texturesCached.end()) {
        return;
    }

    it->second->enabled = false;

    auto sizeKey = std::make_pair(it->second->width, it->second->height);
    m_filterGroups[smooth].inactiveTextures.try_emplace(sizeKey, std::vector<std::unique_ptr<AtlasRegion>>())
        .first->second.emplace_back(std::move(it->second));
    m_texturesCached.erase(it);
}

void TextureAtlas::addTexture(const TexturePtr& texture) {
    const auto textureID = texture->getId();
    const auto width = texture->getWidth();
    const auto height = texture->getHeight();

    if (width <= 0 || height <= 0 || width >= m_size.width() || height >= m_size.height()) {
        return; // don't cache
    }

    auto& filterGroup = m_filterGroups[texture->isSmooth()];

    auto sizeKey = std::make_pair(width, height);
    auto it = filterGroup.inactiveTextures.find(sizeKey);
    if (it != filterGroup.inactiveTextures.end()) {
        auto& texList = it->second;
        if (!texList.empty()) {
            auto tex = std::move(texList.back());
            texList.pop_back();

            tex->textureID = texture->getId();
            tex->transformMatrixId = texture->getTransformMatrixId();
            texture->m_atlas[m_type] = tex.get();

            filterGroup.layers[tex->layer].textures.emplace_back(tex.get());
            m_texturesCached.emplace(textureID, std::move(tex));

            return;
        }
    }

    const int pad = texture->isSmooth() ? SMOOTH_PADDING : 0;
    const int allocW = width + (pad * 2);
    const int allocH = height + (pad * 2);

    auto bestRegionOpt = findBestRegion(allocW, allocH, texture->isSmooth());
    if (!bestRegionOpt.has_value()) {
        createNewLayer(texture->isSmooth());
        return addTexture(texture);
    }

    FreeRegion region = bestRegionOpt.value();
    splitRegion(region, allocW, allocH, texture->isSmooth());

    auto info = std::make_unique<AtlasRegion>(
        textureID,
        region.x + pad,
        region.y + pad,
        region.layer,
        static_cast<int16_t>(width),
        static_cast<int16_t>(height),
        texture->getTransformMatrixId(),
        m_filterGroups[texture->isSmooth()].layers[region.layer].framebuffer->getTexture().get()
    );

    texture->m_atlas[m_type] = info.get();
    filterGroup.layers[region.layer].textures.emplace_back(info.get());
    m_texturesCached.emplace(textureID, std::move(info));
}

void TextureAtlas::createNewLayer(bool smooth) {
    auto fbo = std::make_unique<FrameBuffer>();
    fbo->setAutoClear(false);
    fbo->setAutoResetState(true);
    fbo->setSmooth(smooth);
    fbo->resize(m_size);

    FreeRegion newRegion = { 0, 0, m_size.width(), m_size.height(), static_cast<int>(m_filterGroups[smooth].layers.size()) };

    m_filterGroups[smooth].layers.emplace_back(std::move(fbo));
    m_filterGroups[smooth].freeRegions.insert(newRegion);
    m_filterGroups[smooth].freeRegionsBySize[m_size.width() * m_size.height()].insert(newRegion);
}

void TextureAtlas::flush() {
    static CoordsBuffer buffer;
    for (auto i = -1; ++i < AtlasFilter::ATLAS_FILTER_COUNT;) {
        auto& group = m_filterGroups[i];

        const int pad = i == AtlasFilter::ATLAS_FILTER_LINEAR ? SMOOTH_PADDING : 0;

        for (auto& layer : group.layers) {
            if (!layer.textures.empty()) {
                layer.framebuffer->bind();
                glDisable(GL_BLEND);
                for (const auto& texture : layer.textures) {
                    const int x = texture->x;
                    const int y = texture->y;
                    const int w = texture->width;
                    const int h = texture->height;

                    const Rect dest = { x - pad, y - pad, Size{ w + pad * 2, h + pad * 2 } };

                    g_painter->clearRect(Color::alpha, dest);

                    if (pad > 0) {
                        buffer.clear();
                        buffer.addRect(dest, { -pad, -pad, w + pad * 2, h + pad * 2 });
                        g_painter->setTexture(texture->textureID, texture->transformMatrixId);
                        g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);
                    }

                    buffer.clear();
                    buffer.addRect({ x, y, Size{ w, h } }, { 0, 0, w, h });
                    g_painter->setTexture(texture->textureID, texture->transformMatrixId);
                    g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);

                    texture->enabled.store(true, std::memory_order_release);
                }
                glEnable(GL_BLEND);
                layer.textures.clear();
                layer.framebuffer->release();
            }
        }
    }
}