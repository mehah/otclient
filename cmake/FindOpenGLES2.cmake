# Try to find the OpenGLES2 library
#  OPENGLES2_FOUND - system has OpenGL ES 2.0
#  OPENGLES2_INCLUDE_DIR - the OpenGL ES 2.0 include directory
#  OPENGLES2_LIBRARY - the OpenGL ES 2.0 library

FIND_PATH(OPENGLES2_INCLUDE_DIR NAMES GLES2/gl2.h)
SET(_OPENGLES2_STATIC_LIBS libGLESv2.a)
SET(_OPENGLES2_SHARED_LIBS libGLESv2.dll.a GLESv2)
IF(USE_STATIC_LIBS)
    FIND_LIBRARY(OPENGLES2_LIBRARY NAMES ${_OPENGLES2_STATIC_LIBS} ${_OPENGLES2_SHARED_LIBS})
ELSE()
    FIND_LIBRARY(OPENGLES2_LIBRARY NAMES ${_OPENGLES2_SHARED_LIBS} ${_OPENGLES2_STATIC_LIBS})
ENDIF()
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(OpenGLES2 DEFAULT_MSG OPENGLES2_LIBRARY OPENGLES2_INCLUDE_DIR)
MARK_AS_ADVANCED(OPENGLES2_LIBRARY OPENGLES2_INCLUDE_DIR)
