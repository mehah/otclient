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
#include "texture.h"
#include "framework/core/timer.h"

#include "../stdext/storage.h"

enum class DrawPoolType : uint8_t
{
    MAP,
    CREATURE_INFORMATION,
    LIGHT,
    TEXT,
    FOREGROUND,
    UNKNOW
};

enum DrawOrder : uint8_t
{
    FIRST,  // GROUND
    SECOND, // BORDER
    THIRD,  // BOTTOM & TOP
    FOURTH, // TOP ~ TOP
    FIFTH,  // ABOVE ALL - MISSILE
    LAST
};

struct DrawConductor
{
    bool agroup{ false };
    uint8_t order{ DrawOrder::FIRST };
};

static const DrawConductor DEFAULT_DRAW_CONDUCTOR;

class DrawPool
{
public:

    void setEnable(bool v) { m_enabled = v; }

    DrawPoolType getType() const { return m_type; }

    bool isEnabled() const { return m_enabled; }
    bool isType(DrawPoolType type) const { return m_type == type; }

    bool canRepaint() { return canRepaint(false); }
    void repaint() { m_status.first = 1; }

    virtual bool isValid() const { return true; };

    void optimize(int size);

    void setScaleFactor(float scale) { m_scaleFactor = scale; }
    inline float getScaleFactor() const { return m_scaleFactor; }

    std::mutex& getMutex() { return m_mutex; }

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
        DrawMethodType type{ DrawMethodType::RECT };
        Rect dest, src;
        Point a, b, c;
        uint16_t intValue{ 0 };
    };

    struct PoolState
    {
        Matrix3 transformMatrix = DEFAULT_MATRIX3;
        float opacity{ 1.f };
        CompositionMode compositionMode{ CompositionMode::NORMAL };
        BlendEquation blendEquation{ BlendEquation::ADD };
        Rect clipRect;
        PainterShaderProgram* shaderProgram{ nullptr };
        std::function<void()> action{ nullptr };
        Color color{ Color::white };
        TexturePtr texture;
        size_t hash{ 0 };

        bool operator==(const PoolState& s2) const { return hash == s2.hash; }
        void execute() const;
    };

    struct DrawObject
    {
        DrawObject(std::function<void()> action) : action(std::move(action)) {}
        DrawObject(PoolState& state, const CoordsBufferPtr& coordsBuffer) : coords(coordsBuffer), state(std::move(state)) {}
        DrawObject(const DrawMode drawMode, PoolState& state, DrawMethod& method) :
            drawMode(drawMode), state(std::move(state)) { methods.emplace_back(std::move(method)); }

        void addMethod(DrawMethod& method)
        {
            drawMode = DrawMode::TRIANGLES;
            methods.emplace_back(std::move(method));
        }

        DrawMode drawMode{ DrawMode::TRIANGLES };
        CoordsBufferPtr coords;
        PoolState state;
        std::vector<DrawMethod> methods;
        std::function<void()> action{ nullptr };
    };

    struct DrawObjectState
    {
        CompositionMode compositionMode{ CompositionMode::NORMAL };
        BlendEquation blendEquation{ BlendEquation::ADD };
        Rect clipRect;
        float opacity{ 1.f };
        PainterShaderProgram* shaderProgram{ nullptr };
        std::function<void()> action{ nullptr };
    };

