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

#include <utility>

#include "declarations.h"
#include "framebuffer.h"
#include "framework/core/timer.h"
#include "texture.h"

enum class PoolType : uint8
{
    MAP,
    CREATURE_INFORMATION,
    LIGHT,
    TEXT,
    FOREGROUND,
    UNKNOW
};

class Pool
{
public:
    void setEnable(const bool v) { m_enabled = v; }
    bool isEnabled() const { return m_enabled; }
    PoolType getType() const { return m_type; }

protected:
    enum class DrawMethodType
    {
        RECT,
        TRIANGLE,
        REPEATED_RECT,
        BOUNDING_RECT,
        UPSIDEDOWN_RECT,
    };

    struct DrawMethod
    {
        DrawMethodType type;
        std::pair<Rect, Rect> rects{};
        std::tuple<Point, Point, Point> points{};
        Point dest{};

        uint16 intValue{ 0 };
        size_t hash{ 0 };
    };

    struct DrawObject
    {
        ~DrawObject() { drawMethods.clear(); state.texture = nullptr; action = nullptr; }

        Painter::PainterState state;
        Painter::DrawMode drawMode{ Painter::DrawMode::Triangles };
        std::vector<DrawMethod> drawMethods;

        std::function<void()> action{ nullptr };
    };

private:
    struct State
    {
        ~State() { shaderProgram = nullptr; action = nullptr; }

        Painter::CompositionMode compositionMode;
        Painter::BlendEquation blendEquation;
        Rect clipRect;
        float opacity;
        bool alphaWriting{ true };
        PainterShaderProgram* shaderProgram;
        std::function<void()> action{ nullptr };
    };

    void setCompositionMode(Painter::CompositionMode mode, int pos = -1);
    void setBlendEquation(Painter::BlendEquation equation, int pos = -1);
    void setClipRect(const Rect& clipRect, int pos = -1);
    void setOpacity(float opacity, int pos = -1);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, int pos = -1, const std::function<void()>& action = nullptr);

    float getOpacity(const int pos = -1) { return pos == -1 ? m_state.opacity : m_objects[pos - 1].state.opacity; }

    void resetClipRect() { m_state.clipRect = {}; }
    void resetCompositionMode() { m_state.compositionMode = Painter::CompositionMode_Normal; }
    void resetOpacity() { m_state.opacity = 1.f; }
    void resetShaderProgram() { m_state.shaderProgram = nullptr; }
    void resetState();
    void startPosition() { m_indexToStartSearching = m_objects.size(); }

    virtual bool hasFrameBuffer() const { return false; };
    virtual PoolFramed* toPoolFramed() { return nullptr; }

    std::vector<DrawObject> m_objects;

    bool m_enabled{ true }, m_forceGrouping{ false };
    State m_state;

    uint16_t m_indexToStartSearching{ 0 };

    PoolType m_type;

    friend class DrawPool;
};

class PoolFramed : public Pool
{
public:
    void onBeforeDraw(std::function<void()> f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()> f) { m_afterDraw = std::move(f); }
    void resize(const Size& size) { m_framebuffer->resize(size); }
    void setSmooth(bool enabled) { m_framebuffer->setSmooth(enabled); }
    Size getSize() { return m_framebuffer->getSize(); }

protected:
    bool m_autoUpdate{ false };

    friend class DrawPool;
    friend class Pool;

private:
    void updateStatus() { m_status.first = m_status.second; m_refreshTime.restart(); }
    void resetCurrentStatus() { m_status.second = 0; }
    bool hasModification(bool autoUpdateStatus = false);
    bool hasFrameBuffer() const override { return m_framebuffer != nullptr; }

    PoolFramed* toPoolFramed() override { return this; }

    FrameBufferPtr m_framebuffer;
    Rect m_dest, m_src;

    std::function<void()> m_beforeDraw, m_afterDraw;
    std::pair<size_t, size_t> m_status{ 0,0 };
    Timer m_refreshTime;
};

extern DrawPool g_drawPool;
