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

#include <framework/luaengine/luaobject.h>
#include "declarations.h"

class SoundSource : public LuaObject
{
protected:
    SoundSource(uint32_t sourceId) : m_sourceId(sourceId) {}

public:
    enum FadeState { NoFading, FadingOn, FadingOff };

    SoundSource();
    ~SoundSource() override;

    virtual void play();
    virtual void stop();

    virtual bool isBuffering();
    virtual bool isPlaying() { return isBuffering(); }

    void setName(const std::string_view name) { m_name = name; }
    virtual void setLooping(bool looping);
    virtual void setRelative(bool relative);
    virtual void setReferenceDistance(float distance);
    virtual void setGain(float gain);
    virtual void setPitch(float pitch);
    virtual void setPosition(const Point& pos);
    virtual void setVelocity(const Point& velocity);
    virtual void setFading(FadeState state, float fadeTime);

    std::string getName() { return m_name; }
    uint8_t getChannel() const { return m_channel; }
    float getGain() const { return m_gain; }

protected:
    void setBuffer(const SoundBufferPtr& buffer);
    void setChannel(uint8_t channel) { m_channel = channel; }

    virtual void update();
    friend class SoundManager;
    friend class CombinedSoundSource;

    float m_fadeStartTime{ 0 };
    float m_fadeTime{ 0 };
    float m_fadeGain{ 0 };
    float m_gain{ 1.f };

    FadeState m_fadeState{ NoFading };

    uint32_t m_sourceId{ 0 };
    uint8_t m_channel{ 0 };

    std::string m_name;

    SoundBufferPtr m_buffer;
};
