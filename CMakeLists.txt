cmake_minimum_required(VERSION 3.15)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "Prevented in-tree built. Please create a build directory outside of the fuelbrute source code and call cmake from there")
endif()

if (POLICY CMP0048)
  cmake_policy(SET CMP0048 NEW)
endif()

if (POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

if (POLICY CMP0091)
	cmake_policy(SET CMP0091 NEW)
endif()

project(fuelbrute VERSION 0.1.0.0 LANGUAGES CXX CUDA)

add_executable(cpu
cpu.cpp
)
set_target_properties(cpu PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/data")

add_executable(cuda
cuda.cu
)
set_target_properties(cuda PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/data")

target_compile_options(cuda PRIVATE -rdc=true --default-stream per-thread -G -g)
target_link_libraries(cuda PRIVATE cudadevrt cudart)
set_target_properties(cuda PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
set_target_properties(cuda PROPERTIES CUDA_RESOLVE_DEVICE_SYMBOLS ON)
set_target_properties(cuda PROPERTIES CUDA_ARCHITECTURES 75)

add_executable(dictc
	dictc.cpp
)
set_target_properties(dictc PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/data")

add_executable(hashc
	hashc.cpp
)
set_target_properties(hashc PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/data")

set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT cuda)
