/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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
#include <framework/core/graphicalapplication.h>
#include <framework/platform/platformwindow.h>

#include "../stdext/storage.h"
#include <unordered_set>

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

struct DrawHashController
{
    DrawHashController(bool agroup = false) : m_agroup(agroup) {}

    bool put(size_t hash) {
        if ((m_agroup && m_hashs.emplace(hash).second) || m_lastObjectHash != hash) {
            m_lastObjectHash = hash;
            stdext::hash_union(m_currentHash, hash);
            return true;
        }

        return false;
    }

    bool isLast(const size_t hash) const {
        return m_lastObjectHash == hash;
    }

    void forceUpdate() {
        m_currentHash = 1;
    }

    bool wasModified() const {
        return m_currentHash != m_lastHash;
    }

    void reset() {
        m_hashs.clear();
        m_lastHash = m_currentHash;
        m_currentHash = 0;
        m_lastObjectHash = 0;
    }

private:
    stdext::set<size_t> m_hashs;

    size_t m_lastHash{ 0 };
    size_t m_currentHash{ 0 };
    size_t m_lastObjectHash{ 0 };
    bool m_agroup{ false };
};

struct DrawConductor
{
    bool agroup{ false };
    uint8_t order{ FIRST };
};

constexpr DrawConductor DEFAULT_DRAW_CONDUCTOR;

class DrawPool
{
public:
    static constexpr uint16_t
        FPS10 = 1000 / 10,
        FPS20 = 1000 / 20,
        FPS60 = 1000 / 60;

    void setEnable(const bool v) { m_enabled = v; }

    DrawPoolType getType() const { return m_type; }

    bool isEnabled() const { return m_enabled; }
    bool isType(const DrawPoolType type) const { return m_type == type; }

    bool isValid() const { return !m_framebuffer || m_framebuffer->isValid(); }
    bool hasFrameBuffer() const { return m_framebuffer != nullptr; }
    FrameBufferPtr getFrameBuffer() const { return m_framebuffer; }

    bool canRepaint();
    void repaint() { if (hasFrameBuffer()) m_hashCtrl.forceUpdate(); m_refreshTimer.update(-1000); }
    void resetState();
    void scale(float factor);

    void agroup(const bool agroup) { m_alwaysGroupDrawings = agroup; }

    void setScaleFactor(const float scale) { m_scaleFactor = scale; }
    float getScaleFactor() const { return m_scaleFactor; }
    bool isScaled() const { return m_scaleFactor != PlatformWindow::DEFAULT_DISPLAY_DENSITY; }

    void setFramebuffer(const Size& size);
    void removeFramebuffer();

    void onBeforeDraw(std::function<void()>&& f) { m_beforeDraw = std::move(f); }
    void onAfterDraw(std::function<void()>&& f) { m_afterDraw = std::move(f); }

    std::mutex& getMutex() { return m_mutexDraw; }

    bool isDrawing() const {
        return m_repaint;
    }

    auto& getHashController() {
        return m_hashCtrl;
    }

    void resetBuffer() {
        std::scoped_lock l(m_mutexDraw);
        for (auto& buffer : m_coordsCache) {
            buffer.coords.clear();
            buffer.last = 0;
        }
    }

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
        Rect dest{}, src{};
        Point a{}, b{}, c{};
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
        uint32_t textureId{ 0 };
        uint16_t textureMatrixId{ 0 };
        size_t hash{ 0 };

