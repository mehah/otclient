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

#include <filesystem>
#include <set>
#include "declarations.h"

 // @bindsingleton g_resources
class ResourceManager
{
public:
    // @dontbind
    void init(const char *argv0);
    // @dontbind
    void terminate();

    bool launchCorrect(std::vector<std::string>& args);
    bool setupWriteDir(const std::string& product, const std::string& app);
    bool setup();

    bool loadDataFromSelf(bool unmountIfMounted = false);

    bool setWriteDir(const std::string& writeDir, bool create = false);
    bool addSearchPath(const std::string& path, bool pushFront = false);
    bool removeSearchPath(const std::string& path);
    void searchAndAddPackages(const std::string& packagesDir, const std::string& packageExt);

    bool fileExists(const std::string& fileName);
    bool directoryExists(const std::string& directoryName);

    // @dontbind
    void readFileStream(const std::string& fileName, std::iostream& out);
    std::string readFileContents(const std::string& fileName, bool safe = false);
    std::string readFileContentsSafe(const std::string& fileName) { return readFileContents(fileName, true); }
    bool isFileEncryptedOrCompressed(const std::string& fileName);
    // @dontbind
    bool writeFileBuffer(const std::string& fileName, const uint8_t* data, uint32_t size, bool createDirectory = false);
    bool writeFileContents(const std::string& fileName, const std::string& data);
    // @dontbind
    bool writeFileStream(const std::string& fileName, std::iostream& in);

    FileStreamPtr openFile(const std::string& fileName, bool dontCache = false);
    FileStreamPtr appendFile(const std::string& fileName);
    FileStreamPtr createFile(const std::string& fileName);
    bool deleteFile(const std::string& fileName);

    bool makeDir(const std::string directory);
    std::list<std::string> listDirectoryFiles(const std::string & directoryPath = "", bool fullPath = false, bool raw = false, bool recursive = false);

    std::string resolvePath(const std::string& path);
    std::string getWorkDir() { return "/"; }
#ifdef ANDROID
    std::string getWriteDir() { return "/"; }
    std::string getBinaryName() { return "otclient.apk"; }
#else
    std::string getWriteDir() { return m_writeDir.string(); }
    std::string getBinaryName() { return m_binaryPath.filename().string(); }
#endif

    std::string getRealDir(const std::string& path);
    std::string getRealPath(const std::string& path);
    std::string getBaseDir();
    std::string getUserDir();
    std::deque<std::string> getSearchPaths() { return m_searchPaths; }

    std::string guessFilePath(const std::string& filename, const std::string& type);
    bool isFileType(const std::string& filename, const std::string& type);
    ticks_t getFileTime(const std::string& filename);

    std::string encrypt(const std::string& data, const std::string& password);
    std::string decrypt(const std::string& data);
    static uint8_t* decrypt(uint8_t* data, int32_t size);
    void runEncryption(const std::string& password);
    void save_string_into_file(const std::string& contents, const std::string& name);

    bool isLoadedFromArchive() { return m_loadedFromArchive; }
    bool isLoadedFromMemory() { return m_loadedFromMemory; }

    std::string fileChecksum(const std::string& path);

    stdext::map<std::string, std::string> filesChecksums();
    std::string selfChecksum();

    std::string readCrashLog(bool txt);
    void deleteCrashLog();

    void updateFiles(const std::set<std::string>& files);

    void updateExecutable(std::string fileName);

    std::string getBinaryPath() { return m_binaryPath.filename().string(); }

    std::map<std::string, std::string> decompressArchive(std::string dataOrPath);

    bool decryptBuffer(std::string & buffer);

    void setLayout(std::string layout);
    std::string getLayout()
    {
        return m_layout;
    }

private:
    bool mountMemoryData(const std::shared_ptr<std::vector<uint8_t>>& data);
    void unmountMemoryData();

    std::filesystem::path m_binaryPath, m_writeDir;

    std::deque<std::string> m_searchPaths;

    bool m_loadedFromMemory = false;
    bool m_loadedFromArchive = false;
    std::shared_ptr<std::vector<uint8_t>> m_memoryData;
    uint32_t m_customEncryption = 0;
    std::string m_layout;
};

extern ResourceManager g_resources;
