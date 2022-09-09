SET(Libs_DIR ${Libs_DIR} ${CMAKE_SOURCE_DIR}/android/app/libs)
SET(Include_DIR ${Libs_DIR}/include)
SET(Library_DIR ${Libs_DIR}/lib/${CMAKE_ANDROID_ARCH_ABI})
include_directories(${Include_DIR})

SET(LUAJIT_INCLUDE_DIR ${LUAJIT_INCLUDE_DIR} ${Include_DIR}/luajit)
SET(LUAJIT_LIBRARY ${LUAJIT_LIBRARY} ${Library_DIR}/libluajit.a)
