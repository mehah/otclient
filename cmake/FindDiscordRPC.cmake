# Try to find the DISCORDRPC library
#  DISCORDRPC_FOUND - system has DISCORDRPC
#  DISCORDRPC_INCLUDE_DIR - the DISCORDRPC include directory
#  DISCORDRPC_LIBRARY - the DISCORDRPC library

FIND_PATH(DISCORDRPC_INCLUDE_DIR NAMES discord_rpc.h)
SET(_DISCORDRPC_STATIC_LIBS discord-rpc.lib libdiscord-rpc.a)
SET(_DISCORDRPC_SHARED_LIBS discord-rpc.lib libdiscord-rpc.dylib libdiscord-rpc.so)
IF(USE_STATIC_LIBS)
    FIND_LIBRARY(DISCORDRPC_LIBRARY NAMES ${_DISCORDRPC_STATIC_LIBS} ${_DISCORDRPC_SHARED_LIBS})
ELSE()
    FIND_LIBRARY(DISCORDRPC_LIBRARY NAMES ${_DISCORDRPC_SHARED_LIBS} ${_DISCORDRPC_STATIC_LIBS})
ENDIF()
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(DiscordRPC DEFAULT_MSG DISCORDRPC_LIBRARY DISCORDRPC_INCLUDE_DIR)
MARK_AS_ADVANCED(DISCORDRPC_LIBRARY DISCORDRPC_INCLUDE_DIR)
