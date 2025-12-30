include(FindPackageHandleStandardArgs)

find_package(unofficial-inih CONFIG QUIET)

if(TARGET unofficial::inih::libinih)
  add_library(inih::inih INTERFACE IMPORTED)
  target_link_libraries(inih::inih INTERFACE unofficial::inih::libinih)
endif()

if(TARGET unofficial::inih::inireader)
  add_library(inih::inireader INTERFACE IMPORTED)
  target_link_libraries(inih::inireader INTERFACE unofficial::inih::inireader)
endif()

if(TARGET inih::inih)
  set(inih_FOUND TRUE)
  return()
endif()

find_path(INIH_INCLUDE_DIR
  NAMES ini.h
  PATH_SUFFIXES inih include
)

find_library(INIH_LIBRARY
  NAMES inih libinih
)

# Optional: INIReader (C++ wrapper)
find_path(INIH_CPP_INCLUDE_DIR
  NAMES INIReader.h
  PATH_SUFFIXES inih cpp include
)

find_library(INIH_CPP_LIBRARY
  NAMES inireader libinireader inihcpp libinihcpp
)

find_package_handle_standard_args(inih
  REQUIRED_VARS INIH_INCLUDE_DIR INIH_LIBRARY
)

if(inih_FOUND)
  add_library(inih::inih UNKNOWN IMPORTED)
  set_target_properties(inih::inih PROPERTIES
    IMPORTED_LOCATION "${INIH_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${INIH_INCLUDE_DIR}"
  )

  if(INIH_CPP_INCLUDE_DIR AND INIH_CPP_LIBRARY)
    add_library(inih::inireader UNKNOWN IMPORTED)
    set_target_properties(inih::inireader PROPERTIES
      IMPORTED_LOCATION "${INIH_CPP_LIBRARY}"
      INTERFACE_INCLUDE_DIRECTORIES "${INIH_CPP_INCLUDE_DIR}"
    )
    target_link_libraries(inih::inireader INTERFACE inih::inih)
  endif()
endif()
