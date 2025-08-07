#include "textureatlas.h"
#include "texturemanager.h"
#include "graphics.h"
#include "framebuffer.h"

TextureAtlas::TextureAtlas(Fw::TextureAtlasType type, int size) :
    m_type(type),
    m_size({ std::min<int>(size, 16384) }) {
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

    auto bestRegionOpt = findBestRegion(width, height, texture->isSmooth());
    if (!bestRegionOpt.has_value()) {
        createNewLayer(texture->isSmooth());
        return addTexture(texture);
    }

    FreeRegion region = bestRegionOpt.value();
    splitRegion(region, width, height, texture->isSmooth());

    auto info = std::make_unique<AtlasRegion>(
        textureID,
        region.x,
        region.y,
        region.layer,
        static_cast<int16_t>(width),
        static_cast<int16_t>(height),
        texture->getTransformMatrixId()
    );

    texture->m_atlas[m_type] = info.get();
    filterGroup.layers[region.layer].textures.emplace_back(info.get());
    m_texturesCached.emplace(textureID, std::move(info));
}

void TextureAtlas::createNewLayer(bool smooth) {
    FreeRegion newRegion = { 0, 0, m_size.width(), m_size.height(), static_cast<int>(m_filterGroups[smooth].layers.size()) };
    m_filterGroups[smooth].layers.emplace_back(std::make_unique<FrameBuffer>());
    m_filterGroups[smooth].freeRegions.insert(newRegion);
    m_filterGroups[smooth].freeRegionsBySize[m_size.width() * m_size.height()].insert(newRegion);
}

void TextureAtlas::flush() {
    static CoordsBuffer buffer;
    for (auto i = -1; ++i < AtlasFilter::ATLAS_FILTER_COUNT;) {
        auto& group = m_filterGroups[i];
        for (auto& layer : group.layers) {
            if (!layer.textures.empty()) {
                layer.init(m_size, i);
                layer.framebuffer->bind();
                glDisable(GL_BLEND);
                for (const auto& texture : layer.textures) {
                    g_painter->clearRect(Color::alpha, { texture->x, texture->y, Size{texture->width, texture->height} });

                    buffer.clear();
                    buffer.addRect({ texture->x, texture->y, Size{texture->width, texture->height} }, { 0,0, texture->width, texture->height });
                    g_painter->setTexture(texture->textureID, texture->transformMatrixId);
                    g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);

                    texture->atlas = layer.framebuffer->getTexture().get();
                    texture->enabled.store(true, std::memory_order_release);
                }
                glEnable(GL_BLEND);
                layer.textures.clear();
                layer.framebuffer->release();
            }
        }
    }
}

void TextureAtlas::Layer::init(const Size& size, bool smooth) {
    if (framebuffer->isValid()) return;
    framebuffer->setAutoClear(false);
    framebuffer->setAutoResetState(true);
    framebuffer->setSmooth(smooth);
    framebuffer->resize(size);
}