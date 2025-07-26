#pragma once
#include <GL/glew.h>
#include <unordered_map>
#include <vector>
#include <chrono>
#include <set>
#include <optional>
#include <functional>
#include <stdexcept>
#include <iostream>
#include <map>
#include <algorithm>
#include "declarations.h"

struct TextureInfo
{
    GLuint textureID;
    int x, y, layer;
    int width, height;
    std::chrono::steady_clock::time_point lastUsed;
    bool active = false;
};

struct FreeRegion
{
    int x, y, width, height, layer;

    bool operator<(const FreeRegion& other) const {
        if (layer != other.layer) return layer < other.layer;
        if (width * height != other.width * other.height)
            return (width * height) < (other.width * other.height);
        return (y != other.y) ? (y < other.y) : (x < other.x);
    }

    bool canFit(int texWidth, int texHeight) const {
        return width >= texWidth && height >= texHeight;
    }
};

struct PairHash
{
    template <typename T1, typename T2>
    std::size_t operator()(const std::pair<T1, T2>& pair) const {
        std::hash<T1> hash1;
        std::hash<T2> hash2;
        return hash1(pair.first) ^ (hash2(pair.second) << 1);
    }
};

class TextureAtlas
{
private:
    std::vector<TexturePtr> m_atlas;
    int atlasWidth, atlasHeight, maxLayers;

    std::unordered_map<std::pair<int, int>, std::vector<TextureInfo>, PairHash> inactiveTextures;
    std::set<FreeRegion> freeRegions;
    std::map<int, std::set<FreeRegion>> freeRegionsBySize;

    uint16_t m_transformMatrixId{ 0 };
    phmap::parallel_flat_hash_map<uint32_t, TextureInfo> m_texturesCached;

    void createNewLayer();

    void removeExpiredInactiveTextures(int inactivityThreshold) {
        auto now = std::chrono::steady_clock::now();
        for (auto& [size, texList] : inactiveTextures) {
            std::erase_if(texList, [&now, inactivityThreshold](const TextureInfo& tex) {
                return std::chrono::duration_cast<std::chrono::seconds>(now - tex.lastUsed).count() >= inactivityThreshold;
            });
        }
    }

    std::optional<FreeRegion> findBestRegion(int width, int height) {
        auto sizeIt = freeRegionsBySize.lower_bound(width * height);
        while (sizeIt != freeRegionsBySize.end()) {
            for (const auto& region : sizeIt->second) {
                if (region.canFit(width, height)) {
                    return region;
                }
            }
            ++sizeIt;
        }
        return std::nullopt;
    }

    void splitRegion(const FreeRegion& region, int width, int height) {
        freeRegions.erase(region);
        freeRegionsBySize[region.width * region.height].erase(region);

        if (region.width > width) {
            FreeRegion right = { region.x + width, region.y, region.width - width, height, region.layer };
            if (right.width > 0 && right.height > 0) {
                freeRegions.insert(right);
                freeRegionsBySize[right.width * right.height].insert(right);
            }
        }

        if (region.height > height) {
            FreeRegion bottom = { region.x, region.y + height, width, region.height - height, region.layer };
            if (bottom.width > 0 && bottom.height > 0) {
                freeRegions.insert(bottom);
                freeRegionsBySize[bottom.width * bottom.height].insert(bottom);
            }
        }

        if (region.width > width && region.height > height) {
            FreeRegion corner = { region.x + width, region.y + height, region.width - width, region.height - height, region.layer };
            if (corner.width > 0 && corner.height > 0) {
                freeRegions.insert(corner);
                freeRegionsBySize[corner.width * corner.height].insert(corner);
            }
        }
    }

    void compactAtlas() {
        // Optional: implementar defragmentação aqui.
    }

public:
    TextureAtlas(int width, int height, int layers);

    void addTexture(const TexturePtr& texture);

    const auto& getAtlas(int layer) const {
        if (layer < 0 || layer >= static_cast<int>(m_atlas.size())) {
            throw std::out_of_range("Invalid layer index.");
        }
        return m_atlas[layer];
    }

    auto getTransformMatrixId() const { return m_transformMatrixId; }
    auto getWidth() const { return atlasWidth; }
    auto getHeight() const { return atlasHeight; }

    int getLayerCount() const {
        return static_cast<int>(m_atlas.size());
    }

    TextureInfo getTextureInfo(uint32_t id);
};
