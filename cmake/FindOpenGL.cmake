# Try to find OpenGL
# Once done this will define
#
# OPENGL_FOUND        - system has OpenGL and it should be used
# OPENGL_XMESA_FOUND  - system has XMESA, and it should be used.
# OPENGL_GLU_FOUND    - system has GLU and it should be used.
# OPENGL_INCLUDE_DIR  - where the GL include directory can be found
# OPENGL_LIBRARIES    - Link these to use OpenGL
#
#
# Also defined, but not for general use are
# OPENGL_gl_LIBRARY   - Path to OpenGL Library
# OPENGL_glu_LIBRARY  - Path to GLU Library
#

IF (WIN32)
  IF (CYGWIN)

    FIND_PATH(OPENGL_INCLUDE_DIR GL/gl.h
      /usr/include
      /usr/include/w32api
      /usr/X11R6/include
    )

    FIND_LIBRARY(OPENGL_gl_LIBRARY opengl32
      /usr/lib
      /usr/lib/w32api
    )

    FIND_LIBRARY(OPENGL_glu_LIBRARY glu32
      /usr/lib
      /usr/lib/w32api
    )

  ELSE (CYGWIN)

    IF(BORLAND)
      SET (OPENGL_gl_LIBRARY import32 CACHE STRING "OpenGL library for win32")
      SET (OPENGL_glu_LIBRARY import32 CACHE STRING "GLU library for win32")
    ELSE(BORLAND)
      SET (OPENGL_gl_LIBRARY opengl32 CACHE STRING "OpenGL library for win32")
      SET (OPENGL_glu_LIBRARY glu32 CACHE STRING "GLU library for win32")
    ENDIF(BORLAND)

  ENDIF (CYGWIN)

ELSE (WIN32)

  IF (APPLE)

    # On MacOS X the default method is to use OpenGL.framework.
    # Changing the OPENGL_USE_APPLE_X11 option will allow using
    # OpenGL with X11 instead.
    OPTION (OPENGL_USE_APPLE_X11 "Use X11 OpenGL on OSX?" ON)

    IF (NOT OPENGL_USE_APPLE_X11)

      # When searching for the include directory, find the location
      # for the OpenGL framework rather than an individual header file.
      FIND_PATH(OPENGL_INCLUDE_DIR OpenGL.framework
        /System/Library/Frameworks
        /Library/Frameworks
        ~/Library/Frameworks
      )

      # Frameworks requires some specific link flags that are not
      # currently present within CMake. Therefore, explicity set
      # the link commands here.
      SET (OPENGL_gl_LIBRARY "-framework OpenGL" CACHE STRING "OpenGL lib for OSX")
      SET (OPENGL_glu_LIBRARY "-framework AGL" CACHE STRING "AGL lib for OSX")

    ENDIF (NOT OPENGL_USE_APPLE_X11)

  ELSE (APPLE)

    # Because there are some parsing conflicts, setting this variable
    # is a temporary work-around for finding libraries on other unix
    # type systems.
    SET(NOT_APPLE ON)

  ENDIF (APPLE)

  # A nicer approach here would be something like:
  # IF (OPENGL_USE_APPLE_X11 OR NOT(APPLE)), but that doesn't work.
  # This is why the NOT_APPLE variable was defined above.
  IF (OPENGL_USE_APPLE_X11 OR NOT_APPLE)

    # The first line below is to make sure that the proper headers
    # are used on a Linux machine with the NVidia drivers installed.
    # They replace Mesa with NVidia's own library but normally do not
    # install headers and that causes the linking to
    # fail since the compiler finds the Mesa headers but NVidia's library.
    # Make sure the NVIDIA directory comes BEFORE the others.
    #  - Atanas Georgiev <atanas at cs.columbia.edu>

    FIND_PATH(OPENGL_INCLUDE_DIR GL/gl.h
      /usr/share/doc/NVIDIA_GLX-1.0/include
      /usr/include
      /usr/local/include
      /usr/openwin/share/include
      /opt/graphics/OpenGL/include
      /usr/X11R6/include
    )

    FIND_PATH(OPENGL_xmesa_INCLUDE_DIR GL/xmesa.h
      /usr/share/doc/NVIDIA_GLX-1.0/include
      /usr/include
      /usr/local/include
      /usr/openwin/share/include
      /opt/graphics/OpenGL/include
      /usr/X11R6/include
    )

    FIND_LIBRARY(OPENGL_gl_LIBRARY
      NAMES MesaGL GL
      PATHS /usr/lib
            /usr/local/lib
            /opt/graphics/OpenGL/lib
            /usr/openwin/lib
            /usr/X11R6/lib
    )

    # On Unix OpenGL most certainly always requires X11.
    # Feel free to tighten up these conditions if you don't 
    # think this is always true.

    IF (OPENGL_gl_LIBRARY)
      INCLUDE( ${CMAKE_ROOT}/Modules/FindX11.cmake )
      IF (X11_FOUND)
	SET (OPENGL_LIBRARIES ${X11_LIBRARIES})
      ENDIF (X11_FOUND)
    ENDIF (OPENGL_gl_LIBRARY)

    FIND_LIBRARY(OPENGL_glu_LIBRARY
      NAMES MesaGLU GLU
      PATHS ${OPENGL_gl_LIBRARY}
            /usr/lib
            /usr/local/lib
            /opt/graphics/OpenGL/lib
            /usr/openwin/lib
            /usr/X11R6/lib
    )

  ENDIF (OPENGL_USE_APPLE_X11 OR NOT_APPLE)
ENDIF (WIN32)

SET( OPENGL_FOUND "NO" )
IF(OPENGL_gl_LIBRARY)

    IF(OPENGL_xmesa_INCLUDE_DIR)
      SET( OPENGL_XMESA_FOUND "YES" )
    ELSE(OPENGL_xmesa_INCLUDE_DIR)
      SET( OPENGL_XMESA_FOUND "NO" )
    ENDIF(OPENGL_xmesa_INCLUDE_DIR)

    SET( OPENGL_LIBRARIES  ${OPENGL_gl_LIBRARY} ${OPENGL_LIBRARIES})
    IF(OPENGL_glu_LIBRARY)
      SET( OPENGL_GLU_FOUND "YES" )
      SET( OPENGL_LIBRARIES ${OPENGL_glu_LIBRARY} ${OPENGL_LIBRARIES} )
    ELSE(OPENGL_glu_LIBRARY)
      SET( OPENGL_GLU_FOUND "NO" )
    ENDIF(OPENGL_glu_LIBRARY)

    SET( OPENGL_FOUND "YES" )

    # This deprecated setting is for backward compatibility with CMake1.4

    SET (OPENGL_LIBRARY ${OPENGL_LIBRARIES})

ENDIF(OPENGL_gl_LIBRARY)

# This deprecated setting is for backward compatibility with CMake1.4
SET(OPENGL_INCLUDE_PATH ${OPENGL_INCLUDE_DIR})

MARK_AS_ADVANCED(
  OPENGL_INCLUDE_DIR
  OPENGL_xmesa_INCLUDE_DIR
  OPENGL_glu_LIBRARY
  OPENGL_gl_LIBRARY
)
