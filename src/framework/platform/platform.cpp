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

#include "platform.h"

Platform g_platform;

std::string Platform::getDeviceShortName(DeviceType type)
{
    static stdext::map<Platform::DeviceType, std::string> deviceShortNames = {
        {Platform::Desktop, "desktop"},
        {Platform::Mobile,  "mobile"},
        {Platform::Console, "console"},
    };

    if (type == DeviceUnknown)
        type = m_device.type;

    auto it = deviceShortNames.find(type);
    if (it == deviceShortNames.end())
        return "";
    return it->second;
}

std::string Platform::getOsShortName(OperatingSystem os)
{
    static stdext::map<Platform::OperatingSystem, std::string> osShortNames = {
        {Platform::Windows, "windows"},
        {Platform::Linux,   "linux"},
        {Platform::macOS,   "macos"},
        {Platform::Android, "android"},
        {Platform::iOS,     "ios"},
    };

    if (os == OsUnknown)
        os = m_device.os;

    auto it = osShortNames.find(os);
    if (it == osShortNames.end())
        return "";
    return it->second;
}
