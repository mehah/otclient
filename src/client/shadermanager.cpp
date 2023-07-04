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

#include "shadermanager.h"
#include <framework/core/eventdispatcher.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/graphics.h>
#include <framework/graphics/paintershaderprogram.h>
#include <framework/graphics/shader/shadersources.h>

ShaderManager g_shaders;

void ShaderManager::init() { PainterShaderProgram::release(); }
void ShaderManager::terminate() { m_shaders.clear(); }

void ShaderManager::createShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([&, name = name.data()] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        m_shaders[name] = shader;
        return shader;
    });
}

void ShaderManager::createFragmentShader(const std::string_view name, const std::string_view file)
{
    const auto& filePath = g_resources.resolvePath(file.data());
    g_mainDispatcher.addEvent([&, name = name.data(), filePath] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        if (!shader)
            return;

        const auto& path = g_resources.guessFilePath(filePath, "frag");

        shader->addShaderFromSourceCode(ShaderType::VERTEX, std::string{ glslMainWithTexCoordsVertexShader } + glslPositionOnlyVertexShader.data());
        if (!shader->addShaderFromSourceFile(ShaderType::FRAGMENT, path)) {
            g_logger.error(stdext::format("unable to load fragment shader '%s' from source file '%s'", name, path));
            return;
        }

        if (!shader->link()) {
            g_logger.error(stdext::format("unable to link shader '%s' from file '%s'", name, path));
            return;
        }

        m_shaders[name] = shader;
    });
}

void ShaderManager::createFragmentShaderFromCode(const std::string_view name, const std::string_view code)
{
    g_mainDispatcher.addEvent([&, name = name.data(), code = code.data()] {
        const auto& shader = std::make_shared<PainterShaderProgram>();
        if (!shader)
            return;

        shader->addShaderFromSourceCode(ShaderType::VERTEX, std::string{ glslMainWithTexCoordsVertexShader } + glslPositionOnlyVertexShader.data());
        if (!shader->addShaderFromSourceCode(ShaderType::FRAGMENT, code)) {
            g_logger.error(stdext::format("unable to load fragment shader '%s'", name));
            return;
        }

        if (!shader->link()) {
            g_logger.error(stdext::format("unable to link shader '%s'", name));
            return;
        }

        m_shaders[name] = shader;
    });
}

void ShaderManager::setupItemShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([&, name = name.data()] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(ITEM_ID_UNIFORM, "u_ItemId");
    });
}

void ShaderManager::setupOutfitShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([&, name = name.data()] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(OUTFIT_ID_UNIFORM, "u_OutfitId");
    });
}

void ShaderManager::setupMountShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([&, name = name.data()] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(MOUNT_ID_UNIFORM, "u_MountId");
    });
}

void ShaderManager::setupMapShader(const std::string_view name)
{
    g_mainDispatcher.addEvent([&, name = name.data()] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->bindUniformLocation(MAP_CENTER_COORD, "u_MapCenterCoord");
        shader->bindUniformLocation(MAP_GLOBAL_COORD, "u_MapGlobalCoord");
        shader->bindUniformLocation(MAP_WALKOFFSET, "u_WalkOffset");
        shader->bindUniformLocation(MAP_ZOOM, "u_MapZoom");
    });
}

void ShaderManager::addMultiTexture(const std::string_view name, const std::string_view file)
{
    const auto& filePath = g_resources.resolvePath(file.data());
    g_mainDispatcher.addEvent([&, name = name.data(), filePath] {
        const auto& shader = getShader(name);
        if (!shader) return;
        shader->addMultiTexture(filePath);
    });
}

PainterShaderProgramPtr ShaderManager::getShader(const std::string_view name)
{
    const auto it = m_shaders.find(name.data());
    if (it != m_shaders.end())
        return it->second;

    return nullptr;
}