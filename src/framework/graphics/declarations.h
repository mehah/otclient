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

#include <framework/global.h>
#include "glutil.h"

enum class DrawPoolType : uint8_t;

class Texture;
class TextureManager;
class Image;
class AnimatedTexture;
class BitmapFont;
class CachedText;
class FrameBuffer;
class FrameBufferManager;
class Shader;
class ShaderProgram;
class PainterShaderProgram;
class Particle;
class ParticleType;
class ParticleEmitter;
class ParticleAffector;
class ParticleSystem;
class ParticleEffect;
class ParticleEffectType;
class SpriteSheet;
class DrawPool;
class DrawPoolManager;
class CoordsBuffer;

using ImagePtr = std::shared_ptr<Image>;
using TexturePtr = std::shared_ptr<Texture>;
using AnimatedTexturePtr = std::shared_ptr<AnimatedTexture>;
using BitmapFontPtr = std::shared_ptr<BitmapFont>;
using CachedTextPtr = std::shared_ptr<CachedText>;
using FrameBufferPtr = std::shared_ptr<FrameBuffer>;
using ShaderPtr = std::shared_ptr<Shader>;
using ShaderProgramPtr = std::shared_ptr<ShaderProgram>;
using PainterShaderProgramPtr = std::shared_ptr<PainterShaderProgram>;
using ParticlePtr = std::shared_ptr<Particle>;
using ParticleTypePtr = std::shared_ptr<ParticleType>;
using ParticleEmitterPtr = std::shared_ptr<ParticleEmitter>;
using ParticleAffectorPtr = std::shared_ptr<ParticleAffector>;
using ParticleSystemPtr = std::shared_ptr<ParticleSystem>;
using ParticleEffectPtr = std::shared_ptr<ParticleEffect>;
using SpriteSheetPtr = std::shared_ptr<SpriteSheet>;
using ShaderList = std::vector<ShaderPtr>;

using CoordsBufferPtr = std::shared_ptr<CoordsBuffer>;

using ParticleEffectTypePtr = std::shared_ptr<ParticleEffectType>;
