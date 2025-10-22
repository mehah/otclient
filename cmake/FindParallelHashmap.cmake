# ––– FindParallelHashmap.cmake –––
# Locate the ParallelHashmap (parallel-hashmap) header-only library
#
# Defines:
#   PARALLEL_HASHMAP_FOUND
#   PARALLEL_HASHMAP_INCLUDE_DIRS
#
# Provides imported target:
#   ParallelHashmap::ParallelHashmap

# Look for the main header
find_path(PARALLEL_HASHMAP_INCLUDE_DIRS
    NAMES parallel_hashmap/phmap.h
    HINTS
        ${CMAKE_INSTALL_INCLUDEDIR}
        /usr/include
        /usr/local/include
        /usr/local/port/parallel-hashmap/include
)

# Determine if header file truly exists (no compiler check)
if (PARALLEL_HASHMAP_INCLUDE_DIRS AND EXISTS "${PARALLEL_HASHMAP_INCLUDE_DIRS}/parallel_hashmap/phmap.h")
    set(PARALLEL_HASHMAP_FOUND TRUE)
else()
    set(PARALLEL_HASHMAP_FOUND FALSE)
endif()

# Handle package status
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ParallelHashmap
    REQUIRED_VARS PARALLEL_HASHMAP_INCLUDE_DIRS PARALLEL_HASHMAP_FOUND
)

# Create imported interface target
if (PARALLEL_HASHMAP_FOUND AND NOT TARGET ParallelHashmap::ParallelHashmap)
    add_library(ParallelHashmap::ParallelHashmap INTERFACE IMPORTED)
    set_target_properties(ParallelHashmap::ParallelHashmap PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${PARALLEL_HASHMAP_INCLUDE_DIRS}"
    )
    message(STATUS "Found ParallelHashmap at: ${PARALLEL_HASHMAP_INCLUDE_DIRS}")
else()
    message(WARNING "ParallelHashmap not found — please install parallel-hashmap (e.g. pacman -S parallel-hashmap on Arch).")
endif()
