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

#include <framework/graphics/paintershaderprogram.h>
#include "declarations.h"

 //@bindsingleton g_shaders
class ShaderManager
{
public:
    enum
    {
        ITEM_ID_UNIFORM = 10,
        OUTFIT_ID_UNIFORM = 11,
        MOUNT_ID_UNIFORM = 12,
        SHADER_ID_UNIFORM = 13,
        MAP_ZOOM = 14,
        MAP_WALKOFFSET = 15,
        MAP_CENTER_COORD = 16,
        MAP_GLOBAL_COORD = 17,
    };

    void init();
    void terminate();

    void setupMapShader(const std::string_view name);
    void setupItemShader(const std::string_view name);
    void setupOutfitShader(const std::string_view name);
    void setupMountShader(const std::string_view name);

    void createShader(const std::string_view name);
    void createFragmentShader(const std::string_view name, const std::string_view file);
    void createFragmentShaderFromCode(const std::string_view name, const std::string_view code);

    void addMultiTexture(const std::string_view name, const std::string_view file);

    PainterShaderProgramPtr getShader(const std::string_view name);

private:

    stdext::map<std::string, PainterShaderProgramPtr> m_shaders;
};

extern ShaderManager g_shaders;
