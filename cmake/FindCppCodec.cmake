# ––– FindCppCodec.cmake –––
# Find the cppcodec header-only library
#
# Variables set:
#   CPPCODEC_FOUND           – set to TRUE if found
#   CPPCODEC_INCLUDE_DIRS    – include directory to use
#   CPPCODEC_VERSION         – version string (optional if header defines it)
#
# Usage:
#   find_package(CppCodec REQUIRED)
#   target_link_libraries(myTarget PRIVATE CppCodec::CppCodec)

find_path(CPPCODEC_INCLUDE_DIRS
    NAMES cppcodec/base32_crockford.hpp
    HINTS
      ${CMAKE_INSTALL_PREFIX}/include
      /usr/include
      /usr/local/include
)

# Try to detect version (optional)
set(CPPCODEC_VERSION "")
if(CPPCODEC_INCLUDE_DIRS AND EXISTS "${CPPCODEC_INCLUDE_DIRS}/cppcodec/version.hpp")
    file(READ "${CPPCODEC_INCLUDE_DIRS}/cppcodec/version.hpp" _cppcodec_ver_content)
    string(REGEX MATCH "#define[ \t]+CPPCODEC_VERSION[ \t]+\"([0-9\\.]+)\"" _match "${_cppcodec_ver_content}")
    if(CMAKE_MATCH_1)
        set(CPPCODEC_VERSION "${CMAKE_MATCH_1}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CppCodec
    REQUIRED_VARS CPPCODEC_INCLUDE_DIRS
    VERSION_VAR CPPCODEC_VERSION
)

if(CPPCODEC_FOUND AND NOT TARGET CppCodec::CppCodec)
    add_library(CppCodec::CppCodec INTERFACE IMPORTED)
    set_target_properties(CppCodec::CppCodec PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CPPCODEC_INCLUDE_DIRS}"
    )
endif()
