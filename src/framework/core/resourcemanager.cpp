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

#include "resourcemanager.h"
#include "filestream.h"

#include <framework/core/application.h>
#include <framework/luaengine/luainterface.h>
#include <framework/platform/platform.h>
#include <framework/net/protocolhttp.h>
#include <framework/util/crypt.h>

#define PHYSFS_DEPRECATED
#include <physfs.h>

#include <zlib.h>

ResourceManager g_resources;
static const std::string INIT_FILENAME = "init.lua";

void ResourceManager::init(const char *argv0)
{
#if defined(WIN32)
    char fileName[255];
    GetModuleFileNameA(NULL, fileName, sizeof(fileName));
    m_binaryPath = std::filesystem::absolute(fileName);
#elif defined(ANDROID)
    // nothing
#else
    m_binaryPath = std::filesystem::absolute(argv0);
#endif
    PHYSFS_init(argv0);
    PHYSFS_permitSymbolicLinks(1);
}

void ResourceManager::terminate()
{
    PHYSFS_deinit();
}

bool ResourceManager::launchCorrect(std::vector<std::string>& args) { // curently works only on windows
#if (defined(ANDROID) || defined(FREE_VERSION))
    return false;
#else
    auto fileName2 = m_binaryPath.stem().string();
    fileName2 = stdext::split(fileName2, "-")[0];
    stdext::tolower(fileName2);

    std::filesystem::path path(m_binaryPath.parent_path());
    std::error_code ec;
    auto lastWrite = std::filesystem::last_write_time(m_binaryPath, ec);
    std::filesystem::path binary = m_binaryPath;
    for (auto& entry : std::filesystem::directory_iterator(path)) {
        if (std::filesystem::is_directory(entry.path()))
            continue;

        auto fileName1 = entry.path().stem().string();
        fileName1 = stdext::split(fileName1, "-")[0];
        stdext::tolower(fileName1);
        if (fileName1 != fileName2)
            continue;

        if (entry.path().extension() == m_binaryPath.extension()) {
            std::error_code ec;
            auto writeTime = std::filesystem::last_write_time(entry.path(), ec);
            if (!ec && writeTime > lastWrite) {
                lastWrite = writeTime;
                binary = entry.path();
            }
        }
    }

    for (auto& entry : std::filesystem::directory_iterator(path)) { // remove old
        if (std::filesystem::is_directory(entry.path()))
            continue;

        auto fileName1 = entry.path().stem().string();
        fileName1 = stdext::split(fileName1, "-")[0];
        stdext::tolower(fileName1);
        if (fileName1 != fileName2)
            continue;

        if (entry.path().extension() == m_binaryPath.extension()) {
            if (binary == entry.path())
                continue;
            std::error_code ec;
            std::filesystem::remove(entry.path(), ec);
        }
    }

    if (binary == m_binaryPath)
        return false;

    g_platform.spawnProcess(binary.string(), args);
    return true;
#endif
}

