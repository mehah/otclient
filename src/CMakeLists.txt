project(otclient)

# *****************************************************************************
# Options
# *****************************************************************************

option(TOGGLE_FRAMEWORK_GRAPHICS "Use Graphics " ON)
option(TOGGLE_FRAMEWORK_SOUND "Use SOUND " ON)
option(TOGGLE_FRAMEWORK_XML "Use XML " ON)
option(TOGGLE_FRAMEWORK_NET "Use NET " ON)
option(TOGGLE_FRAMEWORK_EDITOR "Use Editor " OFF)
option(TOGGLE_DIRECTX "Use DX9 support" OFF)
option(ENABLE_DISCORD_RPC "Use Discord Rich Presence" OFF)
option(TOGGLE_BIN_FOLDER "Use build/bin folder for generate compilation files" OFF)
option(DEBUG_LOG "Enable Debug Log" OFF)
option(ASAN_ENABLED "Build this target with AddressSanitizer" OFF)
option(BUILD_STATIC_LIBRARY "Build using static libraries" OFF)
option(TOGGLE_PRE_COMPILED_HEADER "Use precompiled header (speed up compile)" ON)
option(SPEED_UP_BUILD_UNITY "Compile using build unity for speed up build" ON)

# *****************************************************************************
# Cmake Features
# *****************************************************************************
set(GNUCXX_MINIMUM_VERSION 9)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)


# Make will print more details
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# *****************************************************************************
# Client
# *****************************************************************************
if (MSVC)
  add_executable(${PROJECT_NAME} "" ../cmake/icon/otcicon.rc)
else()
  add_executable(${PROJECT_NAME} "")
endif()

# *****************************************************************************
# Options Code
# *****************************************************************************

# Define Framework options for use in compilation
set(FRAMEWORK_DEFINITIONS "")
if (TOGGLE_FRAMEWORK_GRAPHICS)
  set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_GRAPHICS)
endif()
if (TOGGLE_FRAMEWORK_SOUND)
  set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_SOUND)
endif()
if (TOGGLE_FRAMEWORK_XML)
  set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_XML)
endif()
if (TOGGLE_FRAMEWORK_NET)
  set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_NET)
endif()

if (TOGGLE_FRAMEWORK_EDITOR)
  set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_EDITOR)
endif()

set(VERSION "1.0.0")

# *****************************************************************************
# Definitions code
# *****************************************************************************

# *****************************************************************************
# Sanity Check
# *****************************************************************************

# === GCC Minimum Version ===
if (CMAKE_COMPILER_IS_GNUCXX)
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS GNUCXX_MINIMUM_VERSION)
    message(FATAL_ERROR "GCC version must be at least ${GNUCXX_MINIMUM_VERSION}!")
  endif()
endif()


# Multiprocessor compiller
if(CMake_MSVC_PARALLEL)
  if(CMake_MSVC_PARALLEL GREATER 0)
    add_definitions(/MP${CMake_MSVC_PARALLEL})
  else()
    add_definitions(/MP)
  endif()
endif()


# Client options
add_definitions(-DCLIENT)
add_definitions(-DNOMINMAX)
add_definitions(${FRAMEWORK_DEFINITIONS})
add_definitions(-D"VERSION=${VERSION}")
# === Build options ===
message(STATUS "Build type: " ${CMAKE_BUILD_TYPE})
add_definitions(-D"BUILD_TYPE=\\\"${CMAKE_BUILD_TYPE}\\\"")
message(STATUS "Build commit: ${BUILD_COMMIT}")
add_definitions(-D"BUILD_COMMIT=\\\"${BUILD_COMMIT}\\\"")
message(STATUS "Build revision: ${BUILD_REVISION}")
add_definitions(-D"BUILD_REVISION=\\\"${BUILD_REVISION}\\\"")


