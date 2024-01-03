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
#include <framework/platform/platformwindow.h>
#include <framework/core/graphicalapplication.h>

#include "../stdext/storage.h"

enum class DrawPoolType : uint8_t
{
    MAP,
    CREATURE_INFORMATION,
    LIGHT,
    FOREGROUND_MAP,
    FOREGROUND,
    LAST
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

constexpr DrawConductor DEFAULT_DRAW_CONDUCTOR;

class DrawPool
{
public:
    static constexpr uint16_t
        FPS10 = 1000 / 10,
        FPS20 = 1000 / 20,
        FPS60 = 1000 / 60;

    void setEnable(bool v) { m_enabled = v; }

    DrawPoolType getType() const { return m_type; }

    bool isEnabled() const { return m_enabled; }
    bool isType(DrawPoolType type) const { return m_type == type; }

    bool isValid() const { return !m_framebuffer || m_framebuffer->isValid(); }
    bool hasFrameBuffer() const { return m_framebuffer != nullptr; }
    FrameBufferPtr getFrameBuffer() const { return m_framebuffer; }

    bool canRepaint() { return canRepaint(false); }
    void repaint() { m_status.first = 1; }
    void resetState();
    void scale(float factor);

    void agroup(bool agroup) { m_alwaysGroupDrawings = agroup; }

    void setScaleFactor(float scale) { m_scaleFactor = scale; }
    inline float getScaleFactor() const { return m_scaleFactor; }
    inline bool isScaled() const { return m_scaleFactor != PlatformWindow::DEFAULT_DISPLAY_DENSITY; }

    void setFramebuffer(const Size& size);
    void removeFramebuffer();

    void onBeforeDraw(std::function<void()>&& f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()>&& f) { m_afterDraw = std::move(f); }

    std::mutex& getMutex() { return m_mutexDraw; }
    std::mutex& getMutexPreDraw() { return m_mutexPreDraw; }

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
        DrawObject(PoolState&& state) : state(std::move(state)), coords(std::make_unique<CoordsBuffer>()) {}
        DrawObject(const DrawMode drawMode, PoolState&& state, DrawMethod&& method) :
            drawMode(drawMode), state(std::move(state)) { methods.emplace_back(std::move(method)); }

        void addMethod(DrawMethod&& method)
        {
            drawMode = DrawMode::TRIANGLES;
            methods.emplace_back(std::move(method));
        }

        DrawMode drawMode{ DrawMode::TRIANGLES };
        std::unique_ptr<CoordsBuffer> coords;
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
    static DrawPool* create(const DrawPoolType type);
    static void addCoords(CoordsBuffer* buffer, const DrawPool::DrawMethod& method, DrawMode drawMode);

    enum STATE_TYPE : uint32_t
    {
        STATE_OPACITY = 1 << 0,
        STATE_CLIP_RECT = 1 << 1,
        STATE_SHADER_PROGRAM = 1 << 2,
        STATE_COMPOSITE_MODE = 1 << 3,
        STATE_BLEND_EQUATION = 1 << 4,
    };

    void add(const Color& color, const TexturePtr& texture, DrawPool::DrawMethod&& method,
             DrawMode drawMode = DrawMode::TRIANGLES, const DrawConductor& conductor = DEFAULT_DRAW_CONDUCTOR,
             const CoordsBufferPtr& coordsBuffer = nullptr);

    void addAction(const std::function<void()>& action);
    void bindFrameBuffer(const Size& size, const Color& color = Color::white);
    void releaseFrameBuffer(const Rect& dest);

    inline void setFPS(uint16_t fps) { m_refreshDelay = fps; }

    void updateHash(const DrawPool::DrawMethod& method, const TexturePtr& texture, const Color& color);
    PoolState getState(const TexturePtr& texture, const Color& color);

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
    void translate(float x, float y);
    void translate(const Point& p) { translate(p.x, p.y); }
    void rotate(float angle);
    void rotate(float x, float y, float angle);
    void rotate(const Point& p, float angle) { rotate(p.x, p.y, angle); }

