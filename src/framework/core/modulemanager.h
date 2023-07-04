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

#include "module.h"

 // @bindsingleton g_modules
class ModuleManager
{
public:
    void clear();

    void discoverModules();
    void autoLoadModules(int maxPriority);
    ModulePtr discoverModule(const std::string& moduleFile);
    void ensureModuleLoaded(const std::string_view moduleName);
    void unloadModules();
    void reloadModules();

    ModulePtr getModule(const std::string_view moduleName);
    std::deque<ModulePtr> getModules() { return m_modules; }
    ModulePtr getCurrentModule() { return m_currentModule; }

protected:
    void updateModuleLoadOrder(const ModulePtr& module);

    friend class Module;

private:
    std::deque<ModulePtr> m_modules;
    std::multimap<int, ModulePtr> m_autoLoadModules;
    ModulePtr m_currentModule;
};

extern ModuleManager g_modules;
