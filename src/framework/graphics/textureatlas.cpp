#include "textureatlas.h"
#include "texturemanager.h"
#include "graphics.h"
#include "framebuffer.h"

TextureAtlas::TextureAtlas(Fw::TextureAtlasType type) : TextureAtlas(type, g_graphics.getMaxTextureSize(), g_graphics.getMaxTextureSize()) {}

TextureAtlas::TextureAtlas(Fw::TextureAtlasType type, int width, int height) :
    m_type(type),
    m_atlasWidth(std::min<int>(width, 16384)),
    m_atlasHeight(std::min<int>(height, 16384)) {
    createNewLayer();
}

void TextureAtlas::removeTexture(uint32_t id) {
    auto it = m_texturesCached.find(id);
    if (it == m_texturesCached.end()) {
        return;
    }

    it->second->enabled = false;

    auto sizeKey = std::make_pair(it->second->width, it->second->height);
    m_inactiveTextures.try_emplace(sizeKey, std::vector<std::unique_ptr<AtlasRegion>>())
        .first->second.emplace_back(std::move(it->second));
    m_texturesCached.erase(it);
}

void TextureAtlas::addTexture(const TexturePtr& texture) {
    const auto textureID = texture->getId();
    const auto width = texture->getWidth();
    const auto height = texture->getHeight();

    if (width <= 0 || height <= 0 || width >= m_atlasWidth || height >= m_atlasHeight) {
        return; // don't cache
    }

    auto sizeKey = std::make_pair(width, height);
    auto it = m_inactiveTextures.find(sizeKey);
    if (it != m_inactiveTextures.end()) {
        auto& texList = it->second;
        if (!texList.empty()) {
            auto tex = std::move(texList.back());
            texList.pop_back();

            tex->textureID = texture->getId();
            tex->transformMatrixId = texture->getTransformMatrixId();
            texture->m_atlas[m_type] = tex.get();

            m_layers[tex->layer].textures.emplace_back(tex.get());
            m_texturesCached.emplace(textureID, std::move(tex));

            return;
        }
    }

    auto bestRegionOpt = findBestRegion(width, height);
    if (!bestRegionOpt.has_value()) {
        createNewLayer();
        return addTexture(texture);
    }

    FreeRegion region = bestRegionOpt.value();
    splitRegion(region, width, height);

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
    m_layers[region.layer].textures.emplace_back(info.get());
    m_texturesCached.emplace(textureID, std::move(info));
}

void TextureAtlas::createNewLayer() {
    auto fbo = std::make_shared<FrameBuffer>();
    fbo->resize({ m_atlasWidth, m_atlasHeight });
    fbo->setAutoClear(false);
    fbo->setAutoResetState(true);
    fbo->getTexture()->setSmooth(false);

    m_layers.emplace_back(fbo);
    FreeRegion newRegion = { 0, 0, m_atlasWidth, m_atlasHeight, static_cast<int>(m_layers.size()) - 1 };
    m_freeRegions.insert(newRegion);
    m_freeRegionsBySize[m_atlasWidth * m_atlasHeight].insert(newRegion);
}

void TextureAtlas::flush() {
    static CoordsBuffer buffer;
    for (auto& layer : m_layers) {
        if (!layer.textures.empty()) {
            layer.framebuffer->bind();
            glDisable(GL_BLEND);
            for (const auto& texture : layer.textures) {
                g_painter->clearRect(Color::alpha, { texture->x, texture->y, Size{texture->width, texture->height} });

                buffer.clear();
                buffer.addRect({ texture->x, texture->y, Size{texture->width, texture->height} }, { 0,0, texture->width, texture->height });
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