        bool operator==(const PoolState& s2) const { return hash == s2.hash; }
        void execute() const;
    };

    struct DrawObject
    {
        DrawObject(std::function<void()> action) : action(std::move(action)) {}
        DrawObject(PoolState&& state, const std::shared_ptr<CoordsBuffer>& coords) : coords(coords), state(std::move(state)) {}
        std::function<void()> action{ nullptr };
        std::shared_ptr<CoordsBuffer> coords;
        PoolState state;
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
    static DrawPool* create(DrawPoolType type);
    static void addCoords(CoordsBuffer* buffer, const DrawMethod& method);

    enum STATE_TYPE : uint32_t
    {
        STATE_OPACITY = 1 << 0,
        STATE_CLIP_RECT = 1 << 1,
        STATE_SHADER_PROGRAM = 1 << 2,
        STATE_COMPOSITE_MODE = 1 << 3,
        STATE_BLEND_EQUATION = 1 << 4,
    };

    void add(const Color& color, const TexturePtr& texture, DrawMethod&& method, const DrawConductor& conductor = DEFAULT_DRAW_CONDUCTOR,
             const CoordsBufferPtr& coordsBuffer = nullptr);

    void addAction(const std::function<void()>& action);
    void bindFrameBuffer(const Size& size, const Color& color = Color::white);
    void releaseFrameBuffer(const Rect& dest);

    void setFPS(const uint16_t fps) { m_refreshDelay = 1000 / fps; }

    bool updateHash(const DrawMethod& method, const TexturePtr& texture, const Color& color, bool hasCoord);
    PoolState getState(const TexturePtr& texture, const Color& color);

    PoolState& getCurrentState() { return m_states[m_lastStateIndex]; }
    const PoolState& getCurrentState() const { return m_states[m_lastStateIndex]; }

    float getOpacity() const { return getCurrentState().opacity; }
    Rect getClipRect() { return getCurrentState().clipRect; }

    void setCompositionMode(CompositionMode mode, bool onlyOnce = false);
    void setBlendEquation(BlendEquation equation, bool onlyOnce = false);
    void setClipRect(const Rect& clipRect, bool onlyOnce = false);
    void setOpacity(float opacity, bool onlyOnce = false);
    void setShaderProgram(const PainterShaderProgramPtr& shaderProgram, bool onlyOnce = false, const std::function<void()>& action = nullptr);

    void resetOpacity() { getCurrentState().opacity = 1.f; }
    void resetClipRect() { getCurrentState().clipRect = {}; }
    void resetShaderProgram() { getCurrentState().shaderProgram = nullptr; getCurrentState().action = nullptr; }
    void resetCompositionMode() { getCurrentState().compositionMode = CompositionMode::NORMAL; }
    void resetBlendEquation() { getCurrentState().blendEquation = BlendEquation::ADD; }
    void resetTransformMatrix() { getCurrentState().transformMatrix = DEFAULT_MATRIX3; }

    void pushTransformMatrix();
    void popTransformMatrix();
    void translate(float x, float y);
    void translate(const Point& p) { translate(p.x, p.y); }
    void rotate(float angle);
    void rotate(float x, float y, float angle);
    void rotate(const Point& p, const float angle) { rotate(p.x, p.y, angle); }

    std::shared_ptr<CoordsBuffer> getCoordsBuffer();

    template<typename T>
    void setParameter(std::string_view name, T&& value) {
        m_parameters.emplace(name, value);
    }
    template<typename T>
    T getParameter(const std::string_view name) {
        const auto it = m_parameters.find(name);
        if (it != m_parameters.end()) {
            return std::any_cast<T>(it->second);
        }

        return T();
    }
    bool containsParameter(const std::string_view name) {
        return m_parameters.contains(name);
    }
    void removeParameter(const std::string_view name) {
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

    void release(const bool flush = true) {
        m_objectsDraw.clear();

        if (flush) {
            if (!m_objectsFlushed.empty()) {
                if (m_objectsDraw.size() < m_objectsFlushed.size())
                    m_objectsDraw.swap(m_objectsFlushed);

                if (!m_objectsFlushed.empty())
                    m_objectsDraw.insert(m_objectsDraw.end(), make_move_iterator(m_objectsFlushed.begin()), make_move_iterator(m_objectsFlushed.end()));
            }

            for (auto& objs : m_objects) {
                if (m_objectsDraw.size() < objs.size())
                    m_objectsDraw.swap(objs);

                if (!objs.empty()) {
                    m_objectsDraw.insert(m_objectsDraw.end(), make_move_iterator(objs.begin()), make_move_iterator(objs.end()));
                    objs.clear();
                }
            }
        }

        m_objectsFlushed.clear();
        std::swap(m_coordsCache[0], m_coordsCache[1]);
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

    void nextStateAndReset() {
        m_states[++m_lastStateIndex] = {};
    }

    void backState() {
        --m_lastStateIndex;
    }

    const FrameBufferPtr& getTemporaryFrameBuffer(uint8_t index);

    bool m_enabled{ true };
    bool m_alwaysGroupDrawings{ false };

    int_fast8_t m_bindedFramebuffers{ -1 };

    uint16_t m_refreshDelay{ 0 }, m_shaderRefreshDelay{ 0 };
    uint32_t m_onlyOnceStateFlag{ 0 };
    uint_fast64_t m_lastFramebufferId{ 0 };

    PoolState m_states[10];
    uint_fast8_t m_lastStateIndex{ 0 };

    DrawPoolType m_type{ DrawPoolType::LAST };

    Timer m_refreshTimer;

    DrawHashController m_hashCtrl;

    std::vector<Matrix3> m_transformMatrixStack;
    std::vector<FrameBufferPtr> m_temporaryFramebuffers;

    std::vector<DrawObject> m_objects[static_cast<uint8_t>(LAST)];
    std::vector<DrawObject> m_objectsFlushed;
    std::vector<DrawObject> m_objectsDraw;

    struct
    {
        std::vector<std::shared_ptr<CoordsBuffer>> coords;
        uint_fast32_t last{ 0 };
    } m_coordsCache[2];

    stdext::map<size_t, CoordsBuffer*> m_coords;
    stdext::map<std::string_view, std::any> m_parameters;

    float m_scaleFactor{ 1.f };
    float m_scale{ PlatformWindow::DEFAULT_DISPLAY_DENSITY };

    FrameBufferPtr m_framebuffer;

    std::function<void()> m_beforeDraw;
    std::function<void()> m_afterDraw;

    std::atomic_bool m_repaint{ false };
    std::mutex m_mutexDraw;

    friend class DrawPoolManager;
};

extern DrawPoolManager g_drawPool;
