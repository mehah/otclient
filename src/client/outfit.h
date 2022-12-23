/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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

#include "thingtypemanager.h"
#include <framework/util/color.h>

class Outfit
{
    enum
    {
        HSI_SI_VALUES = 7,
        HSI_H_STEPS = 19
    };

public:
    static Color getColor(int color);

    void setId(uint16_t id) { m_id = id; }
    void setAuxId(uint16_t id) { m_auxId = id; }
    void setMount(uint16_t mount) { m_mount = mount; }

    void setHead(uint8_t head) { m_head = head; m_headColor = getColor(head); }
    void setBody(uint8_t body) { m_body = body; m_bodyColor = getColor(body); }
    void setLegs(uint8_t legs) { m_legs = legs; m_legsColor = getColor(legs); }
    void setFeet(uint8_t feet) { m_feet = feet; m_feetColor = getColor(feet); }
    void setAddons(uint8_t addons) { m_addons = addons; }

    void setCategory(ThingCategory category) { m_category = category; }

    void resetClothes();

    uint16_t getId() const { return m_id; }
    uint16_t getAuxId() const { return m_auxId; }
    uint16_t getMount() const { return m_mount; }

    uint8_t getHead() const { return m_head; }
    uint8_t getBody() const { return m_body; }
    uint8_t getLegs() const { return m_legs; }
    uint8_t getFeet() const { return m_feet; }
    uint8_t getAddons() const { return m_addons; }

    bool hasMount() const { return m_mount > 0; }

    ThingCategory getCategory() const { return m_category; }

    Color getHeadColor() const { return m_headColor; }
    Color getBodyColor() const { return m_bodyColor; }
    Color getLegsColor() const { return m_legsColor; }
    Color getFeetColor() const { return m_feetColor; }

    bool operator==(const Outfit& other) const
    {
        return m_category == other.m_category &&
            m_id == other.m_id &&
            m_auxId == other.m_auxId &&
            m_head == other.m_head &&
            m_body == other.m_body &&
            m_legs == other.m_legs &&
            m_feet == other.m_feet &&
            m_addons == other.m_addons &&
            m_mount == other.m_mount;
    }
    bool operator!=(const Outfit& other) const { return !(*this == other); }

private:
    ThingCategory m_category{ ThingCategoryCreature };

    uint16_t m_id{ 0 };
    uint16_t m_auxId{ 0 };
    uint16_t m_mount{ 0 };

    uint8_t m_head{ 0 };
    uint8_t m_body{ 0 };
    uint8_t m_legs{ 0 };
    uint8_t m_feet{ 0 };
    uint8_t m_addons{ 0 };

    Color m_headColor;
    Color m_bodyColor;
    Color m_legsColor;
    Color m_feetColor;
};
