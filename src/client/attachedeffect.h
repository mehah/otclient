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

#include "thingtype.h"
#include "outfit.h"

class AttachedEffect : public LuaObject
{
public:
    void draw(const Point& /*dest*/, bool /*isOnTop*/, LightView* = nullptr);

    uint16_t getId() { return m_id; }

    AttachedEffectPtr clone();

    float getSpeed() { return m_speed / 100.f; }
    void setSpeed(float speed) { m_speed = speed * 100u; }

    float getOpacity() { return m_opacity / 100.f; }
    void setOpacity(float opacity) { m_opacity = opacity * 100u; }

    Size getSize() { return m_size; }
    void setSize(const Size& s) { m_size = s; }

    bool isHidedOwner() { return m_hideOwner; }
    void setHideOwner(bool v) { m_hideOwner = v; }

    bool isTransform() { return m_transform; }
    void setTransform(bool v) { m_transform = v; }

    bool isDisabledWalkAnimation() { return m_disableWalkAnimation; }
    void setDisableWalkAnimation(bool v) { m_disableWalkAnimation = v; }

    uint16_t getDuration() { return m_duration; }
    void setDuration(uint16_t v) { m_duration = v; }

    int8_t getLoop() { return m_loop; }
    void setLoop(int8_t v) { m_loop = v; }

    void setName(std::string_view n) { m_name = { n.data() }; }
    std::string getName() { return m_name; }

    void setOnTop(bool onTop) { for (auto& control : m_offsetDirections) control.onTop = onTop; }
    void setOffset(int16_t x, int16_t y) { for (auto& control : m_offsetDirections) control.offset = { x, y }; }
    void setOnTopByDir(Otc::Direction direction, bool onTop) { m_offsetDirections[direction].onTop = onTop; }

    void setDirOffset(Otc::Direction direction, int8_t x, int8_t y, bool onTop = false) { m_offsetDirections[direction] = { onTop, {x, y} }; }
    void setShader(const std::string_view name);
    void setCanDrawOnUI(bool canDraw) { m_canDrawOnUI = canDraw; }
    bool canDrawOnUI() { return m_canDrawOnUI; }

    void attachEffect(const AttachedEffectPtr& e) { m_effects.emplace_back(e); }

private:
    int getCurrentAnimationPhase();

    struct DirControl
    {
        bool onTop{ false };
        Point offset;
    };

    int8_t m_loop{ -1 };

    uint8_t m_speed{ 100 };
    uint8_t m_opacity{ 100 };
    uint8_t m_lastAnimation{ 0 };

    uint16_t m_id{ 0 };
    uint16_t m_duration{ 0 };

    uint32_t m_frame{ 0 };

    bool m_hideOwner{ false };
    bool m_transform{ false };
    bool m_canDrawOnUI{ true };
    bool m_disableWalkAnimation{ false };

    Outfit m_outfitOwner;

    uint16_t m_thingId{ 0 };
    ThingCategory m_thingCategory{ ThingInvalidCategory };

    ThingType* m_thingType{ nullptr };

    Size m_size;

    Timer m_animationTimer;

    Otc::Direction m_direction{ Otc::North };

    std::array<DirControl, Otc::Direction::West + 1> m_offsetDirections;

    PainterShaderProgramPtr m_shader;
    AnimatedTexturePtr m_texture;

    std::string m_name;

    std::vector<AttachedEffectPtr> m_effects;

    friend class Thing;
    friend class AttachedEffectManager;
};
