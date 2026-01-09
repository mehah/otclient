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

    bool operator==(const ColorOutfit&) const = default;
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

    void setId(const uint16_t id) { m_outfit.type = id; }
    void setAuxId(const uint16_t id) { m_outfit.typeEx = id; }
    void setMount(const uint16_t mount) { m_mount.type = mount; }
    void setFamiliar(const uint16_t familiar) { m_familiar.type = familiar; }
    void setWing(const uint16_t Wing) { m_wing = Wing; }
    void setAura(const uint16_t Aura) { m_aura = Aura; }
    void setEffect(const uint16_t Effect) { m_effect = Effect; }
    void setShader(const std::string& shader) { m_shader = shader; }

    void setResourceId(const uint16_t resourceId) { m_outfit.resourceId = resourceId; }
    void setMountResourceId(const uint16_t resourceId) { m_mount.resourceId = resourceId; }
    void setFamiliarResourceId(const uint16_t resourceId) { m_familiar.resourceId = resourceId; }

    void setHead(uint8_t head);
    void setBody(uint8_t body);
    void setLegs(uint8_t legs);
    void setFeet(uint8_t feet);
    void setAddons(const uint8_t addons) { m_addons = addons; }
    void setTemp(const bool temp) { m_temp = temp; }

    void setCategory(const ThingCategory category) { m_category = category; }

    void resetClothes();

    uint16_t getId() const { return m_outfit.type; }
    uint16_t getAuxId() const { return m_outfit.typeEx; }
    uint16_t getMount() const { return m_mount.type; }
    uint16_t getFamiliar() const { return m_familiar.type; }
    uint16_t getWing() const { return m_wing; }
    uint16_t getAura() const { return m_aura; }
    uint16_t getEffect() const { return m_effect; }
    std::string getShader() const { return m_shader; }

    uint16_t getResourceId() const { return m_outfit.resourceId; }
    uint16_t getMountResourceId() const { return m_mount.resourceId; }
    uint16_t getFamiliarResourceId() const { return m_familiar.resourceId; }

    uint8_t getHead() const { return m_outfit.head; }
    uint8_t getBody() const { return m_outfit.body; }
    uint8_t getLegs() const { return m_outfit.legs; }
    uint8_t getFeet() const { return m_outfit.feet; }
    uint8_t getAddons() const { return m_addons; }

    bool hasMount() const { return m_mount.type > 0; }

    ThingCategory getCategory() const { return m_category; }
    bool isCreature() const { return m_category == ThingCategoryCreature; }
    bool isInvalid() const { return m_category == ThingInvalidCategory; }
    bool isEffect() const { return m_category == ThingCategoryEffect; }
    bool isItem() const { return m_category == ThingCategoryItem; }
    bool isTemp() const { return m_temp; }

    Color getHeadColor() const { return m_outfit.headColor; }
    Color getBodyColor() const { return m_outfit.bodyColor; }
    Color getLegsColor() const { return m_outfit.legsColor; }
    Color getFeetColor() const { return m_outfit.feetColor; }

    bool operator==(const Outfit& other) const
    {
        return m_category == other.m_category &&
            m_outfit == other.m_outfit &&
            m_addons == other.m_addons &&
            m_mount == other.m_mount &&
            m_familiar == other.m_familiar &&
            m_wing == other.m_wing &&
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

    // custom features (to do)
    uint16_t m_wing{ 0 };
    uint16_t m_aura{ 0 };
    uint16_t m_effect{ 0 };
    std::string m_shader;
};
