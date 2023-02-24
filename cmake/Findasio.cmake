find_path(ASIO_INCLUDE_DIR asio.hpp)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(asio DEFAULT_MSG ASIO_INCLUDE_DIR)

add_library(asio::asio INTERFACE IMPORTED)
target_include_directories(asio::asio INTERFACE "${ASIO_INCLUDE_DIR}")
target_compile_definitions(asio::asio INTERFACE "ASIO_STANDALONE")
