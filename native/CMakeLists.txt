cmake_minimum_required(VERSION 3.25)
project(jackdaw VERSION 0.1.0 LANGUAGES C CXX)

option(JACKDAW_BUILD_TESTS "Build the C++ unit tests" OFF)
set(JACKDAW_CPU_REQUIREMENTS "" CACHE STRING "CPU features the build needs, reported to callers")
set(JACKDAW_SANITIZE "" CACHE STRING "Comma separated -fsanitize list, for example address,undefined")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

if(JACKDAW_SANITIZE)
  add_compile_options(-fsanitize=${JACKDAW_SANITIZE} -fno-omit-frame-pointer)
  add_link_options(-fsanitize=${JACKDAW_SANITIZE})
endif()

include(FetchContent)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_APP OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_UI OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_HTML OFF CACHE BOOL "" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_BACKEND_DL OFF CACHE BOOL "" FORCE)
if(APPLE)
  set(GGML_METAL_EMBED_LIBRARY ON CACHE BOOL "" FORCE)
endif()

FetchContent_Declare(
  llama_cpp
  URL https://github.com/ggml-org/llama.cpp/archive/refs/tags/v0.6.0.tar.gz
  URL_HASH SHA256=09b36dba235fcac180efff18514da7038e65d8e5b9e4aefa59238468abfdec12
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
  SYSTEM)
FetchContent_MakeAvailable(llama_cpp)
if(MSVC)
  target_compile_options(llama PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:/FIalgorithm>")
endif()
if(NOT MSVC)
  target_compile_options(llama PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:SHELL:-include algorithm>")
endif()

set(JACKDAW_SOURCES
  src/api.cpp
  src/api_retrieval.cpp
  src/embedder.cpp
  src/error.cpp
  src/generator.cpp
  src/live_objects.cpp
  src/model.cpp
  src/piece_ring.cpp
  src/sampler.cpp
  src/session.cpp
  src/text.cpp
  src/vector_file.cpp
  src/vector_index.cpp)

set(JACKDAW_WARNINGS -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Werror)
if(MSVC)
  set(JACKDAW_WARNINGS /W4 /permissive- /utf-8)
endif()

add_library(jackdaw_core STATIC ${JACKDAW_SOURCES})
target_compile_features(jackdaw_core PUBLIC cxx_std_20)
target_compile_definitions(jackdaw_core PUBLIC JACKDAW_CPU_REQUIREMENTS="${JACKDAW_CPU_REQUIREMENTS}")
target_include_directories(jackdaw_core PUBLIC include PRIVATE src)
target_link_libraries(jackdaw_core PUBLIC llama)
target_compile_options(jackdaw_core PRIVATE ${JACKDAW_WARNINGS})

add_library(jackdaw SHARED ${JACKDAW_SOURCES})
target_compile_features(jackdaw PRIVATE cxx_std_20)
target_compile_definitions(jackdaw PRIVATE JACKDAW_CPU_REQUIREMENTS="${JACKDAW_CPU_REQUIREMENTS}")
target_include_directories(jackdaw PUBLIC include PRIVATE src)
target_link_libraries(jackdaw PRIVATE llama)
target_compile_options(jackdaw PRIVATE ${JACKDAW_WARNINGS})
set_target_properties(jackdaw PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
  RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}
  LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
  LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR})

option(JACKDAW_STRIP "Strip local symbols from the shared library" OFF)
if(JACKDAW_STRIP AND APPLE)
  target_link_options(jackdaw PRIVATE "LINKER:-x")
elseif(JACKDAW_STRIP AND UNIX)
  target_link_options(jackdaw PRIVATE "LINKER:-s")
endif()

if(APPLE)
  target_link_options(jackdaw PRIVATE
    "LINKER:-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/cmake/exports.txt"
    "LINKER:-dead_strip")
elseif(UNIX)
  target_link_options(jackdaw PRIVATE
    "LINKER:--version-script=${CMAKE_CURRENT_SOURCE_DIR}/cmake/exports.map"
    "LINKER:--gc-sections"
    "LINKER:-z,max-page-size=16384")
endif()

if(JACKDAW_BUILD_TESTS)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.18.0.tar.gz
    URL_HASH SHA256=6e3191c1455468b3fc35a417fb565c1c5071aee1b7e7f85e30cf48a98d37d8b5
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE)
  set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(googletest)
  enable_testing()
  add_executable(jackdaw_tests
    tests/api_test.cpp
    tests/embedder_test.cpp
    tests/live_objects_test.cpp
    tests/model_test.cpp
    tests/piece_ring_test.cpp
    tests/vector_index_test.cpp)
  target_include_directories(jackdaw_tests PRIVATE src)
  target_link_libraries(jackdaw_tests PRIVATE jackdaw_core GTest::gtest_main)
  include(GoogleTest)
  gtest_discover_tests(jackdaw_tests DISCOVERY_MODE PRE_TEST)
endif()
