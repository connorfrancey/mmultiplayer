# Launcher.exe: starts Mirror's Edge and injects mmultiplayer.dll

add_executable(mmultiplayer_launcher WIN32 main.cpp stdafx.h resource.h Resource.rc)
set_target_properties(mmultiplayer_launcher PROPERTIES OUTPUT_NAME Launcher)

target_compile_definitions(mmultiplayer_launcher PRIVATE UNICODE _UNICODE)
target_link_libraries(mmultiplayer_launcher PRIVATE shlwapi urlmon psapi)

if(MSVC)
  target_compile_options(mmultiplayer_launcher PRIVATE /W3 /sdl /permissive-)
  # Release builds ask for administrator rights, like the vcxproj
  target_link_options(mmultiplayer_launcher PRIVATE
    $<$<NOT:$<CONFIG:Debug>>:/MANIFESTUAC:level='requireAdministrator'>)
else()
  target_link_options(mmultiplayer_launcher PRIVATE -static -static-libgcc -static-libstdc++)
endif()
