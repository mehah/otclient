# *****************************************************************************
# Project protobuf
# *****************************************************************************
project(protobuf)

if(APPLE)
	set(CMAKE_CXX_STANDARD 11)
endif(APPLE)

find_package(Protobuf REQUIRED)
find_package(Threads)

if(EXISTS ${PROTOBUF_PROTOC_EXECUTABLE})
	message(STATUS "Found Protobuf Compiler: ${PROTOBUF_PROTOC_EXECUTABLE}")
else()
	message(FATAL_ERROR "Could not find Protobuf Compiler")
endif()

if(PROTOBUF_FOUND)

	include_directories(${PROTOBUF_INCLUDE_DIRS})

	file(GLOB ProtoFiles
		"${CMAKE_CURRENT_SOURCE_DIR}/**/*.proto"
		"${CMAKE_CURRENT_SOURCE_DIR}/*.proto"
	)

	if (MSVC)
		if (BUILD_STATIC_LIBRARY)
			add_library(${PROJECT_NAME} STATIC ${ProtoFiles})
			set_property(TARGET ${PROJECT_NAME} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
		else()
			add_library(${PROJECT_NAME} ${ProtoFiles})
			set_property(TARGET ${PROJECT_NAME} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
		endif()
	else()
		add_library(${PROJECT_NAME} ${ProtoFiles})
	endif()

	target_link_libraries(${PROJECT_NAME}
		PUBLIC
			protobuf::libprotobuf
	)
	target_compile_definitions(${PROJECT_NAME} PUBLIC _DISABLE_VECTOR_ANNOTATION _DISABLE_STRING_ANNOTATION)
	target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

	protobuf_generate(TARGET ${PROJECT_NAME} LANGUAGE cpp)
endif(PROTOBUF_FOUND)
