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

#include <future>
#include "declarations.h"
#include "soundchannel.h"

 //@bindsingleton g_sounds
class SoundManager
{
    enum
    {
        MAX_CACHE_SIZE = 100000,
        POLL_DELAY = 100
    };
public:
    void init();
    void terminate();
    void poll();

    void setAudioEnabled(bool enable);
    bool isAudioEnabled() { return m_device && m_context && m_audioEnabled; }
    void enableAudio() { setAudioEnabled(true); }
    void disableAudio() { setAudioEnabled(false); }
    void stopAll();

    void preload(std::string filename);
    SoundSourcePtr play(const std::string& fn, float fadetime = 0, float gain = 1.0f, float pitch = 1.0f);
    SoundChannelPtr getChannel(int channel);

    std::string resolveSoundFile(const std::string& file);
    void ensureContext() const;

private:
    SoundSourcePtr createSoundSource(const std::string& filename);

    ALCdevice* m_device{};
    ALCcontext* m_context{};

    stdext::map<StreamSoundSourcePtr, std::shared_future<SoundFilePtr>> m_streamFiles;
    stdext::map<std::string, SoundBufferPtr> m_buffers;
    stdext::map<int, SoundChannelPtr> m_channels;

    std::vector<SoundSourcePtr> m_sources;
    bool m_audioEnabled{ true };
};

extern SoundManager g_sounds;
