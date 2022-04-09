
project(otclient)

# *****************************************************************************
# Options
# *****************************************************************************
option(TOGGLE_FRAMEWORK_SOUND "Use SOUND " ON)
option(TOGGLE_FRAMEWORK_XML "Use XML " ON)
option(TOGGLE_FRAMEWORK_NET "Use NET " ON)
option(TOGGLE_DIRECTX "Use DX9 support" OFF)
option(TOGGLE_STATIC_LIBS "Use shared libraries (dlls)" ON)
option(TOGGLE_BOT_PROTECTION "Use bot protection" ON)
option(TOGGLE_PRE_COMPILED_HEADER "Use precompiled header (speed up compile)" OFF)

# *****************************************************************************
# Cmake Features
# *****************************************************************************
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Make will print more details
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# *****************************************************************************
# Options Code
# *****************************************************************************

# Define Framework options for use in compilation
set(FRAMEWORK_DEFINITIONS "")
if (TOGGLE_FRAMEWORK_SOUND)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_SOUND)
endif()
if (TOGGLE_FRAMEWORK_XML)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_XML)
endif()
if (TOGGLE_FRAMEWORK_NET)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_NET)
endif()

# Set for use static libs if is x86 build
# CMAKE_SIZEOF_VOID_P EQUAL 4 = x86 build
if(CMAKE_SIZEOF_VOID_P EQUAL 4 AND TOGGLE_STATIC_LIBS AND NOT APPLE)
	set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -static-libgcc -static-libstdc++")
	message(STATUS "Link to static libraries: ON")
else()
	message(STATUS "Link to static libraries: OFF")
endif()

# Set for use bot protection
if(TOGGLE_BOT_PROTECTION)
	message(STATUS "Bot protection: ON")
else(TOGGLE_BOT_PROTECTION)
	message(STATUS "Bot protection: OFF")
endif(TOGGLE_BOT_PROTECTION)

# Set for use precompiled header
if(TOGGLE_PRE_COMPILED_HEADER)
	include(cotire)
	cotire(${PROJECT_NAME})
	message(STATUS "Use precompiled header: ON")
else()
	message(STATUS "Use precompiled header: OFF")
endif(TOGGLE_PRE_COMPILED_HEADER)

set(VERSION "1.0.0")

# *****************************************************************************
# Client
# *****************************************************************************
if (MSVC)
	add_executable(${PROJECT_NAME} "" ../cmake/icon/otcicon.rc)
else()
	add_executable(${PROJECT_NAME} "")
endif()

# *****************************************************************************
# Definitions code
# *****************************************************************************

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
# Set bot protection
if(TOGGLE_BOT_PROTECTION)
	add_definitions(-DBOT_PROTECTION)
endif(TOGGLE_BOT_PROTECTION)
add_definitions(-D_WIN32_WINNT=0x0501)
add_definitions(${FRAMEWORK_DEFINITIONS})
add_definitions(-D"VERSION=${VERSION}")

# *****************************************************************************
# Packages / Libs
# *****************************************************************************
find_package(OpenSSL QUIET)
find_package(PhysFS REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Protobuf REQUIRED)
find_package(LibLZMA REQUIRED)
find_package(nlohmann_json REQUIRED)
# OpenGL/GLEW = Graphics
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
if(UNIX)
	find_package(X11 REQUIRED)
endif()
find_package(LuaJIT REQUIRED)
if(WIN32)
	find_package(DbgHelp REQUIRED)
endif(WIN32)
if(NOT OPENSSL_FOUND)
	find_package(GMP REQUIRED)
endif()
if(TOGGLE_DIRECTX)
	find_package(DirectX REQUIRED)
endif()
if(TOGGLE_FRAMEWORK_SOUND)
	find_package(OpenAL REQUIRED)
	find_package(VorbisFile REQUIRED)
	find_package(Vorbis REQUIRED)
	find_package(Ogg REQUIRED)
endif()

find_path(ASIO_INCLUDE_PATH asio.hpp HINTS 
	"/usr/include"
	"/usr/local/include"
	"/opt/local/include"
)

if(ASIO_INCLUDE_PATH)
	message(STATUS "Found existing ASIO install")
endif(ASIO_INCLUDE_PATH)

