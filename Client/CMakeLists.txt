# Client DLL (mmultiplayer.dll): the addon framework, the bundled ImGui and the addons

file(GLOB CLIENT_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/imgui/*.cpp)
file(GLOB_RECURSE CLIENT_ADDON_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/addons/*.cpp)
file(GLOB CLIENT_HEADERS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.h ${CMAKE_CURRENT_SOURCE_DIR}/imgui/*.h)
file(GLOB_RECURSE CLIENT_ADDON_HEADERS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/addons/*.h)

add_library(mmultiplayer_client SHARED
  ${CLIENT_SOURCES} ${CLIENT_ADDON_SOURCES} ${CLIENT_HEADERS} ${CLIENT_ADDON_HEADERS})
set_target_properties(mmultiplayer_client PROPERTIES OUTPUT_NAME mmultiplayer PREFIX "")
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}
  FILES ${CLIENT_SOURCES} ${CLIENT_ADDON_SOURCES} ${CLIENT_HEADERS} ${CLIENT_ADDON_HEADERS})

target_include_directories(mmultiplayer_client PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(mmultiplayer_client PRIVATE CLIENT_EXPORTS _WINDOWS _USRDLL UNICODE _UNICODE)
target_link_libraries(mmultiplayer_client PRIVATE
  mirrorsedge::sdk d3d9 d3dx9 dwmapi gdi32 imm32 psapi shell32 ole32 ws2_32)

if(MSVC)
  target_compile_options(mmultiplayer_client PRIVATE /W3 /sdl /permissive- /MP)

  # d3dx9 is not in the Windows SDK: it comes from the DirectX SDK (June 2010), found through DXSDK_DIR
  set(DXSDK_DIR "$ENV{DXSDK_DIR}" CACHE PATH "DirectX SDK (June 2010) root, for d3dx9")
  if(NOT DXSDK_DIR)
    message(FATAL_ERROR "The client needs d3dx9 from the DirectX SDK (June 2010). Install it or set -DDXSDK_DIR=...")
  endif()
  target_include_directories(mmultiplayer_client SYSTEM PRIVATE "${DXSDK_DIR}/Include")
  target_link_directories(mmultiplayer_client PRIVATE "${DXSDK_DIR}/Lib/x86")
else()
  # The hooks pass function pointers as void*, which MSVC converts implicitly and GCC/Clang reject
  # without -fpermissive (it downgrades them to warnings, silenced here).
  target_compile_options(mmultiplayer_client PRIVATE -fpermissive -Wno-narrowing $<$<CXX_COMPILER_ID:GNU>:-w>)

  # MinGW ships d3dx9 headers and import libraries. Link the runtime statically so the DLL has no
  # libstdc++/libgcc dependencies next to the game executable.
  target_link_options(mmultiplayer_client PRIVATE -static -static-libgcc -static-libstdc++)
endif()
