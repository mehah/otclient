#include "textureatlas.h"
#include "texturemanager.h"
#include "graphics.h"

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

    info.active = false;
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

            glBindTexture(GL_TEXTURE_2D, m_layers[tex.layer]->getId());
            glCopyImageSubData(texture->getId(), GL_TEXTURE_2D, 0, 0, 0, 0,
                               m_layers[tex.layer]->getId(), GL_TEXTURE_2D, 0, tex.x, tex.y, 0,
                               width, height, 1);

            tex.textureID = texture->getId();
            tex.active = true;
            m_texturesCached.emplace(textureID, std::move(tex));
            texture->m_atlas = this;

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

    glBindTexture(GL_TEXTURE_2D, m_layers[region.layer]->getId());
    glCopyImageSubData(textureID, GL_TEXTURE_2D, 0, 0, 0, 0,
                       m_layers[region.layer]->getId(), GL_TEXTURE_2D, 0, region.x, region.y, 0,
                       width, height, 1);

    m_texturesCached.emplace(textureID, TextureInfo{
        .textureID = textureID,
        .x = region.x,
        .y = region.y,
        .layer = region.layer,
        .width = width,
        .height = height,
        .active = true
    });
    texture->m_atlas = this;
}

const TextureInfo& TextureAtlas::getTextureInfo(uint32_t id) {
    auto it = m_texturesCached.find(id);
    if (it == m_texturesCached.end()) {
        static TextureInfo info;
        return info;
    }

    return it->second;
}

void TextureAtlas::createNewLayer() {
    auto texture = std::make_shared<Texture>(Size{ m_atlasWidth, m_atlasHeight });
    texture->setCached(true);
    texture->setSmooth(false);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, m_atlasWidth, m_atlasHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);

    m_layers.push_back(texture);
    FreeRegion newRegion = { 0, 0, m_atlasWidth, m_atlasHeight, static_cast<int>(m_layers.size()) - 1 };
    m_freeRegions.insert(newRegion);
    m_freeRegionsBySize[m_atlasWidth * m_atlasHeight].insert(newRegion);
}