# *****************************************************************************
# OTClient source files configuration
# *****************************************************************************
target_sources(${PROJECT_NAME}
	PRIVATE
	client/animatedtext.cpp
	client/animator.cpp
	client/spriteappearances.cpp
	client/client.cpp
	client/container.cpp
	client/creature.cpp
	client/creatures.cpp
	client/effect.cpp
	client/game.cpp
	client/houses.cpp
	client/item.cpp
	client/itemtype.cpp
	client/lightview.cpp
	client/localplayer.cpp
	client/luafunctions.cpp
	client/luavaluecasts.cpp
	client/map.cpp
	client/mapio.cpp
	client/mapview.cpp
	client/minimap.cpp
	client/missile.cpp
	client/outfit.cpp
	client/player.cpp
	client/protocolcodes.cpp
	client/protocolgame.cpp
	client/protocolgameparse.cpp
	client/protocolgamesend.cpp
	client/shadermanager.cpp
	client/spritemanager.cpp
	client/statictext.cpp
	client/thing.cpp
	client/thingtype.cpp
	client/thingtypemanager.cpp
	client/tile.cpp
	client/towns.cpp
	client/uicreature.cpp
	client/uiitem.cpp
	client/uimap.cpp
	client/uimapanchorlayout.cpp
	client/uiminimap.cpp
	client/uiprogressrect.cpp
	client/uisprite.cpp
	framework/core/adaptativeframecounter.cpp
	framework/core/application.cpp
	framework/core/asyncdispatcher.cpp
	framework/core/binarytree.cpp
	framework/core/clock.cpp
	framework/core/config.cpp
	framework/core/configmanager.cpp
	framework/core/event.cpp
	framework/core/eventdispatcher.cpp
	framework/core/filestream.cpp
	framework/core/graphicalapplication.cpp
	framework/core/logger.cpp
	framework/core/module.cpp
	framework/core/modulemanager.cpp
	framework/core/resourcemanager.cpp
	framework/core/scheduledevent.cpp
	framework/core/timer.cpp
	framework/graphics/animatedtexture.cpp
	framework/graphics/apngloader.cpp
	framework/graphics/bitmapfont.cpp
	framework/graphics/cachedtext.cpp
	framework/graphics/coordsbuffer.cpp
	framework/graphics/drawpool.cpp
	framework/graphics/fontmanager.cpp
	framework/graphics/framebuffer.cpp
	framework/graphics/framebuffermanager.cpp
	framework/graphics/graphics.cpp
	framework/graphics/image.cpp
	framework/graphics/ogl/painterogl.cpp
	framework/graphics/ogl/painterogl1.cpp
	framework/graphics/ogl/painterogl2.cpp
	framework/graphics/painter.cpp
	framework/graphics/paintershaderprogram.cpp
	framework/graphics/particle.cpp
	framework/graphics/particleaffector.cpp
	framework/graphics/particleeffect.cpp
	framework/graphics/particleemitter.cpp
	framework/graphics/particlemanager.cpp
	framework/graphics/particlesystem.cpp
	framework/graphics/particletype.cpp
	framework/graphics/pool.cpp
	framework/graphics/shader.cpp
	framework/graphics/shaderprogram.cpp
	framework/graphics/texture.cpp
	framework/graphics/texturemanager.cpp
	framework/input/mouse.cpp
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
	framework/net/server.cpp
	framework/otml//otmldocument.cpp
	framework/otml//otmlemitter.cpp
	framework/otml//otmlexception.cpp
	framework/otml//otmlnode.cpp
	framework/otml//otmlparser.cpp
	framework/platform/platform.cpp
	framework/platform/platformwindow.cpp
	framework/platform/unixcrashhandler.cpp
	framework/platform/unixplatform.cpp
	framework/platform/win32crashhandler.cpp
	framework/platform/win32platform.cpp
	framework/platform/win32window.cpp
	framework/platform/x11window.cpp
	framework/sound/combinedsoundsource.cpp
	framework/sound/oggsoundfile.cpp
	framework/sound/soundbuffer.cpp
	framework/sound/soundchannel.cpp
	framework/sound/soundfile.cpp
	framework/sound/soundmanager.cpp
	framework/sound/soundsource.cpp
	framework/sound/streamsoundsource.cpp
	framework/stdext/demangle.cpp
	framework/stdext/math.cpp
	framework/stdext/net.cpp
	framework/stdext/string.cpp
	framework/stdext/time.cpp
	framework/ui/uianchorlayout.cpp
	framework/ui/uiboxlayout.cpp
	framework/ui/uigridlayout.cpp
	framework/ui/uihorizontallayout.cpp
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
	framework/util/color.cpp
	framework/util/crypt.cpp
	framework/xml/tinystr.cpp
	framework/xml/tinyxml.cpp
	framework/xml/tinyxmlerror.cpp
	framework/xml/tinyxmlparser.cpp
	protobuf/appearances.pb.cc
	main.cpp
)