    template<typename T>
    void setParameter(std::string_view name, T&& value) {
        m_parameters.emplace(name, value);
    }
    template<typename T>
    T getParameter(std::string_view name) {
        auto it = m_parameters.find(name);
        if (it != m_parameters.end()) {
            return std::any_cast<T>(it->second);
        }

        return T();
    }
    bool containsParameter(std::string_view name) {
        return m_parameters.contains(name);
    }
    void removeParameter(std::string_view name) {
        const auto& it = m_parameters.find(name);
        if (it != m_parameters.end())
            m_parameters.erase(it);
    }

    void flush()
    {
        m_coords.clear();
        for (auto& objs : m_objects) {
            m_objectsFlushed.insert(m_objectsFlushed.end(), make_move_iterator(objs.begin()), make_move_iterator(objs.end()));
            objs.clear();
        }
    }

    void release(bool draw = true) {
        m_objectsDraw.clear();
        if (draw) {
            if (!m_objectsFlushed.empty())
                m_objectsDraw.insert(m_objectsDraw.end(), make_move_iterator(m_objectsFlushed.begin()), make_move_iterator(m_objectsFlushed.end()));

            for (auto& objs : m_objects) {
                m_objectsDraw.insert(m_objectsDraw.end(), make_move_iterator(objs.begin()), make_move_iterator(objs.end()));
                objs.clear();
            }
        }

        m_objectsFlushed.clear();
    }

    void resetOnlyOnceParameters() {
        if (m_onlyOnceStateFlag > 0) { // Only Once State
            if (m_onlyOnceStateFlag & STATE_OPACITY)
                resetOpacity();

            if (m_onlyOnceStateFlag & STATE_BLEND_EQUATION)
                resetBlendEquation();

            if (m_onlyOnceStateFlag & STATE_CLIP_RECT)
                resetClipRect();

            if (m_onlyOnceStateFlag & STATE_COMPOSITE_MODE)
                resetCompositionMode();

            if (m_onlyOnceStateFlag & STATE_SHADER_PROGRAM)
                resetShaderProgram();

            m_onlyOnceStateFlag = 0;
        }
    }

    bool canRepaint(bool autoUpdateStatus);

    const FrameBufferPtr& getTemporaryFrameBuffer(const uint8_t index);

    bool m_enabled{ true };
    bool m_alwaysGroupDrawings{ false };

    int_fast8_t m_bindedFramebuffers{ -1 };

    uint16_t m_refreshDelay{ 0 }, m_shaderRefreshDelay{ 0 };
    uint32_t m_onlyOnceStateFlag{ 0 };
    uint_fast64_t m_lastFramebufferId{ 0 };

    PoolState m_state, m_oldState;

    DrawPoolType m_type{ DrawPoolType::LAST };

    Timer m_refreshTimer;

    std::pair<size_t, size_t> m_status{ 1, 0 };

    std::vector<Matrix3> m_transformMatrixStack;
    std::vector<FrameBufferPtr> m_temporaryFramebuffers;

    std::vector<DrawObject> m_objects[static_cast<uint8_t>(DrawOrder::LAST)];
    std::vector<DrawObject> m_objectsFlushed;
    std::vector<DrawObject> m_objectsDraw;

    stdext::map<size_t, CoordsBuffer*> m_coords;
    stdext::map<std::string_view, std::any> m_parameters;

    float m_scaleFactor{ 1.f };
    float m_scale{ PlatformWindow::DEFAULT_DISPLAY_DENSITY };

    FrameBufferPtr m_framebuffer;

    std::function<void()> m_beforeDraw;
    std::function<void()> m_afterDraw;

    std::atomic_bool m_repaint{ false };
    std::mutex m_mutexDraw;
    std::mutex m_mutexPreDraw;

    friend class DrawPoolManager;
};

extern DrawPoolManager g_drawPool;