private:
    static void addCoords(CoordsBuffer* buffer, const DrawPool::DrawMethod& method, DrawMode drawMode);

    enum STATE_TYPE : uint32_t
    {
        STATE_OPACITY = 1 << 0,
        STATE_CLIP_RECT = 1 << 1,
        STATE_SHADER_PROGRAM = 1 << 2,
        STATE_COMPOSITE_MODE = 1 << 3,
        STATE_BLEND_EQUATION = 1 << 4,
    };

    static constexpr uint8_t ARR_MAX_Z = MAX_Z + 1;
    static DrawPool* create(const DrawPoolType type);

    void add(const Color& color, const TexturePtr& texture, DrawPool::DrawMethod& method,
             DrawMode drawMode = DrawMode::TRIANGLES, const DrawConductor& conductor = DEFAULT_DRAW_CONDUCTOR,
             const CoordsBufferPtr& coordsBuffer = nullptr);

    void resetState();
    inline void setFPS(uint16_t fps) { m_refreshDelay = fps; }

    PoolState getState(const DrawPool::DrawMethod& method, const TexturePtr& texture, const Color& color);

    float getOpacity() const { return m_state.opacity; }
    Rect getClipRect() { return m_state.clipRect; }

    void setCompositionMode(CompositionMode mode, bool onlyOnce = false);
    void setBlendEquation(BlendEquation equation, bool onlyOnce = false);
    void setClipRect(const Rect& clipRect, bool onlyOnce = false);
    void setOpacity(float opacity, bool onlyOnce = false);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce = false, const std::function<void()>& action = nullptr);

    void resetOpacity() { m_state.opacity = 1.f; }
    void resetClipRect() { m_state.clipRect = {}; }
    void resetShaderProgram() { m_state.shaderProgram = nullptr; m_state.action = nullptr; }
    void resetCompositionMode() { m_state.compositionMode = CompositionMode::NORMAL; }
    void resetBlendEquation() { m_state.blendEquation = BlendEquation::ADD; }
    void resetTransformMatrix() { m_state.transformMatrix = DEFAULT_MATRIX3; }

    void pushTransformMatrix();
    void popTransformMatrix();
    void scale(float x, float y);
    void scale(float factor) { scale(factor, factor); }
    void translate(float x, float y);
    void translate(const Point& p) { translate(p.x, p.y); }
    void rotate(float angle);
    void rotate(float x, float y, float angle);
    void rotate(const Point& p, float angle) { rotate(p.x, p.y, angle); }

    void flush()
    {
        m_objectsByhash.clear();
        if (m_currentFloor < ARR_MAX_Z - 1)
            ++m_currentFloor;
    }

    void disableUpdateHash() {
        m_status.first = 0;
        m_updateHash = false;
    }

    virtual bool hasFrameBuffer() const { return false; };
    virtual DrawPoolFramed* toPoolFramed() { return nullptr; }

    bool canRepaint(bool autoUpdateStatus);

    bool m_enabled{ true };
    bool m_updateHash{ true };
    bool m_alwaysGroupDrawings{ false };

    uint8_t m_currentFloor{ 0 };

    uint16_t m_refreshDelay{ 0 }, m_shaderRefreshDelay{ 0 };
    uint32_t m_onlyOnceStateFlag{ 0 };

    PoolState m_state, m_oldState;

    DrawPoolType m_type{ DrawPoolType::UNKNOW };

    Timer m_refreshTimer;

    std::pair<size_t, size_t> m_status{ 1, 0 };

    std::vector<Matrix3> m_transformMatrixStack;
    std::vector<DrawObject> m_objects[ARR_MAX_Z][static_cast<uint8_t>(DrawOrder::LAST)];

    stdext::map<size_t, DrawObject> m_objectsByhash;

    float m_scaleFactor{ 1.f };

    std::mutex m_mutex;

    friend DrawPoolManager;
};

class DrawPoolFramed : public DrawPool
{
public:
    void onBeforeDraw(std::function<void()> f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()> f) { m_afterDraw = std::move(f); }
    void setSmooth(bool enabled) const { m_framebuffer->setSmooth(enabled); }
    void resize(const Size& size) { if (m_framebuffer->resize(size)) repaint(); }
    Size getSize() const { return m_framebuffer->getSize(); }
    bool isValid() const override { return m_framebuffer->isValid(); }

protected:
    DrawPoolFramed() : m_framebuffer(std::make_shared<FrameBuffer>()) {};

    friend DrawPoolManager;
    friend DrawPool;

private:
    bool hasFrameBuffer() const override { return m_framebuffer->isValid(); }
    DrawPoolFramed* toPoolFramed() override { return this; }

    FrameBufferPtr m_framebuffer;

    std::function<void()> m_beforeDraw;
    std::function<void()> m_afterDraw;
};

extern DrawPoolManager g_drawPool;