# *****************************************************************************
# Includes and librarys
# *****************************************************************************
if(MSVC)
	target_include_directories(${PROJECT_NAME}
		PRIVATE
		${CMAKE_SOURCE_DIR}/src
		${MYSQL_INCLUDE_DIR}
		${LUAJIT_INCLUDE_DIR}
		${Protobuf_INCLUDE_DIRS}
		${OPENAL_INCLUDE_DIR}
		${VORBISFILE_INCLUDE_DIR}
		${MYSQL_INCLUDE_DIR}
		${GMP_INCLUDE_DIR}
		${OPENSSL_INCLUDE_DIR}
		${PHYSFS_INCLUDE_DIR}
		${LIBLZMA_INCLUDE_DIRS}
		${NLOHMANN_JSON_INCLUDE_DIR}
	)
	target_link_libraries(${PROJECT_NAME}
		PRIVATE
		${MYSQL_CLIENT_LIBS}
		${LUAJIT_LIBRARY}
		${CMAKE_THREAD_LIBS_INIT}
		${PHYSFS_LIBRARY}
		${ZLIB_LIBRARY}
		${PROTOBUF_LIBRARY}
		${LIBLZMA_LIBRARIES}
		${NLOHMANN_JSON_LIBRARY}
		${GLEW_LIBRARY}
		${OPENGL_LIBRARIES}
		${DirectX_LIBRARY}
		${DirectX_LIBRARIES}
		${OPENAL_LIBRARY}
		${VORBISFILE_LIBRARY}
		${VORBIS_LIBRARY}
		${OGG_LIBRARY}
		${MYSQL_LIBRARY}
		${GMP_LIBRARY}
		${OPENSSL_LIBRARIES}
		${DBGHELP_LIBRARY}

		Threads::Threads
		GLEW::GLEW
	)
	
else()
	target_include_directories(${PROJECT_NAME}
		PRIVATE
		${CMAKE_SOURCE_DIR}/src
		${LUAJIT_INCLUDE_DIR}
		${Protobuf_INCLUDE_DIRS}
		${OPENAL_INCLUDE_DIR}
		${VORBISFILE_INCLUDE_DIR}
		${MYSQL_INCLUDE_DIR}
		${GMP_INCLUDE_DIR}
		${OPENSSL_INCLUDE_DIR}
		${OPENGL_INCLUDE_DIR}
		${PHYSFS_INCLUDE_DIR}
		${LIBLZMA_INCLUDE_DIRS}
		${NLOHMANN_JSON_INCLUDE_DIR}
		${X11_INCLUDE_DIR}
	)
	target_link_libraries(${PROJECT_NAME}
		PRIVATE
		${LUAJIT_LIBRARY}
		${PHYSFS_LIBRARY}
		${ZLIB_LIBRARY}
		${PROTOBUF_LIBRARY}
		${LIBLZMA_LIBRARIES}
		${NLOHMANN_JSON_LIBRARY}
		${GLEW_LIBRARY}
		${OPENGL_LIBRARIES}
		${DirectX_LIBRARY}
		${DirectX_LIBRARIES}
		${OPENAL_LIBRARY}
		${VORBISFILE_LIBRARY}
		${VORBIS_LIBRARY}
		${OGG_LIBRARY}
		${MYSQL_LIBRARY}
		${GMP_LIBRARY}
		${OPENSSL_LIBRARIES}
		${X11_LIBRARIES}

		Threads::Threads
		X11::X11
	)
endif()

# *****************************************************************************
# Enable otclient console only for debug build
# *****************************************************************************
if(WIN32)
	set_target_properties(${PROJECT_NAME}
	PROPERTIES
		LINK_FLAGS_DEBUG "/SUBSYSTEM:CONSOLE"
		LINK_FLAGS_RELEASE "/SUBSYSTEM:windows /ENTRY:mainCRTStartup"
		LINK_FLAGS_RELWITHDEBINFO "/SUBSYSTEM:windows /ENTRY:mainCRTStartup"
		LINK_FLAGS_MINSIZEREL "/SUBSYSTEM:windows /ENTRY:mainCRTStartup"
	)
endif(WIN32)

# *****************************************************************************
# Link compilation files to the "build/release/bin" folder
# *****************************************************************************
set_target_properties(${PROJECT_NAME}
PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
)
