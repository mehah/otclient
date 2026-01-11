/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
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

#pragma once

#include "declarations.h"

struct SimpleOutfit
{
    uint16_t type = 0;
    uint16_t typeEx = 0;
    uint16_t resourceId = 0;

    bool operator==(const SimpleOutfit&) const = default;
};

struct ColorOutfit
{
    uint16_t type = 0;
    uint16_t typeEx = 0;
    uint16_t resourceId = 0;

    uint8_t head = 0;
    uint8_t body = 0;
    uint8_t legs = 0;
    uint8_t feet = 0;

    Color headColor{ Color::white };
    Color bodyColor{ Color::white };
    Color legsColor{ Color::white };
    Color feetColor{ Color::white };

    void applyColors();
    void resetColors();

    bool operator==(const ColorOutfit&) const = default;
};

struct EffectOutfit
{
    uint16_t type = 0;
    uint16_t resourceId = 0;
    ThingCategory category = ThingCategoryEffect;
    bool operator==(const EffectOutfit&) const = default;
};

class Outfit
{
    enum
    {
        HSI_SI_VALUES = 7,
        HSI_H_STEPS = 19
    };

public:
    static Color getColor(int color);

    // bulk apply fields
    void applyOutfit(ColorOutfit outfit) { m_outfit = std::move(outfit); };
    void applySimpleOutfit(SimpleOutfit outfit) {
        m_outfit = ColorOutfit();
        m_outfit.type = outfit.type;
        m_outfit.typeEx = outfit.typeEx;
        m_outfit.resourceId = outfit.resourceId;
    };
    void applyMount(ColorOutfit outfit) { m_mount = std::move(outfit); };
    void applyFamiliar(SimpleOutfit outfit) { m_familiar = std::move(outfit); };
    void applyWings(SimpleOutfit outfit) { m_wings = std::move(outfit); };
    void applyAura(EffectOutfit effect) { m_aura = std::move(effect); };
    void applyParticles(EffectOutfit effect) { m_effect = std::move(effect); };

    // bulk get fields
    ColorOutfit getBaseOutfit() const { return m_outfit; };
    ColorOutfit getMount() const { return m_mount; };
    SimpleOutfit getFamiliar() const { return m_familiar; };
    SimpleOutfit getWings() const { return m_wings; };
    EffectOutfit getAura() const { return m_aura; };
    EffectOutfit getEffect() const { return m_effect; };

    // these fields are in use more than the rest
    // so it's best to have get/set for them
    void setId(const uint16_t id) { m_outfit.type = id; }
    void setAuxId(const uint16_t id) { m_outfit.typeEx = id; }
    void setResourceId(const uint16_t resourceId) { m_outfit.resourceId = resourceId; }

    void setMount(const uint16_t mount) { m_mount.type = mount; }
    void setShader(const std::string& shader) { m_shader = shader; }

    void setAddons(const uint8_t addons) { m_addons = addons; }
    void setTemp(const bool temp) { m_temp = temp; }

    void setCategory(const ThingCategory category) { m_category = category; }

    void resetClothes();

    uint16_t getId() const { return m_outfit.type; }
    uint16_t getAuxId() const { return m_outfit.typeEx; }
    std::string getShader() const { return m_shader; }

    uint16_t getResourceId() const { return m_outfit.resourceId; }

    uint8_t getAddons() const { return m_addons; }

    bool hasMount() const { return m_mount.type > 0; }
    bool hasWings() const { return m_wings.type > 0; }
    bool hasAura() const { return m_aura.type > 0; }
    bool hasParticles() const { return m_effect.type > 0; }

    ThingCategory getCategory() const { return m_category; }
    bool isCreature() const { return m_category == ThingCategoryCreature; }
    bool isInvalid() const { return m_category == ThingInvalidCategory; }
    bool isEffect() const { return m_category == ThingCategoryEffect; }
    bool isItem() const { return m_category == ThingCategoryItem; }
    bool isTemp() const { return m_temp; }

    bool operator==(const Outfit& other) const
    {
        return m_category == other.m_category &&
            m_outfit == other.m_outfit &&
            m_addons == other.m_addons &&
            m_mount == other.m_mount &&
            m_familiar == other.m_familiar &&
            m_wings == other.m_wings &&
            m_aura == other.m_aura &&
            m_effect == other.m_effect &&
            m_shader == other.m_shader;
    }
    bool operator!=(const Outfit& other) const { return !(*this == other); }

private:
    ThingCategory m_category{ ThingInvalidCategory };

    bool m_temp{ false };
    
    // base outfit fields
    ColorOutfit m_outfit{};
    uint8_t m_addons{ 0 };

    // mount fields
    ColorOutfit m_mount{};

    // familiar fields
    SimpleOutfit m_familiar{};

    // wings fields
    SimpleOutfit m_wings{};

    // aura fields
    EffectOutfit m_aura{};

    // particles fields
    EffectOutfit m_effect{};

    // shaders are indexed by string
    // and they do not use resource ids
    std::string m_shader;
};
