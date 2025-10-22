# ––– FindObfuscate.cmake –––
# Locate the Obfuscate header-only library (obfuscate.h)
#
# Defines:
#   Obfuscate_FOUND
#   Obfuscate_INCLUDE_DIR
#
# Provides imported target:
#   Obfuscate::Obfuscate

# Look for the main header
find_path(Obfuscate_INCLUDE_DIR
    NAMES obfuscate.h
    HINTS
        ${CMAKE_INSTALL_INCLUDEDIR}
        /usr/include
        /usr/local/include
        /usr/local/port/obfuscate
        ${CMAKE_SOURCE_DIR}/third_party/obfuscate
)

# Determine if header file truly exists
if (Obfuscate_INCLUDE_DIR AND EXISTS "${Obfuscate_INCLUDE_DIR}/obfuscate.h")
    set(Obfuscate_FOUND TRUE)
else()
    set(Obfuscate_FOUND FALSE)
endif()

# Handle package status
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Obfuscate
    REQUIRED_VARS Obfuscate_INCLUDE_DIR Obfuscate_FOUND
)

# Create imported interface target
if (Obfuscate_FOUND AND NOT TARGET Obfuscate::Obfuscate)
    add_library(Obfuscate::Obfuscate INTERFACE IMPORTED)
    set_target_properties(Obfuscate::Obfuscate PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${Obfuscate_INCLUDE_DIR}"
    )
    message(STATUS "Found Obfuscate at: ${Obfuscate_INCLUDE_DIR}")
else()
    message(WARNING "Obfuscate not found — please install it or place obfuscate.h in an include path")
endif()
