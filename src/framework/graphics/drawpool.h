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

class DrawPool
{
public:
    enum class DrawOrder
    {
        NONE = -1,
        FIRST,  // GROUND
        SECOND, // BORDER
        THIRD,  // BOTTOM & TOP
        FOURTH, // TOP ~ TOP
        FIFTH,  // ABOVE ALL - MISSILE
        LAST
    };

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

    void resetState();

    std::mutex& getMutex() { return m_mutex; }

    struct PoolState
    {
        Matrix3 transformMatrix;
        Color color;
        float opacity{ 1.f };
        CompositionMode compositionMode{ CompositionMode::NORMAL };
        BlendEquation blendEquation{ BlendEquation::ADD };
        Rect clipRect;
        TexturePtr texture;
        PainterShaderProgram* shaderProgram{ nullptr };
        std::function<void()> action{ nullptr };

        bool operator==(const PoolState& s2) const
        {
            return
                transformMatrix == s2.transformMatrix &&
                color == s2.color &&
                opacity == s2.opacity &&
                compositionMode == s2.compositionMode &&
                blendEquation == s2.blendEquation &&
                clipRect == s2.clipRect &&
                texture == s2.texture &&
                shaderProgram == s2.shaderProgram;
        }
    };

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
        std::pair<Rect, Rect> rects;
        std::tuple<Point, Point, Point> points;
        Point dest;
        uint16_t intValue{ 0 };
    };

    struct DrawObject
    {
        DrawObject(std::function<void()> action) : action(std::move(action)) {}
        DrawObject(const PoolState& state, const DrawBufferPtr& buffer) : buffer(buffer), state(state) {}
        DrawObject(const DrawMode drawMode, const PoolState& state, const DrawMethod& method) :
            drawMode(drawMode), state(state), method(method)
        {}

        void addMethod(const DrawMethod& method)
        {
            if (methods.empty())
                methods.emplace_back(this->method);

            drawMode = DrawMode::TRIANGLES;
            methods.emplace_back(method);
        }

        DrawMode drawMode{ DrawMode::TRIANGLES };
        DrawBufferPtr buffer;
        PoolState state;
        DrawMethod method;
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
    static void addCoords(const DrawPool::DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode);

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

    void add(const Color& color, const TexturePtr& texture, const DrawPool::DrawMethod& method,
             DrawMode drawMode = DrawMode::TRIANGLES, const DrawBufferPtr& drawBuffer = nullptr,
             const CoordsBufferPtr& coordsBuffer = nullptr);

    void updateHash(const PoolState& state, const DrawPool::DrawMethod& method, size_t& stateHash, size_t& methodHash);

    float getOpacity() { return m_state.opacity; }
    Rect getClipRect() { return m_state.clipRect; }

    void setCompositionMode(CompositionMode mode, bool onLastDrawing = false);
    void setBlendEquation(BlendEquation equation, bool onLastDrawing = false);
    void setClipRect(const Rect& clipRect, bool onLastDrawing = false);
    void setOpacity(float opacity, bool onLastDrawing = false);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onLastDrawing = false, const std::function<void()>& action = nullptr);

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

    void clear();
    void flush()
    {
        m_objectsByhash.clear();
        if (m_currentFloor < ARR_MAX_Z - 1)
            ++m_currentFloor;
    }

    virtual bool hasFrameBuffer() const { return false; };
    virtual DrawPoolFramed* toPoolFramed() { return nullptr; }

    bool canRepaint(bool autoUpdateStatus);

    bool m_enabled{ true };
    bool m_alwaysGroupDrawings{ false };
    bool m_autoUpdate{ false };

    uint8_t m_currentOrder{ 0 };
    uint8_t m_currentFloor{ 0 };

    uint16_t m_refreshTimeMS{ 0 };
    uint32_t m_onlyOnceStateFlag{ 0 };

    PoolState m_state;

    DrawPoolType m_type{ DrawPoolType::UNKNOW };

    Timer m_refreshTimer;

    std::pair<size_t, size_t> m_status{ 1, 0 };

    std::vector<DrawObject> m_objects[ARR_MAX_Z][static_cast<uint8_t>(DrawOrder::LAST)];
    stdext::map<size_t, DrawObject> m_objectsByhash;

    std::vector<Matrix3> m_transformMatrixStack;

    float m_scaleFactor{ 1.f };

    std::mutex m_mutex;

    friend DrawPoolManager;
};

class DrawPoolFramed : public DrawPool
{
public:
    void onBeforeDraw(std::function<void()> f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()> f) { m_afterDraw = std::move(f); }
    void setSmooth(bool enabled) { m_framebuffer->setSmooth(enabled); }
    void resize(const Size& size) { if (m_framebuffer->resize(size)) repaint(); }
    Size getSize() { return m_framebuffer->getSize(); }
    bool isValid() const override { return m_framebuffer->isValid(); }

protected:
    DrawPoolFramed(const FrameBufferPtr& fb) : m_framebuffer(fb) {};

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

class DrawBuffer
{
public:
    DrawBuffer(DrawPool::DrawOrder order, bool agroup = true) : m_agroup(agroup), m_order(order) {}
    void agroup(bool v) { m_agroup = v; }
    void setOrder(DrawPool::DrawOrder order) { m_order = order; }

    void invalidate() { m_i = -1; }

private:
    static DrawBufferPtr createTemporaryBuffer(DrawPool::DrawOrder order)
    {
        auto buffer = std::make_shared<DrawBuffer>(order);
        buffer->m_i = -2; // identifier to say it is a temporary buffer.
        return buffer;
    }

    inline bool isValid() { return m_i != -1; }
    inline bool isTemporary() { return m_i == -2; }

    bool validate(const Point& p)
    {
        const size_t hash = p.hash();
        if (m_ref != hash) { m_ref = hash; invalidate(); }
        return isValid();
    }

    inline CoordsBuffer* getCoords() { return (m_coords ? m_coords : m_coords = std::make_shared<CoordsBuffer>()).get(); }

    int m_i{ -1 };
    bool m_agroup{ true };

    DrawPool::DrawOrder m_order{ DrawPool::DrawOrder::FIRST };
    size_t m_ref;
    size_t m_stateHash{ 0 };

    std::vector<size_t> m_hashs;
    CoordsBufferPtr m_coords;

    friend class DrawPool;
    friend class DrawPoolManager;
};
