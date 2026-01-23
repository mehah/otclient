vcpkg_from_gitlab(
    GITLAB_URL https://gitlab.freedesktop.org
    OUT_SOURCE_PATH SOURCE_PATH
    REPO freetype/freetype
    REF "VER-${VERSION}"
    SHA512 62dc2f9da8b5e5c8a20e0de0c1c84b23e63c5f7d36c74ace0452d01d19bb5db1c5e45b3fa38b5b5a9dbf2da3fc7b4f6d1eb8edb0c5f8ae4a0b4f5e3c2e6d3e7f9
    HEAD_REF master
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        brotli  FT_REQUIRE_BROTLI
        bzip2   FT_REQUIRE_BZIP2
        error-strings   FT_ENABLE_ERROR_STRINGS
        png     FT_REQUIRE_PNG
        zlib    FT_REQUIRE_ZLIB
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        -DFT_DISABLE_HARFBUZZ=ON
        -DCMAKE_C_FLAGS="-pthread"
        -DCMAKE_CXX_FLAGS="-pthread"
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/freetype)
vcpkg_fixup_pkgconfig()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# Cleanup
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/LICENSE.TXT" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
