set(client_LIBRARIES "")
set(client_DEFINITIONS "")
set(client_INCLUDE_DIRS "")

# client options
set(client_DEFINITIONS ${client_DEFINITIONS} -DCLIENT)

option(BOT_PROTECTION "Enable bot protection" ON)
if(BOT_PROTECTION)
    set(client_DEFINITIONS ${client_DEFINITIONS} -DBOT_PROTECTION)
    message(STATUS "Bot protection: ON")
else(BOT_PROTECTION)
    message(STATUS "Bot protection: OFF")
endif(BOT_PROTECTION)

set(client_SOURCES ${client_SOURCES}
    # client
    ${CMAKE_CURRENT_LIST_DIR}/const.h
    ${CMAKE_CURRENT_LIST_DIR}/global.h
    ${CMAKE_CURRENT_LIST_DIR}/config.h
    ${CMAKE_CURRENT_LIST_DIR}/luafunctions.cpp
    ${CMAKE_CURRENT_LIST_DIR}/client.cpp
    ${CMAKE_CURRENT_LIST_DIR}/client.h

    # core
    ${CMAKE_CURRENT_LIST_DIR}/animatedtext.cpp
    ${CMAKE_CURRENT_LIST_DIR}/animatedtext.h
    ${CMAKE_CURRENT_LIST_DIR}/animator.h
    ${CMAKE_CURRENT_LIST_DIR}/animator.cpp
)
if(USE_PROTOBUF)
    find_package(Protobuf REQUIRED)
    find_package(LibLZMA REQUIRED)
    find_package(nlohmann_json REQUIRED)

    set(clie ${client_LIBRARIES}
        ${PROTOBUF_LIBRARY}
        ${LIBLZMA_LIBRARIES}
        ${NLOHMANN_JSON_LIBRARY}
    )

    set(client_INCLUDE_DIRS ${client_INCLUDE_DIRS}
        ${PROTOBUF_INCLUDE_DIRS}
        ${LIBLZMA_INCLUDE_DIRS}
        ${NLOHMANN_JSON_INCLUDE_DIR}
    )

    # protobuf
    set(protobuf_PATH ${CMAKE_CURRENT_LIST_DIR}/protobuf/proto)
    set(protobuf_MODULES
        appearances
        shared
    )

    foreach(protobuf_FILENAME ${protobuf_MODULES})

        set(protobuf_SOURCES
            ${CMAKE_CURRENT_LIST_DIR}/protobuf/${protobuf_FILENAME}.pb.cc
            ${CMAKE_CURRENT_LIST_DIR}/protobuf/${protobuf_FILENAME}.pb.h
        )

        set(framework_SOURCES ${framework_SOURCES} ${protobuf_SOURCES})

        if(NOT WIN32)
            add_custom_command(
                OUTPUT ${protobuf_SOURCES}
                DEPENDS ${protobuf_PATH}/${protobuf_FILENAME}.proto
                COMMAND protoc --cpp_out=../ ${protobuf_FILENAME}.proto
                WORKING_DIRECTORY ${protobuf_PATH}
                COMMENT "Compiling ${protobuf_FILENAME}.proto"
            )
        endif()

    endforeach()
    set(client_DEFINITIONS ${client_DEFINITIONS} -DUSE_PROTOBUF)

    set(client_SOURCES ${client_SOURCES}
        # 12.70
        ${CMAKE_CURRENT_LIST_DIR}/spriteappearances.cpp
        ${CMAKE_CURRENT_LIST_DIR}/spriteappearances.h
    )
endif()
message(STATUS "Use Protobuf for protocol 12+: " ${USE_PROTOBUF})

