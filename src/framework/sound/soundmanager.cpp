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

#include "soundmanager.h"
#include "combinedsoundsource.h"
#include "soundbuffer.h"
#include "soundfile.h"
#include "soundsource.h"
#include "streamsoundsource.h"

#include <framework/core/asyncdispatcher.h>
#include <framework/core/clock.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/resourcemanager.h>

SoundManager g_sounds;

void SoundManager::init()
{
#ifdef ANDROID
    // The alcOpenDevice call needs to be executed on Android main thread
    g_androidManager.attachToAppMainThread();
#endif
    m_device = alcOpenDevice(nullptr);
    if (!m_device) {
        g_logger.error("unable to open audio device");
        return;
    }

    m_context = alcCreateContext(m_device, nullptr);
    if (!m_context) {
        g_logger.error(stdext::format("unable to create audio context: %s", alcGetString(m_device, alcGetError(m_device))));
        return;
    }

    if (alcMakeContextCurrent(m_context) != ALC_TRUE) {
        g_logger.error(stdext::format("unable to make context current: %s", alcGetString(m_device, alcGetError(m_device))));
    }
}

void SoundManager::terminate()
{
    ensureContext();

    for (auto& streamFile : m_streamFiles) {
        auto& future = streamFile.second;
        future.wait();
    }
    m_streamFiles.clear();

    m_sources.clear();
    m_buffers.clear();
    m_channels.clear();

    m_audioEnabled = false;

    alcMakeContextCurrent(nullptr);

    if (m_context) {
        alcDestroyContext(m_context);
        m_context = nullptr;
    }

    if (m_device) {
        alcCloseDevice(m_device);
        m_device = nullptr;
    }
}

void SoundManager::poll()
{
    static ticks_t lastUpdate = 0;
    const ticks_t now = g_clock.millis();

    if (now - lastUpdate < POLL_DELAY)
        return;

    lastUpdate = now;

    ensureContext();

    for (auto it = m_streamFiles.begin(); it != m_streamFiles.end();) {
        const auto& source = it->first;
        const auto& future = it->second;

        if (future.wait_for(std::chrono::seconds(0)) == std::future_status::ready) {
            const auto& sound = future.get();
            if (sound)
                source->setSoundFile(sound);
            else
                source->stop();

            it = m_streamFiles.erase(it);
        } else {
            ++it;
        }
    }

    for (auto it = m_sources.begin(); it != m_sources.end();) {
        const auto& source = *it;

        source->update();

        if (!source->isPlaying())
            it = m_sources.erase(it);
        else
            ++it;
    }

    for (const auto& it : m_channels) {
        it.second->update();
    }

    if (m_context) {
        alcProcessContext(m_context);
    }
}

void SoundManager::setAudioEnabled(bool enable)
{
    if (m_audioEnabled == enable)
        return;

    m_audioEnabled = enable;
    if (!enable) {
        ensureContext();
        for (const auto& source : m_sources) {
            source->stop();
        }
    }
}

void SoundManager::preload(std::string filename)
{
    filename = resolveSoundFile(filename);

    const auto it = m_buffers.find(filename);
    if (it != m_buffers.end())
        return;

    ensureContext();
    const auto& soundFile = SoundFile::loadSoundFile(filename);

    // only keep small files
    if (!soundFile || soundFile->getSize() > MAX_CACHE_SIZE)
        return;

    const auto& buffer = std::make_shared<SoundBuffer>();
    if (buffer->fillBuffer(soundFile))
        m_buffers[filename] = buffer;
}

SoundSourcePtr SoundManager::play(const std::string& fn, float fadetime, float gain, float pitch)
{
    if (!m_audioEnabled)
        return nullptr;

    ensureContext();

    if (gain == 0)
        gain = 1.0f;

    if (pitch == 0)
        pitch = 1.0f;

    const std::string& filename = resolveSoundFile(fn);
    const auto& soundSource = createSoundSource(filename);
    if (!soundSource) {
        g_logger.error(stdext::format("unable to play '%s'", filename));
        return nullptr;
    }

    soundSource->setName(filename);
    soundSource->setRelative(true);
    soundSource->setGain(gain);
    soundSource->setPitch(pitch);

    if (fadetime > 0)
        soundSource->setFading(StreamSoundSource::FadingOn, fadetime);

    soundSource->play();

    m_sources.emplace_back(soundSource);

    return soundSource;
}

SoundChannelPtr SoundManager::getChannel(int channel)
{
    ensureContext();
    if (!m_channels[channel])
        m_channels[channel] = std::make_shared<SoundChannel>(channel);
    return m_channels[channel];
}

void SoundManager::stopAll()
{
    ensureContext();
    for (const auto& source : m_sources) {
        source->stop();
    }

    for (const auto& it : m_channels) {
        it.second->stop();
    }
}

SoundSourcePtr SoundManager::createSoundSource(const std::string& filename)
{
    SoundSourcePtr source;

    try {
        const auto it = m_buffers.find(filename);
        if (it != m_buffers.end()) {
            source = std::make_shared<SoundSource>();
            source->setBuffer(it->second);
        } else {
#if defined __linux && !defined OPENGL_ES
            // due to OpenAL implementation bug, stereo buffers are always downmixed to mono on linux systems
            // this is hack to work around the issue
            // solution taken from http://opensource.creative.com/pipermail/openal/2007-April/010355.html
            const auto& combinedSource = std::make_shared<CombinedSoundSource>();
            StreamSoundSourcePtr streamSource;

            streamSource = std::make_shared<StreamSoundSource>();
            streamSource->downMix(StreamSoundSource::DownMixLeft);
            streamSource->setRelative(true);
            streamSource->setPosition(Point(-128, 0));
            combinedSource->addSource(streamSource);
            m_streamFiles[streamSource] = g_asyncDispatcher.schedule([=]() -> SoundFilePtr {
                stdext::timer a;
                try {
                    return SoundFile::loadSoundFile(filename);
                } catch (std::exception& e) {
                    g_logger.error(e.what());
                    return nullptr;
                }
            });

            streamSource = std::make_shared<StreamSoundSource>();
            streamSource->downMix(StreamSoundSource::DownMixRight);
            streamSource->setRelative(true);
            streamSource->setPosition(Point(128, 0));
            combinedSource->addSource(streamSource);
            m_streamFiles[streamSource] = g_asyncDispatcher.schedule([=]() -> SoundFilePtr {
                try {
                    return SoundFile::loadSoundFile(filename);
                } catch (std::exception& e) {
                    g_logger.error(e.what());
                    return nullptr;
                }
            });

            source = combinedSource;
#else
            const auto& streamSource = std::make_shared<StreamSoundSource>();
            m_streamFiles[streamSource] = g_asyncDispatcher.schedule([=]() -> SoundFilePtr {
                try {
                    return SoundFile::loadSoundFile(filename);
                } catch (std::exception& e) {
                    g_logger.error(e.what());
                    return nullptr;
                }
            });
            source = streamSource;
#endif
        }
    } catch (std::exception& e) {
        g_logger.error(stdext::format("failed to load sound source: '%s'", e.what()));
        return nullptr;
    }

    return source;
}

std::string SoundManager::resolveSoundFile(const std::string& file)
{
    std::string _file = g_resources.guessFilePath(file, "ogg");
    _file = g_resources.resolvePath(_file);
    return _file;
}

void SoundManager::ensureContext() const
{
    if (m_context)
        alcMakeContextCurrent(m_context);
}