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
#include <optional>

#include "declarations.h"
#include "framebuffer.h"
#include "framework/core/timer.h"
#include "texture.h"

#include "../stdext/storage.h"

enum class PoolType : uint8_t
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

    void setEnable(const bool v) { m_enabled = v; }
    bool isEnabled() const { return m_enabled; }
    PoolType getType() const { return m_type; }

protected:
    struct PoolState
    {
        Matrix3 transformMatrix;
        Color color;
        float opacity;
        CompositionMode compositionMode;
        BlendEquation blendEquation;
        Rect clipRect;
        TexturePtr texture;
        PainterShaderProgram* shaderProgram;
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
        std::optional<std::pair<Rect, Rect>> rects;
        std::optional<std::tuple<Point, Point, Point>> points;
        std::optional<Point> dest;
        uint16_t intValue{ 0 };
    };

    struct DrawObject
    {
        DrawObject(std::function<void()> action) : action(std::move(action)) {}
        DrawObject(const PoolState& state, const DrawBufferPtr& buffer) : state(state), buffer(buffer) {}
        DrawObject(const DrawMode drawMode, const PoolState& state, const DrawMethod& method) :
            drawMode(drawMode), state(state), method(method)
        {}

        void addMethod(const DrawMethod& method)
        {
            if (!methods.has_value()) {
                methods = std::vector<DrawMethod>();
                methods->emplace_back(*this->method);
            }
            drawMode = DrawMode::TRIANGLES;
            methods->emplace_back(method);
        }

        DrawMode drawMode{ DrawMode::TRIANGLES };
        DrawBufferPtr buffer;
        std::optional<PoolState> state;
        std::optional<DrawMethod> method;
        std::optional<std::vector<DrawMethod>> methods;
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
    static constexpr uint8_t ARR_MAX_Z = (MAX_Z / 2) + 1;
    static Pool* create(const PoolType type);

    DrawObject& getLastDrawObject()
    {
        auto& list = m_objects[m_currentFloor][m_currentOrder];
        return list[list.size() - 1];
    }

    void add(const Color& color, const TexturePtr& texture, const Pool::DrawMethod& method,
             DrawMode drawMode = DrawMode::TRIANGLES, const DrawBufferPtr& drawBuffer = nullptr,
             const CoordsBufferPtr& coordsBuffer = nullptr);

    void addCoords(const Pool::DrawMethod& method, CoordsBuffer& buffer, DrawMode drawMode);
    void updateHash(const PoolState& state, const Pool::DrawMethod& method, size_t& stateHash, size_t& methodHash);

    float getOpacity(bool lastDrawing = false) { return !lastDrawing ? m_state.opacity : getLastDrawObject().state->opacity; }
    Rect getClipRect(bool lastDrawing = false) { return !lastDrawing ? m_state.clipRect : getLastDrawObject().state->clipRect; }

    void setCompositionMode(CompositionMode mode, bool onLastDrawing = false);
    void setBlendEquation(BlendEquation equation, bool onLastDrawing = false);
    void setClipRect(const Rect& clipRect, bool onLastDrawing = false);
    void setOpacity(float opacity, bool onLastDrawing = false);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onLastDrawing = false, const std::function<void()>& action = nullptr);

    void resetState();
    void resetOpacity() { m_state.opacity = 1.f; }
    void resetClipRect() { m_state.clipRect = {}; }
    void resetShaderProgram() { m_state.shaderProgram = nullptr; }
    void resetCompositionMode() { m_state.compositionMode = CompositionMode::NORMAL; }
    void resetBlendEquation() { m_state.blendEquation = BlendEquation::ADD; }

    void clear();
    void flush()
    {
        m_objectsByhash.clear();
        if (m_currentFloor < ARR_MAX_Z - 1)
            ++m_currentFloor;
    }

    virtual bool hasFrameBuffer() const { return false; };
    virtual PoolFramed* toPoolFramed() { return nullptr; }

    bool hasModification(bool autoUpdateStatus = false);
    void updateStatus() { m_status.first = m_status.second; m_refreshTime.restart(); }

    bool m_enabled{ true },
        m_alwaysGroupDrawings{ false },
        m_autoUpdate{ false };

    uint8_t m_currentOrder{ 0 }, m_currentFloor{ 0 };

    PoolState m_state;

    PoolType m_type{ PoolType::UNKNOW };

    Timer m_refreshTime;

    std::pair<size_t, size_t> m_status{ 0,0 };

    std::vector<DrawObject> m_objects[ARR_MAX_Z][static_cast<uint8_t>(DrawOrder::LAST)];
    stdext::map<size_t, DrawObject> m_objectsByhash;

    bool m_empty = true;

    friend DrawPool;
};

class PoolFramed : public Pool
{
public:
    void onBeforeDraw(std::function<void()> f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()> f) { m_afterDraw = std::move(f); }
    void setSmooth(bool enabled) { m_framebuffer->setSmooth(enabled); }
    void resize(const Size& size) { m_framebuffer->resize(size); }
    Size getSize() { return m_framebuffer->getSize(); }

protected:
    PoolFramed(const FrameBufferPtr& fb) : m_framebuffer(fb) {};

    friend DrawPool;
    friend Pool;

private:
    bool hasFrameBuffer() const override { return true; }
    PoolFramed* toPoolFramed() override { return this; }

    FrameBufferPtr m_framebuffer;

    std::function<void()> m_beforeDraw, m_afterDraw;
};

extern DrawPool g_drawPool;

class DrawBuffer
{
public:
    DrawBuffer(Pool::DrawOrder order, bool agroup = true) : m_order(order), m_agroup(agroup) {}
    void agroup(bool v) { m_agroup = v; }

private:
    inline bool isValid() { return m_i > -1; }
    inline bool isTemporary() { return m_i == -2; }

    bool validate(const Point& p)
    {
        if (m_ref != p) { m_ref = p; invalidate(); }
        return isValid();
    }

    inline CoordsBuffer* getCoords()
    {
        return (m_coords ? m_coords : m_coords = std::make_shared<CoordsBuffer>()).get();
    }

    void invalidate() { m_i = -1; }
    int m_i{ -1 };
    bool m_agroup{ true };
    Pool::DrawOrder m_order{ Pool::DrawOrder::FIRST };
    Point m_ref;

    std::vector<size_t> m_hashs;
    CoordsBufferPtr m_coords;

    friend class Pool;
    friend class DrawPool;
};