set(client_SOURCES ${client_SOURCES}
    ${CMAKE_CURRENT_LIST_DIR}/container.cpp
    ${CMAKE_CURRENT_LIST_DIR}/container.h
    ${CMAKE_CURRENT_LIST_DIR}/creature.cpp
    ${CMAKE_CURRENT_LIST_DIR}/creature.h
    ${CMAKE_CURRENT_LIST_DIR}/declarations.h
    ${CMAKE_CURRENT_LIST_DIR}/effect.cpp
    ${CMAKE_CURRENT_LIST_DIR}/effect.h
    ${CMAKE_CURRENT_LIST_DIR}/game.cpp
    ${CMAKE_CURRENT_LIST_DIR}/game.h
    ${CMAKE_CURRENT_LIST_DIR}/shadermanager.cpp
    ${CMAKE_CURRENT_LIST_DIR}/shadermanager.h
    ${CMAKE_CURRENT_LIST_DIR}/item.cpp
    ${CMAKE_CURRENT_LIST_DIR}/item.h
    ${CMAKE_CURRENT_LIST_DIR}/localplayer.cpp
    ${CMAKE_CURRENT_LIST_DIR}/localplayer.h
    ${CMAKE_CURRENT_LIST_DIR}/map.cpp
    ${CMAKE_CURRENT_LIST_DIR}/map.h
    ${CMAKE_CURRENT_LIST_DIR}/mapio.cpp
    ${CMAKE_CURRENT_LIST_DIR}/mapview.cpp
    ${CMAKE_CURRENT_LIST_DIR}/mapview.h
    ${CMAKE_CURRENT_LIST_DIR}/minimap.cpp
    ${CMAKE_CURRENT_LIST_DIR}/minimap.h
    ${CMAKE_CURRENT_LIST_DIR}/lightview.cpp
    ${CMAKE_CURRENT_LIST_DIR}/lightview.h
    ${CMAKE_CURRENT_LIST_DIR}/missile.cpp
    ${CMAKE_CURRENT_LIST_DIR}/missile.h
    ${CMAKE_CURRENT_LIST_DIR}/outfit.cpp
    ${CMAKE_CURRENT_LIST_DIR}/outfit.h
    ${CMAKE_CURRENT_LIST_DIR}/player.cpp
    ${CMAKE_CURRENT_LIST_DIR}/player.h
    ${CMAKE_CURRENT_LIST_DIR}/spritemanager.cpp
    ${CMAKE_CURRENT_LIST_DIR}/spritemanager.h
    ${CMAKE_CURRENT_LIST_DIR}/statictext.cpp
    ${CMAKE_CURRENT_LIST_DIR}/statictext.h
    ${CMAKE_CURRENT_LIST_DIR}/thing.cpp
    ${CMAKE_CURRENT_LIST_DIR}/thing.h
    ${CMAKE_CURRENT_LIST_DIR}/thingtypemanager.cpp
    ${CMAKE_CURRENT_LIST_DIR}/thingtypemanager.h
    ${CMAKE_CURRENT_LIST_DIR}/thingtype.cpp
    ${CMAKE_CURRENT_LIST_DIR}/thingtype.h
    ${CMAKE_CURRENT_LIST_DIR}/itemtype.cpp
    ${CMAKE_CURRENT_LIST_DIR}/itemtype.h
    ${CMAKE_CURRENT_LIST_DIR}/tile.cpp
    ${CMAKE_CURRENT_LIST_DIR}/tile.h
    ${CMAKE_CURRENT_LIST_DIR}/houses.cpp
    ${CMAKE_CURRENT_LIST_DIR}/houses.h
    ${CMAKE_CURRENT_LIST_DIR}/towns.cpp
    ${CMAKE_CURRENT_LIST_DIR}/towns.h
    ${CMAKE_CURRENT_LIST_DIR}/creatures.cpp
    ${CMAKE_CURRENT_LIST_DIR}/creatures.h

    # lua
    ${CMAKE_CURRENT_LIST_DIR}/luavaluecasts.cpp
    ${CMAKE_CURRENT_LIST_DIR}/luavaluecasts.h

    # net
    ${CMAKE_CURRENT_LIST_DIR}/protocolcodes.cpp
    ${CMAKE_CURRENT_LIST_DIR}/protocolcodes.h
    ${CMAKE_CURRENT_LIST_DIR}/protocolgame.cpp
    ${CMAKE_CURRENT_LIST_DIR}/protocolgame.h
    ${CMAKE_CURRENT_LIST_DIR}/protocolgameparse.cpp
    ${CMAKE_CURRENT_LIST_DIR}/protocolgamesend.cpp

    # ui
    ${CMAKE_CURRENT_LIST_DIR}/uicreature.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uicreature.h
    ${CMAKE_CURRENT_LIST_DIR}/uiitem.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uiitem.h
    ${CMAKE_CURRENT_LIST_DIR}/uimap.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uimap.h
    ${CMAKE_CURRENT_LIST_DIR}/uiminimap.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uiminimap.h
    ${CMAKE_CURRENT_LIST_DIR}/uiprogressrect.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uiprogressrect.h
    ${CMAKE_CURRENT_LIST_DIR}/uimapanchorlayout.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uimapanchorlayout.h
    ${CMAKE_CURRENT_LIST_DIR}/uisprite.cpp
    ${CMAKE_CURRENT_LIST_DIR}/uisprite.h

    # util
    ${CMAKE_CURRENT_LIST_DIR}/position.h
)

if(NOT MSVC)
    set_source_files_properties(${CMAKE_CURRENT_LIST_DIR}/luafunctions.cpp
                                PROPERTIES LANGUAGE CXX COMPILE_FLAGS "-g0 -Os")
endif()

include_directories(${client_INCLUDE_DIRS})
add_definitions(${client_DEFINITIONS})