bool ResourceManager::setupWriteDir(const std::string& product, const std::string& app) {
#ifdef ANDROID
    const char* localDir = g_androidState->activity->internalDataPath;
#else
    const char* localDir = PHYSFS_getPrefDir(product.c_str(), app.c_str());
#endif

    if (!localDir) {
        g_logger.fatal(stdext::format("Unable to get local dir, error: %s", PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    if (!PHYSFS_mount(localDir, NULL, 0)) {
        g_logger.fatal(stdext::format("Unable to mount local directory '%s': %s", localDir, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    if (!PHYSFS_setWriteDir(localDir)) {
        g_logger.fatal(stdext::format("Unable to set write dir '%s': %s", localDir, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

#ifndef ANDROID
    m_writeDir = std::filesystem::path(std::filesystem::u8path(localDir));
#endif
    return true;
}

bool ResourceManager::setup()
{
    std::shared_ptr<std::vector<uint8_t>> data = nullptr;
#ifdef ANDROID
    PHYSFS_File* file = PHYSFS_openRead("data.zip");
    if (file) {
        auto data = std::make_shared<std::vector<uint8_t>>(PHYSFS_fileLength(file));
        PHYSFS_readBytes(file, data->data(), data->size());
        PHYSFS_close(file);
        if (mountMemoryData(data))
            return true;
    }
#else
    std::string localDir(PHYSFS_getWriteDir());
    std::vector<std::string> possiblePaths = { localDir, g_platform.getCurrentDir() };
    const char* baseDir = PHYSFS_getBaseDir();
    if (baseDir)
        possiblePaths.push_back(baseDir);

    for (const std::string& dir : possiblePaths) {
        if (dir == localDir || !PHYSFS_mount(dir.c_str(), NULL, 0))
            continue;

        if(PHYSFS_exists(INIT_FILENAME.c_str())) {
            g_logger.info(stdext::format("Found work dir at '%s'", dir));
            return true;
        }

        PHYSFS_unmount(dir.c_str());
    }

    for(const std::string& dir : possiblePaths) {
        if (dir != localDir && !PHYSFS_mount(dir.c_str(), NULL, 0)) {
            continue;
        }

        if (!PHYSFS_exists("data.zip")) {
            if(dir != localDir)
                PHYSFS_unmount(dir.c_str());
            continue;
        }

        PHYSFS_File* file = PHYSFS_openRead("data.zip");
        if (!file) {
            if (dir != localDir)
                PHYSFS_unmount(dir.c_str());
            continue;
        }

        auto data = std::make_shared<std::vector<uint8_t>>(PHYSFS_fileLength(file));
        PHYSFS_readBytes(file, data->data(), data->size());
        PHYSFS_close(file);
        if (dir != localDir)
            PHYSFS_unmount(dir.c_str());

        g_logger.info(stdext::format("Found work dir at '%s'", dir));
        if (mountMemoryData(data))
            return true;
    }
#endif
    if (loadDataFromSelf()) {
        g_logger.info(stdext::format("Found work dir inside binary"));
        return true;
    }

    g_logger.fatal("Unable to find working directory (or data.zip)");
    return false;
}

bool ResourceManager::loadDataFromSelf(bool unmountIfMounted) {
    std::shared_ptr<std::vector<uint8_t>> data = nullptr;
#ifdef ANDROID
    AAsset* file = AAssetManager_open(g_androidState->activity->assetManager, "data.zip", AASSET_MODE_BUFFER);
    if (!file)
        g_logger.fatal("Can't open data.zip from assets");
    data = std::make_shared<std::vector<uint8_t>>(AAsset_getLength(file));
    AAsset_read(file, data->data(), data->size());
    AAsset_close(file);
#else
    std::ifstream file(m_binaryPath.string(), std::ios::binary);
    if (!file.is_open())
        return false;
    file.seekg(0, std::ios_base::end);
    std::size_t size = file.tellg();
    file.seekg(0, std::ios_base::beg);
    if (size < 1024 || size > 1024 * 1024 * 128) {
        file.close();
        return false;
    }

    std::vector<uint8_t> v(1 + size);
    file.read((char*)&v[0], size);
    file.close();
    for (size_t i = 0, end = size - 128; i < end; ++i) {
        if (v[i] == 0x50 && v[i + 1] == 0x4b && v[i + 2] == 0x03 && v[i + 3] == 0x04 && v[i + 4] == 0x14) {
            uint32_t compSize = *(uint32_t*)&v[i + 18];
            uint32_t decompSize = *(uint32_t*)&v[i + 22];
            if (compSize < 1024 * 1024 * 512 && decompSize < 1024 * 1024 * 512) {
                data = std::make_shared<std::vector<uint8_t>>(&v[i], &v[v.size() - 1]);
                break;
            }
        }
    }
    v.clear();

#endif

    if (unmountIfMounted)
        unmountMemoryData();

    if (mountMemoryData(data)) {
        m_loadedFromMemory = true;
        return true;
    }

    return false;
}

bool ResourceManager::setWriteDir(const std::string& writeDir, bool)
{
    if (!PHYSFS_setWriteDir(writeDir.c_str())) {
        g_logger.error(stdext::format("Unable to set write directory '%s': %s", writeDir, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
        return false;
    }

    if (!m_writeDir.empty())
        removeSearchPath(m_writeDir.string());

    m_writeDir = writeDir;

    if (!addSearchPath(writeDir))
        g_logger.error(stdext::format("Unable to add write '%s' directory to search path", writeDir));

    return true;
}

bool ResourceManager::addSearchPath(const std::string& path, bool pushFront)
{
    std::string savePath = path;
    if (!PHYSFS_mount(path.c_str(), nullptr, pushFront ? 0 : 1)) {
        bool found = false;
        for (const std::string& searchPath : m_searchPaths) {
            std::string newPath = searchPath + path;
            if (PHYSFS_mount(newPath.c_str(), nullptr, pushFront ? 0 : 1)) {
                savePath = newPath;
                found = true;
                break;
            }
        }

        if (!found) {
            //g_logger.error(stdext::format("Could not add '%s' to directory search path. Reason %s", path, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
            return false;
        }
    }
    if (pushFront)
        m_searchPaths.push_front(savePath);
    else
        m_searchPaths.push_back(savePath);
    return true;
}

bool ResourceManager::removeSearchPath(const std::string& path)
{
    if (!PHYSFS_unmount(path.c_str()))
        return false;
    const auto it = std::find(m_searchPaths.begin(), m_searchPaths.end(), path);
    assert(it != m_searchPaths.end());
    m_searchPaths.erase(it);
    return true;
}

void ResourceManager::searchAndAddPackages(const std::string& packagesDir, const std::string& packageExt)
{
    auto files = listDirectoryFiles(packagesDir);
    for (auto it = files.rbegin(); it != files.rend(); ++it) {
        const auto& file = *it;

        if (!file.ends_with(packageExt))
            continue;
        std::string package = getRealDir(packagesDir) + "/" + file;
        if (!addSearchPath(package, true))
            g_logger.error(stdext::format("Unable to read package '%s': %s", package, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    }
}

bool ResourceManager::fileExists(const std::string& fileName)
{
    if (fileName.find("/downloads") != std::string::npos)
        return g_http.getFile(fileName.substr(10)) != nullptr;
    return (PHYSFS_exists(resolvePath(fileName).c_str()) && !PHYSFS_isDirectory(resolvePath(fileName).c_str()));
}

bool ResourceManager::directoryExists(const std::string& directoryName)
{
    if (directoryName == "/downloads")
        return true;
    return (PHYSFS_isDirectory(resolvePath(directoryName).c_str()));
}

void ResourceManager::readFileStream(const std::string& fileName, std::iostream& out)
{
    std::string buffer(readFileContents(fileName));
    if(buffer.length() == 0) {
        out.clear(std::ios::eofbit);
        return;
    }
    out.clear(std::ios::goodbit);
    out.write(&buffer[0], buffer.length());
    out.seekg(0, std::ios::beg);
}

std::string ResourceManager::readFileContents(const std::string& fileName, bool safe)
{
    std::string fullPath = resolvePath(fileName);

    if (fullPath.find("/downloads") != std::string::npos) {
        auto dfile = g_http.getFile(fullPath.substr(10));
        if (dfile)
            return std::string(dfile->response.begin(), dfile->response.end());
    }

    PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
    if(!file)
        throw Exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

    int fileSize = PHYSFS_fileLength(file);
    std::string buffer(fileSize, 0);
    PHYSFS_readBytes(file, (void*)&buffer[0], fileSize);
    PHYSFS_close(file);

#if ENABLE_ENCRYPTION == 1
    buffer = decrypt(buffer);
#endif

    if (safe) {
        return buffer;
    }

    // skip decryption for bot configs
    if (fullPath.find("/bot/") != std::string::npos) {
        return buffer;
    }

    static std::string unencryptedExtensions[] = { ".otml", ".otmm", ".dmp", ".log", ".txt", ".dll", ".exe", ".zip" };

    if (!decryptBuffer(buffer)) {
        bool ignore = (m_customEncryption == 0);
        for (auto& it : unencryptedExtensions) {
            if (fileName.find(it) == fileName.size() - it.size()) {
                ignore = true;
            }
        }
        if(!ignore)
            g_logger.fatal(stdext::format("unable to decrypt file: %s", fullPath));
    }

    return buffer;
}

bool ResourceManager::isFileEncryptedOrCompressed(const std::string& fileName)
{
    std::string fullPath = resolvePath(fileName);
    std::string fileContent;

    if (fullPath.find("/downloads") != std::string::npos) {
        auto dfile = g_http.getFile(fullPath.substr(10));
        if (dfile) {
            if (dfile->response.size() < 10)
                return false;
            fileContent = std::string(dfile->response.begin(), dfile->response.begin() + 10);
        }
    }

    if (!fileContent.empty()) {
        PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
        if (!file)
            throw Exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));

        int fileSize = std::min<int>(10, PHYSFS_fileLength(file));
        fileContent.resize(fileSize);
        PHYSFS_readBytes(file, (void*)&fileContent[0], fileSize);
        PHYSFS_close(file);
    }

    if (fileContent.size() < 10)
        return false;

    if (fileContent.substr(0, 4).compare("ENC3") == 0)
        return true;

    if ((uint8_t)fileContent[0] != 0x1f || (uint8_t)fileContent[1] != 0x8b || (uint8_t)fileContent[2] != 0x08) {
        return false;
    }

    return true;
}

bool ResourceManager::writeFileBuffer(const std::string& fileName, const uint8_t* data, uint32_t size, bool createDirectory)
{
    if (createDirectory) {
        const auto& path = std::filesystem::path(fileName);
        const auto& dirPath = path.parent_path().string();

        if (!PHYSFS_isDirectory(dirPath.c_str())) {
            if (!PHYSFS_mkdir(dirPath.c_str())) {
                g_logger.error(stdext::format("Unable to create write directory '%s': %s", dirPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
                return false;
            }
        }
    }

    PHYSFS_file* file = PHYSFS_openWrite(fileName.c_str());
    if (!file) {
        g_logger.error(PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
        return false;
    }

    PHYSFS_writeBytes(file, data, size);
    PHYSFS_close(file);
    return true;
}

bool ResourceManager::writeFileStream(const std::string& fileName, std::iostream& in)
{
    std::streampos oldPos = in.tellg();
    in.seekg(0, std::ios::end);
    std::streampos size = in.tellg();
    in.seekg(0, std::ios::beg);
    std::vector<char> buffer(size);
    in.read(&buffer[0], size);
    bool ret = writeFileBuffer(fileName, (const uchar*)&buffer[0], size);
    in.seekg(oldPos, std::ios::beg);
    return ret;
}

bool ResourceManager::writeFileContents(const std::string& fileName, const std::string& data)
{
#if ENABLE_ENCRYPTION == 1
    return writeFileBuffer(fileName, (const uint8_t*)encrypt(data, std::string(ENCRYPTION_PASSWORD)).c_str(), data.size());
#else
    return writeFileBuffer(fileName, (const uint8_t*)data.c_str(), data.size());
#endif
}

FileStreamPtr ResourceManager::openFile(const std::string& fileName, bool dontCache)
{
    std::string fullPath = resolvePath(fileName);
    if (isFileEncryptedOrCompressed(fullPath) || !dontCache) {
        return FileStreamPtr(new FileStream(fullPath, readFileContents(fullPath)));
    }
    PHYSFS_File* file = PHYSFS_openRead(fullPath.c_str());
    if (!file)
        throw Exception(stdext::format("unable to open file '%s': %s", fullPath, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fullPath, file, false));
}

FileStreamPtr ResourceManager::appendFile(const std::string& fileName)
{
    PHYSFS_File* file = PHYSFS_openAppend(fileName.c_str());
    if(!file)
        throw Exception(stdext::format("failed to append file '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fileName, file, true));
}

FileStreamPtr ResourceManager::createFile(const std::string& fileName)
{
    PHYSFS_File* file = PHYSFS_openWrite(fileName.c_str());
    if(!file)
        throw Exception(stdext::format("failed to create file '%s': %s", fileName, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    return FileStreamPtr(new FileStream(fileName, file, true));
}

bool ResourceManager::deleteFile(const std::string& fileName)
{
    return PHYSFS_delete(resolvePath(fileName).c_str()) != 0;
}

bool ResourceManager::makeDir(const std::string directory)
{
    return PHYSFS_mkdir(directory.c_str());
}

std::list<std::string> ResourceManager::listDirectoryFiles(const std::string& directoryPath, bool fullPath /* = false */, bool raw /*= false*/, bool recursive /*= false*/)
{
    std::list<std::string> files;
    auto path = raw ? directoryPath : resolvePath(directoryPath);
    auto rc = PHYSFS_enumerateFiles(path.c_str());

    if (!rc)
        return files;

    for (int i = 0; rc[i] != nullptr; i++) {
        std::string fileOrDir = rc[i];
        if (fullPath) {
            if (path != "/")
                fileOrDir = path + "/" + fileOrDir;
            else
                fileOrDir = path + fileOrDir;
        }

        if (recursive && directoryExists("/" + fileOrDir)) {
            const auto& moreFiles = listDirectoryFiles(fileOrDir, fullPath, raw, recursive);
            files.insert(files.end(), moreFiles.begin(), moreFiles.end());
        } else {
            files.push_back(fileOrDir);
        }

    }

    PHYSFS_freeList(rc);
    files.sort();
    return files;
}

std::string ResourceManager::resolvePath(const std::string& path)
{
    std::string fullPath;
    if (path.starts_with("/"))
        fullPath = path;
    else {
        if (const std::string scriptPath = "/" + g_lua.getCurrentSourcePath(); !scriptPath.empty())
            fullPath += scriptPath + "/";
        fullPath += path;
    }
    if (!(fullPath.starts_with("/")))
        g_logger.traceWarning(stdext::format("the following file path is not fully resolved: %s", path));

    stdext::replace_all(fullPath, "//", "/");
    return fullPath;
}

std::string ResourceManager::getRealDir(const std::string& path)
{
    std::string dir;
    if (const char* cdir = PHYSFS_getRealDir(resolvePath(path).c_str()))
        dir = cdir;
    return dir;
}

std::string ResourceManager::getRealPath(const std::string& path)
{
    return getRealDir(path) + "/" + path;
}

std::string ResourceManager::getBaseDir()
{
#ifdef ANDROID
    return g_androidState->activity->internalDataPath;
#else
    return PHYSFS_getBaseDir();
#endif
}

std::string ResourceManager::getUserDir()
{
#ifdef ANDROID
    return getBaseDir() + "/";
#else
    static const char* orgName = g_app.getOrganizationName().data();
    static const char* appName = g_app.getCompactName().data();

    return PHYSFS_getPrefDir(orgName, appName);
#endif
}

std::string ResourceManager::guessFilePath(const std::string& filename, const std::string& type)
{
    if(isFileType(filename, type))
        return filename;
    return filename + "." + type;
}

bool ResourceManager::isFileType(const std::string& filename, const std::string& type)
{
    if (filename.ends_with(std::string(".") + type))
        return true;
    return false;
}

ticks_t ResourceManager::getFileTime(const std::string& filename)
{
    return g_platform.getFileModificationTime(getRealPath(filename));
}

std::string ResourceManager::encrypt(const std::string& data, const std::string& password)
{
    const int len = data.length(),
        plen = password.length();

    std::ostringstream ss;
    int j = 0;
    for (int i = -1; ++i < len;) {
        int ct = data[i];
        if (i % 2) {
            ct = ct - password[j] + i;
        } else {
            ct = ct + password[j] - i;
        }
        ss << static_cast<char>(ct);
        ++j;

        if (j >= plen)
            j = 0;
    }

    return ss.str();
}
std::string ResourceManager::decrypt(const std::string& data)
{
    const auto& password = std::string(ENCRYPTION_PASSWORD);

    const int len = data.length(),
        plen = password.length();

    std::ostringstream ss;
    int j = 0;
    for (int i = -1; ++i < len;) {
        int ct = data[i];
        if (i % 2) {
            ct = ct + password[j] - i;
        } else {
            ct = ct - password[j] + i;
        }
        ss << static_cast<char>(ct);
        ++j;

        if (j >= plen)
            j = 0;
    }

    return ss.str();
}

uint8_t* ResourceManager::decrypt(uint8_t* data, int32_t size)
{
    const auto& password = std::string(ENCRYPTION_PASSWORD);
    const int plen = password.length();

    auto* const new_Data = new uint8_t[size];

    int j = 0;
    for (int i = -1; ++i < size;) {
        const int ct = data[i];
        if (i % 2) {
            new_Data[i] = ct + password[j] - i;
        } else {
            new_Data[i] = ct - password[j] + i;
        }
        data[i] = new_Data[i];
        ++j;

        if (j >= plen)
            j = 0;
    }

    return nullptr;
}

void ResourceManager::runEncryption(const std::string& password)
{
    std::vector<std::string> excludedExtensions = { ".rar",".ogg",".xml",".dll",".exe", ".log",".otb" };
    for (const auto& entry : std::filesystem::recursive_directory_iterator("./")) {
        if (std::string ext = entry.path().extension().string();
            std::find(excludedExtensions.begin(), excludedExtensions.end(), ext) != excludedExtensions.end())
            continue;

        std::ifstream ifs(entry.path().string(), std::ios_base::binary);
        std::string data((std::istreambuf_iterator(ifs)), std::istreambuf_iterator<char>());
        ifs.close();
        data = encrypt(data, password);
        save_string_into_file(data, entry.path().string());
    }
}

void ResourceManager::save_string_into_file(const std::string& contents, const std::string& name)
{
    std::ofstream datFile;
    datFile.open(name, std::ofstream::binary | std::ofstream::trunc | std::ofstream::out);
    datFile.write(contents.c_str(), contents.size());
    datFile.close();
}

std::string ResourceManager::fileChecksum(const std::string& path) {
    static std::map<std::string, std::string> cache;

    auto it = cache.find(path);
    if (it != cache.end())
        return it->second;

    PHYSFS_File* file = PHYSFS_openRead(path.c_str());
    if(!file)
        return "";

    int fileSize = PHYSFS_fileLength(file);
    std::string buffer(fileSize, 0);
    PHYSFS_readBytes(file, (void*)&buffer[0], fileSize);
    PHYSFS_close(file);

    auto checksum = g_crypt.crc32(buffer, false);
    cache[path] = checksum;

    return checksum;
}

stdext::map<std::string, std::string> ResourceManager::filesChecksums()
{
    stdext::map<std::string, std::string> ret;
    auto files = listDirectoryFiles("/", true, false, true);
    for (auto it = files.rbegin(); it != files.rend(); ++it) {
        const auto& filePath = *it;
        PHYSFS_File* file = PHYSFS_openRead(filePath.c_str());
        if (!file)
            continue;

        int fileSize = PHYSFS_fileLength(file);
        std::string buffer(fileSize, 0);
        PHYSFS_readBytes(file, (void*)&buffer[0], fileSize);
        PHYSFS_close(file);

        auto checksum = g_crypt.crc32(buffer, false);
        ret[filePath] = checksum;
    }

    return ret;
}

std::string ResourceManager::selfChecksum() {
#ifdef ANDROID
    return "";
#else
    static std::string checksum;
    if (!checksum.empty())
        return checksum;

    std::ifstream file(m_binaryPath.string(), std::ios::binary);
    if (!file.is_open())
        return "";

    std::string buffer(std::istreambuf_iterator<char>(file), {});
    file.close();

    checksum = g_crypt.crc32(buffer, false);
    return checksum;
#endif
}

void ResourceManager::updateFiles(const std::set<std::string>& files) {
    g_logger.info(stdext::format("Updating client, %i files", files.size()));

    const auto& oldWriteDir = getWriteDir();
    setWriteDir(getWorkDir());
    for (auto fileName : files) {
        if (fileName.empty())
            continue;

        if (fileName.size() > 1 && fileName[0] == '/')
            fileName = fileName.substr(1);

        auto dFile = g_http.getFile(fileName);

        if (dFile) {
            if (!writeFileBuffer(fileName, (const uint8_t*)dFile->response.data(), dFile->response.size(), true)) {
                g_logger.error(stdext::format("Cannot write file: %s", fileName));
            } else {
                //g_logger.info(stdext::format("Updated file: %s", fileName));
            }
        } else {
            g_logger.error(stdext::format("Cannot find file: %s in downloads", fileName));
        }
    }
    setWriteDir(oldWriteDir);
}

void ResourceManager::updateExecutable(std::string fileName)
{
#if defined(ANDROID) || defined(FREE_VERSION)
    g_logger.fatal("Executable cannot be updated on android or in free version");
#else
    if (fileName.size() <= 2) {
        g_logger.fatal("Invalid executable name");
    }

    if (fileName[0] == '/')
        fileName = fileName.substr(1);

    auto dFile = g_http.getFile(fileName);
    if (!dFile)
        g_logger.fatal(stdext::format("Cannot find executable: %s in downloads", fileName));

    const auto& oldWriteDir = getWriteDir();
    setWriteDir(getWorkDir());
    std::filesystem::path path(m_binaryPath);
    auto newBinary = path.stem().string() + "-" + std::to_string(time(nullptr)) + path.extension().string();
    g_logger.info(stdext::format("Updating binary file: %s", newBinary));
    PHYSFS_file* file = PHYSFS_openWrite(newBinary.c_str());
    if (!file)
        return g_logger.fatal(stdext::format("can't open %s for writing: %s", newBinary, PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    PHYSFS_writeBytes(file, dFile->response.data(), dFile->response.size());
    PHYSFS_close(file);
    setWriteDir(oldWriteDir);

    std::filesystem::path newBinaryPath(std::filesystem::u8path(PHYSFS_getWriteDir()));
#endif
}

#if defined(WITH_ENCRYPTION) && !defined(ANDROID)
void ResourceManager::encrypt(const std::string& seed) {
    const std::string dirsToCheck[] = { "data", "modules", "mods", "layouts" };
    const std::string luaExtension = ".lua";

    g_logger.setLogFile("encryption.log");
    g_logger.info("----------------------");

    std::queue<std::filesystem::path> toEncrypt;
    // you can add custom files here
    toEncrypt.push(std::filesystem::path(INIT_FILENAME));

    for (auto& dir : dirsToCheck) {
        if (!std::filesystem::exists(dir))
            continue;
        for(auto&& entry : std::filesystem::recursive_directory_iterator(std::filesystem::path(dir))) {
            if (!std::filesystem::is_regular_file(entry.path()))
                continue;
            std::string str(entry.path().string());
            // skip encryption for bot configs
            if (str.find("game_bot") != std::string::npos && str.find("default_config") != std::string::npos) {
                continue;
            }
            toEncrypt.push(entry.path());
        }
    }

    bool encryptForAndroid = seed.find("android") != std::string::npos;
    uint32_t uintseed = seed.empty() ? 0 : stdext::adler32((const uint8_t*)seed.c_str(), seed.size());

    while (!toEncrypt.empty()) {
        auto it = toEncrypt.front();
        toEncrypt.pop();
        std::ifstream in_file(it, std::ios::binary);
        if (!in_file.is_open())
            continue;
        std::string buffer(std::istreambuf_iterator<char>(in_file), {});
        in_file.close();
        if (buffer.size() >= 4 && buffer.substr(0, 4).compare("ENC3") == 0)
            continue; // already encrypted

        if (!encryptForAndroid && it.extension().string() == luaExtension && it.filename().string() != INIT_FILENAME) {
            std::string bytecode = g_lua.generateByteCode(buffer, it.string());
            if (bytecode.length() > 10) {
                buffer = bytecode;
                g_logger.info(stdext::format("%s - lua bytecode encrypted", it.string()));
            } else {
                g_logger.info(stdext::format("%s - lua but not bytecode encrypted", it.string()));
            }
        }

        if (!encryptBuffer(buffer, uintseed)) { // already encrypted
            g_logger.info(stdext::format("%s - already encrypted", it.string()));
            continue;
        }

        std::ofstream out_file(it, std::ios::binary);
        if (!out_file.is_open())
            continue;
        out_file.write(buffer.data(), buffer.size());
        out_file.close();
        g_logger.info(stdext::format("%s - encrypted", it.string()));
    }
}
#endif

bool ResourceManager::decryptBuffer(std::string& buffer) {
#ifdef FREE_VERSION
    return false;
#else
    if (buffer.size() < 5)
        return true;

    if (buffer.substr(0, 4).compare("ENC3") != 0) {
        return false;
    }

    uint64_t key = *(uint64_t*)&buffer[4];
    uint32_t compressed_size = *(uint32_t*)&buffer[12];
    uint32_t size = *(uint32_t*)&buffer[16];
    uint32_t adler = *(uint32_t*)&buffer[20];

    if (compressed_size < buffer.size() - 24)
        return false;

    g_crypt.bdecrypt((uint8_t*)&buffer[24], compressed_size, key);
    std::string new_buffer;
    new_buffer.resize(size);
    unsigned long new_buffer_size = new_buffer.size();
    if (uncompress((uint8_t*)new_buffer.data(), &new_buffer_size, (uint8_t*)&buffer[24], compressed_size) != Z_OK)
        return false;

    uint32_t addlerCheck = stdext::adler32((const uint8_t*)&new_buffer[0], size);
    if (adler != addlerCheck) {
        uint32_t cseed = adler ^ addlerCheck;
        if (m_customEncryption == 0) {
            m_customEncryption = cseed;
        }
        if ((addlerCheck ^ m_customEncryption) != adler) {
            return false;
        }
    }

    buffer = new_buffer;
    return true;
#endif
}

#ifdef WITH_ENCRYPTION
bool ResourceManager::encryptBuffer(std::string& buffer, uint32_t seed) {
    if (buffer.size() >= 4 && buffer.substr(0, 4).compare("ENC3") == 0)
        return false; // already encrypted

    // not random beacause it would require to update to new files each time
    int64_t key = stdext::adler32((const uint8_t*)&buffer[0], buffer.size());
    key <<= 32;
    key += stdext::adler32((const uint8_t*)&buffer[0], buffer.size() / 2);

    std::string new_buffer(24 + buffer.size() * 2, '0');
    new_buffer[0] = 'E';
    new_buffer[1] = 'N';
    new_buffer[2] = 'C';
    new_buffer[3] = '3';

    unsigned long dstLen = new_buffer.size() - 24;
    if (compress((uint8_t*)&new_buffer[24], &dstLen, (const uint8_t*)buffer.data(), buffer.size()) != Z_OK) {
        g_logger.error("Error while compressing");
        return false;
    }
    new_buffer.resize(24 + dstLen);

    *(int64_t*)&new_buffer[4] = key;
    *(uint32_t*)&new_buffer[12] = (uint32_t)dstLen;
    *(uint32_t*)&new_buffer[16] = (uint32_t)buffer.size();
    *(uint32_t*)&new_buffer[20] = ((uint32_t)stdext::adler32((const uint8_t*)&buffer[0], buffer.size())) ^ seed;

    g_crypt.bencrypt((uint8_t*)&new_buffer[0] + 24, new_buffer.size() - 24, key);
    buffer = new_buffer;
    return true;
}
#endif

void ResourceManager::setLayout(std::string layout)
{
    stdext::tolower(layout);
    stdext::replace_all(layout, "/", "");
    if (layout == "default") {
        layout = "";
    }
    if (!layout.empty() && !PHYSFS_exists((std::string("/layouts/") + layout).c_str())) {
        g_logger.error(stdext::format("Layour %s doesn't exist, using default", layout));
        return;
    }
    m_layout = layout;
}

bool ResourceManager::mountMemoryData(const std::shared_ptr<std::vector<uint8_t>>& data)
{
    if (!data || data->size() < 1024)
        return false;

    if (PHYSFS_mountMemory(data->data(), data->size(), nullptr,
                           "memory_data.zip", "/", 0)) {
        if (PHYSFS_exists(INIT_FILENAME.c_str())) {
            m_loadedFromArchive = true;
            m_memoryData = data;
            return true;
        }
        PHYSFS_unmount("memory_data.zip");
    }
    return false;
}

void ResourceManager::unmountMemoryData()
{
    if (!m_memoryData)
        return;

    if (!PHYSFS_unmount("memory_data.zip")) {
        g_logger.fatal(stdext::format("Unable to unmount memory data", PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode())));
    }
    m_memoryData = nullptr;
    m_loadedFromMemory = false;
    m_loadedFromArchive = false;
}
