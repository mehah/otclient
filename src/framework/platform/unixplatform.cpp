/*
 * Copyright (c) 2010-2016 OTClient <https://github.com/edubart/otclient>
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

#if !defined(WIN32) && !defined(__EMSCRIPTEN__)

#include "platform.h"
#include <cstring>
#include <fstream>
#include <unistd.h>
#include <framework/stdext/stdext.h>
#include <framework/core/eventdispatcher.h>

#include <sys/stat.h>

#ifdef ANDROID
#include <errno.h>
#else
#include <execinfo.h>
#endif

void Platform::init(std::vector<std::string>& args)
{
    processArgs(args);

#ifdef __APPLE__
    #include "TargetConditionals.h"
    #if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || (defined(TARGET_OS_SIMULATOR) && TARGET_OS_SIMULATOR)
        setDevice({ Mobile, iOS });
    #else
        setDevice({ Desktop, macOS });
    #endif
#elifdef ANDROID
    setDevice({ Mobile, Android });
#else
    setDevice({ Desktop, Linux });
#endif
}

void Platform::processArgs(std::vector<std::string>& /*args*/)
{
    //nothing todo, linux args are already utf8 encoded
}

bool Platform::spawnProcess(std::string process, const std::vector<std::string>& args)
{
    struct stat sts;
    if(stat(process.c_str(), &sts) == -1 && errno == ENOENT)
        return false;

    pid_t pid = fork();
    if(pid == -1)
        return false;

    if(pid == 0) {
        std::vector<char*> cargs;
        cargs.push_back(const_cast<char*>(process.c_str()));
        for(const auto& arg : args) {
            cargs.push_back(const_cast<char*>(arg.c_str()));
        }
        cargs.push_back(nullptr);

        execv(process.c_str(), cargs.data());
        _exit(EXIT_FAILURE);
    }

    return true;
}

int Platform::getProcessId()
{
    return getpid();
}

bool Platform::isProcessRunning(const std::string_view /*name*/)
{
    return false;
}

bool Platform::killProcess(const std::string_view /*name*/)
{
    return false;
}

std::string Platform::getTempPath()
{
    return "/tmp/";
}

std::string Platform::getCurrentDir()
{
    std::string res;
    char cwd[2048];
    if(getcwd(cwd, sizeof(cwd)) != nullptr) {
        res = cwd;
        res += "/";
    }
    return res;
}

bool Platform::copyFile(std::string from, std::string to)
{
    return system(fmt::format("/bin/cp '{}' '{}'", from, to).c_str()) == 0;
}

bool Platform::fileExists(std::string file)
{
    struct stat buffer;
    return (stat(file.c_str(), &buffer) == 0);
}

bool Platform::removeFile(std::string file)
{
    if(unlink(file.c_str()) == 0)
        return true;
    return false;
}

ticks_t Platform::getFileModificationTime(std::string file)
{
    struct stat attrib;
    if(stat(file.c_str(), &attrib) == 0)
        return attrib.st_mtime;
    return 0;
}

bool Platform::openUrl(std::string url, bool now)
{
    if(url.find("http://") == std::string::npos && url.find("https://") == std::string::npos)
        url.insert(0, "http://");

    const auto& action = [url] {
#if defined(__APPLE__)
        return system(fmt::format("open {}", url).c_str()) == 0;
#else
        return system(fmt::format("xdg-open {}", url).c_str()) == 0;
#endif
    };

    if (now)
        return action();

    g_dispatcher.scheduleEvent(action, 50);
	
	return true;
}

bool Platform::openDir(std::string path, bool now)
{
    const auto& action = [path] {
        return system(fmt::format("xdg-open {}", path).c_str()) == 0;
    };
	
    if(now)
        return action();
	
    g_dispatcher.scheduleEvent(action, 50);
	
	return true;
}

std::string Platform::getCPUName()
{
    std::string line;
    std::ifstream in("/proc/cpuinfo");
    while(getline(in, line)) {
        auto strs = stdext::split(line, ":");
        if(strs.size() == 2) {
            stdext::trim(strs[0]);
            if(strs[0] == "model name") {
                stdext::trim(strs[1]);
                return strs[1];
            }
        }
    }
    return std::string();
}

double Platform::getTotalSystemMemory()
{
    std::string line;
    std::ifstream in("/proc/meminfo");
    while(getline(in, line)) {
        auto strs = stdext::split(line, ":");
        if(strs.size() == 2) {
            stdext::trim(strs[0]);
            if(strs[0] == "MemTotal") {
                stdext::trim(strs[1]);
                return stdext::unsafe_cast<double>(strs[1].substr(0, strs[1].length() - 3)) * 1000;
            }
        }
    }
    return 0;
}

std::string Platform::getOSName()
{
    std::string line;
    std::ifstream in("/etc/issue");
    if(getline(in, line)) {
        auto res = line.substr(0, line.find('\\'));
        stdext::trim(res);
        return res;
    }
    return std::string();
}

std::string Platform::traceback(const std::string_view where, int level, int maxDepth)
{
#ifndef ANDROID
    std::stringstream ss;

    ss << "\nC++ stack traceback:";
    if(!where.empty())
        ss << "\n\t[C++]: " << where;

    const int size = maxDepth + level + 1;
    std::vector<void*> buffer(size);

    int numLevels = backtrace(buffer.data(), size);
    char **tracebackBuffer = backtrace_symbols(buffer.data(), numLevels);
    if(tracebackBuffer) {
        for(int i = 1 + level; i < numLevels; i++) {
            std::string line = tracebackBuffer[i];
            if(line.find("__libc_start_main") != std::string::npos)
                break;
            std::size_t demanglePos = line.find("(_Z");
            if(demanglePos != std::string::npos) {
                demanglePos++;
                int len = std::min(line.find_first_of("+", demanglePos), line.find_first_of(")", demanglePos)) - demanglePos;
                std::string funcName = line.substr(demanglePos, len);
                line.replace(demanglePos, len, stdext::demangle_name(funcName.c_str()));
            }
            ss << "\n\t" << line;
        }
        free(tracebackBuffer);
    }

    return ss.str();
#else
    std::stringstream ss;
    ss << "\nat:";
    ss << "\n\t[C++]: " << where;
    return ss.str();
#endif
}


#endif