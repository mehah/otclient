include(CheckIncludeFileCXX)
set(CMAKE_REQUIRED_INCLUDES "${CMAKE_INSTALL_INCLUDEDIR}")
check_include_file_cxx(parallel_hashmap/phmap.h PHMAP_PHMAP_INCLUDE)
check_include_file_cxx(parallel_hashmap/btree.h PHMAP_BTREE_INCLUDE)
