# ––– FindBSThreadPool.cmake –––
# Locate the header-only BS_thread_pool library (BS_thread_pool.hpp)
#
# Defines:
#   BSTHREADPOOL_FOUND
#   BSTHREADPOOL_INCLUDE_DIR
#
# Provides imported target:
#   BSThreadPool::BSThreadPool

# Look for the main header
find_path(BSTHREADPOOL_INCLUDE_DIR
    NAMES BS_thread_pool.hpp
    HINTS
        ${CMAKE_INSTALL_INCLUDEDIR}
        /usr/include
        /usr/local/include
        /usr/local/port/thread-pool
        ${CMAKE_SOURCE_DIR}/third_party/thread-pool
)

# Verify the file exists
if (BSTHREADPOOL_INCLUDE_DIR AND EXISTS "${BSTHREADPOOL_INCLUDE_DIR}/BS_thread_pool.hpp")
    set(BSTHREADPOOL_FOUND TRUE)
else()
    set(BSTHREADPOOL_FOUND FALSE)
endif()

# Handle package status
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(BSThreadPool
    REQUIRED_VARS BSTHREADPOOL_INCLUDE_DIR
)

# Create imported interface target
if (BSTHREADPOOL_FOUND AND NOT TARGET BSThreadPool::BSThreadPool)
    add_library(BSThreadPool::BSThreadPool INTERFACE IMPORTED)
    set_target_properties(BSThreadPool::BSThreadPool PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${BSTHREADPOOL_INCLUDE_DIR}"
    )
    message(STATUS "Found BS_thread_pool at: ${BSTHREADPOOL_INCLUDE_DIR}")
else()
    message(WARNING "BS_thread_pool not found — please install it or place BS_thread_pool.hpp in an include path")
endif()
