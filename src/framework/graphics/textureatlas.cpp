#include "textureatlas.h"
#include "texturemanager.h"
#include "graphics.h"
#include "framebuffer.h"

TextureAtlas::TextureAtlas() : TextureAtlas(g_graphics.getMaxTextureSize(), g_graphics.getMaxTextureSize()) {}

TextureAtlas::TextureAtlas(int width, int height) : m_atlasWidth(width), m_atlasHeight(height) {
    if (width <= 0 || height <= 0) {
        throw std::invalid_argument("Invalid atlas dimensions or layer count.");
    }
    createNewLayer();
}

void TextureAtlas::removeTexture(uint32_t id) {
    auto it = m_texturesCached.find(id);
    if (it == m_texturesCached.end()) {
        return;
    }

    auto& info = it->second;

    auto sizeKey = std::make_pair(info.width, info.height);
    m_inactiveTextures.try_emplace(sizeKey, std::vector<TextureInfo>())
        .first->second.emplace_back(std::move(info));
    m_texturesCached.erase(it);
}

void TextureAtlas::addTexture(const TexturePtr& texture) {
    const auto textureID = texture->getId();
    const auto width = texture->getWidth();
    const auto height = texture->getHeight();

    if (width <= 0 || height <= 0 || width > m_atlasWidth || height > m_atlasHeight) {
        throw std::invalid_argument("Texture dimensions are invalid or exceed atlas dimensions.");
    }

    auto sizeKey = std::make_pair(width, height);
    auto it = m_inactiveTextures.find(sizeKey);
    if (it != m_inactiveTextures.end()) {
        auto& texList = it->second;
        if (!texList.empty()) {
            TextureInfo tex = std::move(texList.back());
            texList.pop_back();

            tex.textureID = texture->getId();
            tex.transformMatrixId = texture->getTransformMatrixId();
            texture->m_atlas = this;
            texture->m_atlasX = tex.x;
            texture->m_atlasY = tex.y;
            texture->m_atlasLayer = tex.layer;

            m_layers[tex.layer].textures.emplace_back(tex);
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

    auto info = TextureInfo{
       .textureID = textureID,
       .x = texture->m_atlasX = region.x,
       .y = texture->m_atlasY = region.y,
       .layer = texture->m_atlasLayer = region.layer,
       .width = static_cast<int16_t>(width),
       .height = static_cast<int16_t>(height),
       .transformMatrixId = texture->getTransformMatrixId()
    };

    m_layers[region.layer].textures.emplace_back(info);
    m_texturesCached.emplace(textureID, std::move(info));

    texture->m_atlas = this;
}

void TextureAtlas::createNewLayer() {
    auto fbo = std::make_shared<FrameBuffer>();
    fbo->resize({ m_atlasWidth, m_atlasHeight });
    fbo->setAutoClear(false);
    fbo->getTexture()->setSmooth(false);
    fbo->getTexture()->setCached(true);

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

            for (const auto& texture : layer.textures) {
                buffer.clear();
                buffer.addRect({ texture.x, texture.y, Size{texture.width, texture.height} }, { 0,0, texture.width, texture.height });
                g_painter->setTexture(texture.textureID, texture.transformMatrixId);
                g_painter->drawCoords(buffer, DrawMode::TRIANGLE_STRIP);
            }
            layer.textures.clear();
            layer.framebuffer->release();
        }
    }
}