cmake_minimum_required(VERSION 3.21)
project(visualmunge)
include(FetchContent)
set(BUILD_SHARED_LIBS OFF)

FetchContent_Declare(
        imgui-glfw-glad-glm
        GIT_REPOSITORY https://github.com/cmmw/imgui-glfw-glad-glm.git
        GIT_TAG v3.3.4
)
FetchContent_MakeAvailable(imgui-glfw-glad-glm)

set(CMAKE_CXX_STANDARD 17)
find_package(PkgConfig)

include_directories(include)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/..)
set(SOURCE_FILES main.cpp main.cpp)
add_executable(${CMAKE_PROJECT_NAME} ${SOURCE_FILES})

target_link_libraries(
        ${CMAKE_PROJECT_NAME}
        imgui
        glm
)
