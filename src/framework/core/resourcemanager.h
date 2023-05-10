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
    void init(const char* argv0);
    // @dontbind
    void terminate();

    bool discoverWorkDir(const std::string& existentFile);
    bool setupUserWriteDir(const std::string& appWriteDirName);
    bool setWriteDir(const std::string& writeDir, bool create = false);

    bool addSearchPath(const std::string& path, bool pushFront = false);
    bool removeSearchPath(const std::string& path);
    void searchAndAddPackages(const std::string& packagesDir, const std::string& packageExt);

    bool fileExists(const std::string& fileName);
    bool directoryExists(const std::string& directoryName);

    // @dontbind
    void readFileStream(const std::string& fileName, std::iostream& out);
    std::string readFileContents(const std::string& fileName);
    // @dontbind
    bool writeFileBuffer(const std::string& fileName, const uint8_t* data, uint32_t size, bool createDirectory = false);
    bool writeFileContents(const std::string& fileName, const std::string& data);
    // @dontbind
    bool writeFileStream(const std::string& fileName, std::iostream& in);

    // String_view Support
    FileStreamPtr openFile(const std::string& fileName);
    FileStreamPtr appendFile(const std::string& fileName) const;
    FileStreamPtr createFile(const std::string& fileName) const;
    bool deleteFile(const std::string& fileName);

    bool makeDir(const std::string& directory);
    std::list<std::string> listDirectoryFiles(const std::string& directoryPath = "", bool fullPath = false, bool raw = false, bool recursive = false);
    std::vector<std::string> getDirectoryFiles(const std::string& path, bool filenameOnly, bool recursive);

    std::string resolvePath(const std::string& path);
    std::string getRealDir(const std::string& path);
    std::string getRealPath(const std::string& path);
    std::string getBaseDir();
    std::string getUserDir();
    std::string getWriteDir() { return m_writeDir; }
    std::string getWorkDir() { return m_workDir; }
    std::deque<std::string> getSearchPaths() { return m_searchPaths; }

    std::string guessFilePath(const std::string& filename, const std::string& type);
    bool isFileType(const std::string& filename, const std::string& type);
    ticks_t getFileTime(const std::string& filename);

    std::string encrypt(const std::string& data, const std::string& password);
    std::string decrypt(const std::string& data);
    static uint8_t* decrypt(uint8_t* data, int32_t size);
    void runEncryption(const std::string& password);
    void save_string_into_file(const std::string& contents, const std::string& name);

    std::string fileChecksum(const std::string& path);
    stdext::map<std::string, std::string> filesChecksums();
    std::string selfChecksum();
    void updateFiles(const std::set<std::string>& files);
    void updateExecutable(std::string fileName);
    bool launchCorrect(std::vector<std::string>& args);

    std::string getBinaryPath() { return m_binaryPath.string(); }

protected:
    std::vector<std::string> discoverPath(const std::filesystem::path& path, bool filenameOnly, bool recursive);

private:
    std::string m_workDir;
    std::string m_writeDir;
    std::filesystem::path m_binaryPath;
    std::deque<std::string> m_searchPaths;
};

extern ResourceManager g_resources;
