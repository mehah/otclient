
project(otclient)

# *****************************************************************************
# Options
# *****************************************************************************
option(FRAMEWORK_SOUND "Use SOUND " ON)
option(FRAMEWORK_XML "Use XML " ON)
option(FRAMEWORK_NET "Use NET " ON)
option(FRAMEWORK_SQL "Use SQL" OFF)
option(TOOGLE_DIRECTX "Use DX9 support" OFF)

# *****************************************************************************
# Cmake Features
# *****************************************************************************
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Global gives error when building spdlog
# Avoid changes by cmake/make on the source tree
# https://gitlab.kitware.com/cmake/cmake/issues/18403
set(CMAKE_DISABLE_SOURCE_CHANGES ON)
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

# Make will print more details
set(CMAKE_VERBOSE_MAKEFILE OFF)

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(Boost_USE_MULTITHREADED ON)

# Define Framework Options for use in compilation
set(FRAMEWORK_DEFINITIONS "")
if (FRAMEWORK_SOUND)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_SOUND)
endif()
if (FRAMEWORK_XML)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_XML)
endif()
if (FRAMEWORK_NET)
	set(FRAMEWORK_DEFINITIONS ${FRAMEWORK_DEFINITIONS} -DFRAMEWORK_NET)
endif()

# *****************************************************************************
# Client
# *****************************************************************************
if (MSVC)
	add_executable(${PROJECT_NAME} "" ../cmake/icon/otcicon.rc)
else()
	add_executable(${PROJECT_NAME} "")
endif()

add_definitions(-D_WIN32_WINNT=0x0501)
add_definitions(${FRAMEWORK_DEFINITIONS})

# *****************************************************************************
# Packages / Libs
# *****************************************************************************
find_package(Boost 1.53.0 COMPONENTS system thread filesystem REQUIRED)
find_package(OpenSSL QUIET)
find_package(spdlog CONFIG REQUIRED)
find_package(Protobuf REQUIRED)
find_package(PhysFS REQUIRED)
find_package(ZLIB REQUIRED)
find_package(Protobuf REQUIRED)
find_package(LibLZMA REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(DbgHelp REQUIRED)
# OpenGL/GLEW = Graphics
find_package(OpenGL REQUIRED)
find_package(GLEW REQUIRED)
if (WIN32)
	find_package(LuaJIT REQUIRED)
endif(WIN32)
if (UNIX)
	find_package(Lua REQUIRED)
endif(UNIX)
if(NOT OPENSSL_FOUND)
	find_package(GMP REQUIRED)
endif()
if(TOOGLE_DIRECTX)
	find_package(DirectX REQUIRED)
endif()
if(FRAMEWORK_SOUND)
	find_package(OpenAL REQUIRED)
	find_package(VorbisFile REQUIRED)
	find_package(Vorbis REQUIRED)
	find_package(Ogg REQUIRED)
endif()
if(FRAMEWORK_SQL)
	find_package(MySQL REQUIRED)
endif()

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
	framework/luaengine/lbitlib.cpp
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
	framework/platform/win32crashhandler.cpp
	framework/platform/win32platform.cpp
	framework/platform/win32window.cpp
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
if (MSVC)
	target_include_directories(${PROJECT_NAME}
		PRIVATE
		${CMAKE_SOURCE_DIR}/src
		${MYSQL_INCLUDE_DIR}
		${LUAJIT_INCLUDE_DIR}
		${Boost_INCLUDE_DIRS}
		${PUGIXML_INCLUDE_DIR}
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
		${Boost_LIBRARY_DIRS}
		${Boost_LIBRARIES}
		${PUGIXML_LIBRARIES}
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

		spdlog::spdlog
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
		${PHYSFS_INCLUDE_DIR}
		${LIBLZMA_INCLUDE_DIRS}
		${NLOHMANN_JSON_INCLUDE_DIR}
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
		${DBGHELP_LIBRARY}

		Boost::boost
		Boost::filesystem
		Boost::system
		Threads::Threads
		unofficial::libmariadb unofficial::mariadbclient
		pugixml::pugixml
		spdlog::spdlog
	)
endif (MSVC)

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
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)