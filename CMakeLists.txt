cmake_minimum_required(VERSION 3.21)
project(mmultiplayer VERSION 2.5.2 LANGUAGES C CXX)

# mmultiplayer: the client DLL (mmultiplayer.dll), the launcher (Launcher.exe) and the game SDK.
#
#   cmake -B build -A Win32                                              (Visual Studio, x86)
#   cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-i686.cmake (MinGW i686)
#   cmake --build build --config Release
#
# The Go server (Server/) is built separately with `go build`.

if(NOT WIN32)
  message(FATAL_ERROR "mmultiplayer targets 32-bit Windows. Use an x86 MSVC or MinGW (i686) toolchain.")
endif()
if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
  message(FATAL_ERROR "Mirror's Edge is 32-bit. Use an x86 toolchain (cmake -A Win32, or cmake/mingw-i686.cmake).")
endif()

option(MMULTIPLAYER_BUILD_CLIENT "Build the client DLL" ON)
option(MMULTIPLAYER_BUILD_LAUNCHER "Build the launcher" ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>") # static CRT, like the vcxproj

# Both outputs land next to each other, like build.sh's Release/ folder
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

# The SDK's Doxygen target is opt-in here (it is on by default only when Client/sdk is configured on its own)
if(NOT DEFINED ME_SDK_BUILD_DOCS)
  set(ME_SDK_BUILD_DOCS OFF CACHE BOOL "Add the me_sdk_docs target (Doxygen)")
endif()
add_subdirectory(Client/sdk)

if(MMULTIPLAYER_BUILD_CLIENT)
  add_subdirectory(Client)
endif()
if(MMULTIPLAYER_BUILD_LAUNCHER)
  add_subdirectory(Launcher)
endif()