# *****************************************************************************
# Packages / Libs
# *****************************************************************************
find_package(OpenSSL QUIET)
find_package(PhysFS REQUIRED)
find_package(ZLIB REQUIRED)
find_package(phmap REQUIRED)
find_package(absl CONFIG REQUIRED)
find_package(Protobuf REQUIRED)
find_package(LibLZMA REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(asio REQUIRED)
find_package(Threads REQUIRED)
find_package(STDUUID CONFIG REQUIRED)
find_package(pugixml CONFIG REQUIRED)
find_package(ZLIB REQUIRED)
find_package(httplib CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(utf8cpp REQUIRED)
find_package(unofficial-inih CONFIG REQUIRED)

find_path(CPPCODEC_INCLUDE_DIRS "cppcodec/base32_crockford.hpp")

if(APPLE)
  # Required for Physfs
  find_library(FOUNDATION Foundation REQUIRED)
  find_library(IOKIT IOKit REQUIRED)
endif()
if(UNIX AND NOT APPLE)
  find_package(X11 REQUIRED)
endif()
if(APPLE)
  find_library(COCOA_LIBRARY Cocoa REQUIRED)
  find_library(COREVIDEO_LIBRARY CoreVideo REQUIRED)
  find_library(QUARTZCORE_LIBRARY QuartzCore REQUIRED)
  find_library(OPENGL_FRAMEWORK OpenGL REQUIRED)
endif()
if(WIN32)
  find_package(DbgHelp REQUIRED)
endif(WIN32)
if(NOT OPENSSL_FOUND)
  find_package(GMP REQUIRED)
endif()
if(ENABLE_DISCORD_RPC)
        find_package(DiscordRPC REQUIRED)
        set(OTCLIENT_ENABLE_DISCORD_RPC 1)
        log_option_enabled("Discord Rich Presence")
else()
        set(OTCLIENT_ENABLE_DISCORD_RPC 0)
        log_option_disabled("Discord Rich Presence")
endif()
if(TOGGLE_DIRECTX)
  find_package(DirectX REQUIRED)
endif()
if(TOGGLE_FRAMEWORK_SOUND)
  find_package(OpenAL CONFIG REQUIRED)
  find_package(VorbisFile REQUIRED)
  find_package(Vorbis CONFIG REQUIRED)
  find_package(Ogg CONFIG REQUIRED)
endif()
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
find_package(LuaJIT REQUIRED)

# *****************************************************************************
# OTClient source files configuration
# *****************************************************************************
set(SOURCE_FILES
        framework/core/application.cpp
        framework/core/asyncdispatcher.cpp
        framework/core/binarytree.cpp
        framework/core/clock.cpp
        framework/core/config.cpp
        framework/core/configmanager.cpp
        framework/core/event.cpp
        framework/core/eventdispatcher.cpp
        framework/core/filestream.cpp
        framework/core/logger.cpp
        framework/core/module.cpp
        framework/core/modulemanager.cpp
        framework/core/resourcemanager.cpp
        framework/core/scheduledevent.cpp
        framework/core/unzipper.cpp
        framework/core/unzipper.h
        framework/core/timer.cpp
        framework/discord/discord.cpp
        framework/luaengine/luaexception.cpp
        framework/luaengine/luainterface.cpp
        framework/luaengine/luaobject.cpp
        framework/luaengine/luavaluecasts.cpp
        framework/luafunctions.cpp
        framework/net/connection.cpp
        framework/net/inputmessage.cpp
        framework/net/outputmessage.cpp
        framework/net/protocol.cpp
        framework/net/protocolhttp.cpp
        framework/net/httplogin.cpp
        framework/net/server.cpp
        framework/html/queryselector.cpp
        framework/html/htmlnode.cpp
        framework/html/htmlparser.cpp
        framework/html/htmlmanager.cpp
        framework/html/cssparser.cpp
        framework/otml/otmldocument.cpp
        framework/otml/otmlemitter.cpp
        framework/otml/otmlexception.cpp
        framework/otml/otmlnode.cpp
        framework/otml/otmlparser.cpp
        framework/platform/platform.cpp
        framework/platform/platformwindow.cpp
        framework/platform/unixcrashhandler.cpp
        framework/platform/unixplatform.cpp
        framework/platform/win32crashhandler.cpp
        framework/platform/win32platform.cpp
        framework/stdext/demangle.cpp
        framework/stdext/math.cpp
        framework/stdext/net.cpp
        framework/stdext/string.cpp
        framework/stdext/time.cpp
        framework/stdext/uri.cpp
        framework/stdext/qrcodegen.cpp
        framework/util/color.cpp
        framework/util/crypt.cpp
        framework/util/stats.cpp
        framework/proxy/proxy.cpp
        framework/proxy/proxy_client.cpp
        framework/net/packet_player.cpp
        framework/net/packet_recorder.cpp

        client/animatedtext.cpp
        client/animator.cpp
        client/attachableobject.cpp
        client/attachedeffect.cpp
        client/attachedeffectmanager.cpp
        client/client.cpp
        client/container.cpp
        client/creature.cpp
        client/creatures.cpp
        client/effect.cpp
        client/game.cpp
        client/gameconfig.cpp
        client/houses.cpp
        client/item.cpp
        client/itemtype.cpp
        client/lightview.cpp
        client/localplayer.cpp
        client/luafunctions.cpp
        client/luavaluecasts_client.cpp
        client/map.cpp
        client/mapio.cpp
        client/mapview.cpp
        client/minimap.cpp
        client/missile.cpp
        client/outfit.cpp
        client/player.cpp
        client/position.cpp
        client/protocolcodes.cpp
        client/protocolgame.cpp
        client/protocolgameparse.cpp
        client/protocolgamesend.cpp
        client/paperdoll.cpp
        client/paperdollmanager.cpp
        client/spriteappearances.cpp
        client/spritemanager.cpp
        client/statictext.cpp
        client/thing.cpp
        client/thingtype.cpp
        client/thingtypemanager.cpp
        client/tile.cpp
        client/towns.cpp
        client/uicreature.cpp
        client/uigraph.cpp
        client/uiitem.cpp
        client/uieffect.cpp
        client/uimissile.cpp
        client/uimap.cpp
        client/uimapanchorlayout.cpp
        client/uiminimap.cpp
        client/uiprogressrect.cpp
        client/uisprite.cpp
        tools/datdump.cpp
)

if (TOGGLE_FRAMEWORK_GRAPHICS)
  set(SOURCE_FILES ${SOURCE_FILES}
          framework/core/adaptativeframecounter.cpp
          framework/core/graphicalapplication.cpp
          framework/core/garbagecollection.cpp
          framework/input/mouse.cpp
          framework/graphics/animatedtexture.cpp
          framework/graphics/apngloader.cpp
          framework/graphics/bitmapfont.cpp
          framework/graphics/cachedtext.cpp
          framework/graphics/coordsbuffer.cpp
          framework/graphics/textureatlas.cpp
          framework/graphics/drawpool.cpp
          framework/graphics/drawpoolmanager.cpp
          framework/graphics/fontmanager.cpp
          framework/graphics/framebuffer.cpp
          framework/graphics/graphics.cpp
          framework/graphics/image.cpp
          framework/graphics/painter.cpp
          framework/graphics/paintershaderprogram.cpp
          framework/graphics/particle.cpp
          framework/graphics/particleaffector.cpp
          framework/graphics/particleeffect.cpp
          framework/graphics/particleemitter.cpp
          framework/graphics/particlemanager.cpp
          framework/graphics/particlesystem.cpp
          framework/graphics/particletype.cpp
          framework/graphics/shader.cpp
          framework/graphics/shaderprogram.cpp
          framework/graphics/texture.cpp
          framework/graphics/texturemanager.cpp
          framework/graphics/shadermanager.cpp
          framework/ui/uianchorlayout.cpp
          framework/ui/uiboxlayout.cpp
          framework/ui/uigridlayout.cpp
          framework/ui/uihorizontallayout.cpp
          framework/ui/uilayoutflexbox.cpp
          framework/ui/uilayout.cpp
          framework/ui/uimanager.cpp
          framework/ui/uiparticles.cpp
          framework/ui/uitextedit.cpp
          framework/ui/uitranslator.cpp
          framework/ui/uiverticallayout.cpp
          framework/ui/uiwidget.cpp
          framework/ui/uiwidgetbasestyle.cpp
          framework/ui/uiwidgetimage.cpp
          framework/ui/uiwidgettext.cpp
          framework/ui/uiwidgethtml.cpp
          framework/ui/uiqrcode.cpp
  )
endif()

if (TOGGLE_FRAMEWORK_SOUND)
  set(SOURCE_FILES ${SOURCE_FILES}
          framework/sound/combinedsoundsource.cpp
          framework/sound/oggsoundfile.cpp
          framework/sound/soundbuffer.cpp
          framework/sound/soundchannel.cpp
          framework/sound/soundfile.cpp
          framework/sound/soundmanager.cpp
          framework/sound/soundsource.cpp
          framework/sound/streamsoundsource.cpp
          framework/sound/soundeffect.cpp
  )
endif()

if(WIN32)
  set(SOURCE_FILES ${SOURCE_FILES} framework/platform/win32window.cpp)
elseif(APPLE)
  set(SOURCE_FILES ${SOURCE_FILES}
          framework/platform/cocoawindow.mm
          framework/platform/cocoaview.mm
  )
  set_source_files_properties(
    framework/platform/cocoawindow.mm
    framework/platform/cocoaview.mm
    PROPERTIES
    SKIP_UNITY_BUILD_INCLUSION ON
    SKIP_PRECOMPILE_HEADERS ON
  )
elseif(UNIX)
  set(SOURCE_FILES ${SOURCE_FILES} framework/platform/x11window.cpp)
endif()

add_library(otclient_core STATIC ${SOURCE_FILES})

target_link_libraries(otclient_core PRIVATE unofficial::inih::inireader)

if(NOT MSVC)
  target_link_options(otclient_core PUBLIC -flto=auto)
endif()

if(TOGGLE_PRE_COMPILED_HEADER)
  # === PRECOMPILED HEADER ===
  target_precompile_headers(otclient_core PRIVATE framework/pch.h)
  message(STATUS "Use precompiled header: ON")
else()
  message(STATUS "Use precompiled header: OFF")
endif(TOGGLE_PRE_COMPILED_HEADER)

if(SPEED_UP_BUILD_UNITY)
  set_target_properties(otclient_core PROPERTIES UNITY_BUILD ON)
  log_option_enabled("Build unity for speed up compilation")
endif(SPEED_UP_BUILD_UNITY)

target_sources(${PROJECT_NAME} PRIVATE main.cpp)

target_link_libraries(${PROJECT_NAME} PRIVATE otclient_core)

# *****************************************************************************
# Build flags
# *****************************************************************************
if (NOT MSVC)
  if (CMAKE_COMPILER_IS_GNUCXX)
    target_compile_options(otclient_core PRIVATE -Wno-deprecated-declarations)
  endif()
endif()

if(THREADS_HAVE_PTHREAD_ARG)
  target_compile_options(otclient_core PUBLIC "-pthread")
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Release")
  add_definitions(-DNDEBUG)
endif()

# *****************************************************************************
# Definitions code
# *****************************************************************************

# === ASAN ===
if(ASAN_ENABLED)
  log_option_enabled("asan")

  if(MSVC)
    string(REGEX REPLACE "/RTC(su|[1su])" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    target_compile_options(otclient_core PUBLIC /fsanitize=address)
    target_link_options(${PROJECT_NAME} PUBLIC /fsanitize=address)
  else()
    target_compile_options(otclient_core PUBLIC -fsanitize=address)
    target_link_options(${PROJECT_NAME} PUBLIC -fsanitize=address)
  endif()
else()
  log_option_disabled("asan")
endif()

# === DEBUG LOG ===
# cmake -DDEBUG_LOG=ON ..
if(CMAKE_BUILD_TYPE MATCHES Debug)
  target_compile_definitions(otclient_core PRIVATE -DDEBUG_LOG=ON )
  log_option_enabled("DEBUG LOG")
else()
  log_option_disabled("DEBUG LOG")
endif(CMAKE_BUILD_TYPE MATCHES Debug)

target_compile_definitions(otclient_core PRIVATE ENABLE_DISCORD_RPC=${OTCLIENT_ENABLE_DISCORD_RPC})

# *****************************************************************************
# Includes and librarys
# *****************************************************************************
if(MSVC)

  # Set variables to have Windows Vista Value so httplib will build 'inet_pton'
  target_compile_definitions(otclient_core
          PUBLIC
          NTDDI_VERSION=0x06000000
          _WIN32_WINNT=0x0600
  )

  target_compile_options(otclient_core PUBLIC /MP /FS /Zf /EHsc /bigobj)

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
  elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
    string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
  elseif(CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    string(REPLACE "/Zi" "/Z7" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
    string(REPLACE "/Zi" "/Z7" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
  endif()

  if(BUILD_STATIC_LIBRARY)
    log_option_enabled("STATIC_LIBRARY")
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".lib")
    find_package(Vorbis REQUIRED)
    foreach(msvc_target IN ITEMS otclient_core ${PROJECT_NAME})
      if(TARGET ${msvc_target})
        set_property(TARGET ${msvc_target} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
      endif()
    endforeach()
    set(VCPKG_TARGET_TRIPLET "x64-windows-static" CACHE STRING "")
  else()
    log_option_disabled("STATIC_LIBRARY")
    set(VCPKG_TARGET_TRIPLET "x64-windows" CACHE STRING "")
    foreach(msvc_target IN ITEMS otclient_core ${PROJECT_NAME})
      if(TARGET ${msvc_target})
        set_property(TARGET ${msvc_target} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
      endif()
    endforeach()
  endif()

  target_include_directories(otclient_core
          PUBLIC
          $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/>
          $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
          ${LUAJIT_INCLUDE_DIR}
          ${Protobuf_INCLUDE_DIRS}
          ${VORBISFILE_INCLUDE_DIR}
          ${GMP_INCLUDE_DIR}
          ${OPENSSL_INCLUDE_DIR}
          ${PHYSFS_INCLUDE_DIR}
          ${PARALLEL_HASHMAP_INCLUDE_DIRS}
          ${NLOHMANN_JSON_INCLUDE_DIR}
          ${CPPCODEC_INCLUDE_DIRS}
  )
  target_link_libraries(otclient_core
          PUBLIC
          ${LUAJIT_LIBRARY}
          ${CMAKE_THREAD_LIBS_INIT}
          ${PHYSFS_LIBRARY}
          ${ZLIB_LIBRARY}
          ${NLOHMANN_JSON_LIBRARY}
          ${OPENGL_LIBRARIES}
          ${DirectX_LIBRARY}
          ${DirectX_LIBRARIES}
          ${OGG_LIBRARY}
          ${VORBISFILE_LIBRARY}
          ${VORBIS_LIBRARY}
          ${GMP_LIBRARY}
          ${OPENSSL_LIBRARIES}
          ${DBGHELP_LIBRARY}
          ${STDUUID}

          protobuf::libprotobuf protobuf
          absl::log_internal_check_op
          Threads::Threads
          GLEW::GLEW
          asio::asio
          OpenAL::OpenAL
          LibLZMA::LibLZMA
          winmm.lib
          pugixml::pugixml
          fmt::fmt-header-only
          utf8cpp::utf8cpp
  )

else() # Linux/macOS
  target_include_directories(otclient_core
          PUBLIC
          $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/>
          $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
          ${LUAJIT_INCLUDE_DIR}
          ${CMAKE_THREAD_LIBS_INIT}
          ${Protobuf_INCLUDE_DIRS}
          ${GMP_INCLUDE_DIR}
          ${PHYSFS_INCLUDE_DIR}
          ${PARALLEL_HASHMAP_INCLUDE_DIRS}
          ${NLOHMANN_JSON_INCLUDE_DIR}
          ${OPENSSL_INCLUDE_DIR}
          ${CPPCODEC_INCLUDE_DIRS}
  )
  target_link_libraries(otclient_core
          PUBLIC
          ${LUAJIT_LIBRARY}
          ${PHYSFS_LIBRARY}
          ${ZLIB_LIBRARY}
          ${NLOHMANN_JSON_LIBRARY}
          GLEW::GLEW
          ${OPENGL_LIBRARIES}
          ${DirectX_LIBRARY}
          ${DirectX_LIBRARIES}
          ${OGG_LIBRARY}
          ${VORBISFILE_LIBRARY}
          ${VORBIS_LIBRARY}
          ${GMP_LIBRARY}
          ${STDUUID}
          ${FOUNDATION}
          ${IOKIT}
          ${OPENSSL_LIBRARY}
          ${OPENSSL_CRYPTO_LIBRARY}
          ${HTTPLIB_LIBRARY}

          protobuf::libprotobuf protobuf
          absl::log_internal_check_op
          Threads::Threads
          $<$<PLATFORM_ID:Linux>:X11::X11>
          asio::asio
          OpenAL::OpenAL
          LibLZMA::LibLZMA
          pugixml::pugixml
          ZLIB::ZLIB
          OpenSSL::SSL
          OpenSSL::Crypto
          httplib::httplib
          fmt::fmt-header-only
          utf8cpp::utf8cpp
          Ogg::ogg
          Vorbis::vorbisfile
          Vorbis::vorbis
  )

  if(APPLE)
    target_link_libraries(otclient_core
            PUBLIC
            ${COCOA_LIBRARY}
            ${COREVIDEO_LIBRARY}
            ${QUARTZCORE_LIBRARY}
            ${OPENGL_FRAMEWORK}
    )
  endif()

  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(otclient_core
            PRIVATE
            -Wall -Wextra -Wpedantic
    )
  endif()

endif()
if(ENABLE_DISCORD_RPC)
        target_link_libraries(otclient_core PUBLIC ${DISCORDRPC_LIBRARY})
endif()

# *****************************************************************************
# Enable otclient console only for debug build
# *****************************************************************************
if(WIN32)
  set_target_properties(${PROJECT_NAME}
          PROPERTIES
          LINK_FLAGS_DEBUG "/SUBSYSTEM:CONSOLE"
          LINK_FLAGS_RELEASE "/SUBSYSTEM:windows /ENTRY:mainCRTStartup"
          LINK_FLAGS_RELWITHDEBINFO "/SUBSYSTEM:CONSOLE"
          LINK_FLAGS_MINSIZEREL "/SUBSYSTEM:windows /ENTRY:mainCRTStartup"
  )
endif(WIN32)

# *****************************************************************************
# Link compilation files folder
# *****************************************************************************

## Link compilation files to build/bin folder, else link to the main dir
if (TOGGLE_BIN_FOLDER)
  set_target_properties(${PROJECT_NAME}
          PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
  )
else()
  set_target_properties(${PROJECT_NAME}
          PROPERTIES
          RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/"
  )
endif()
