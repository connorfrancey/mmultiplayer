cmake_minimum_required(VERSION 3.21)
project(mirrorsedge_sdk VERSION 2.5.2 LANGUAGES CXX)

# Generated Mirror's Edge (1.0) SDK as a standalone static library, plus optional Doxygen docs.
#
#   add_subdirectory(path/to/Client/sdk)
#   target_link_libraries(my_mod PRIVATE mirrorsedge::sdk)
#   #include <ME_SDK.hpp>

option(ME_SDK_BUILD_LIBRARY "Build the me_sdk static library (Win32 only)" ON)
option(ME_SDK_BUILD_DOCS "Add the me_sdk_docs target (Doxygen)" ${PROJECT_IS_TOP_LEVEL})

# -------------------------------------------------------------------------------------------------
# Library

if(ME_SDK_BUILD_LIBRARY)
  if(NOT WIN32)
    message(FATAL_ERROR "me_sdk targets 32-bit Windows. Use an x86 MSVC or MinGW (i686) toolchain, "
      "or configure with -DME_SDK_BUILD_LIBRARY=OFF to build only the docs.")
  endif()
  if(NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
    message(FATAL_ERROR "Mirror's Edge is 32-bit. Use an x86 toolchain (cmake -A Win32, or a MinGW i686 toolchain file).")
  endif()

  file(GLOB ME_SDK_SOURCES CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/ME_*.cpp)
  file(GLOB ME_SDK_HEADERS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/ME_*.hpp)

  add_library(me_sdk STATIC ${ME_SDK_SOURCES} ${ME_SDK_HEADERS})
  add_library(mirrorsedge::sdk ALIAS me_sdk)

  target_compile_features(me_sdk PUBLIC cxx_std_17)

  # SYSTEM: consumers building with /W4 or -Wall -Wextra don't get warnings from generated code
  target_include_directories(me_sdk SYSTEM INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

  if(MSVC)
    target_compile_options(me_sdk PRIVATE /w /bigobj /MP)
  else()
    # ME_TdGame_functions.cpp and ME_Engine_functions.cpp exceed the default COFF section limit
    target_compile_options(me_sdk PRIVATE -w $<$<BOOL:${MINGW}>:-Wa,-mbig-obj>)
  endif()

  source_group("Headers" FILES ${ME_SDK_HEADERS})
  source_group("Sources" FILES ${ME_SDK_SOURCES})
endif()

# -------------------------------------------------------------------------------------------------
# Documentation

if(ME_SDK_BUILD_DOCS)
  find_package(Doxygen REQUIRED)

  get_filename_component(ME_SDK_REPO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
  set(ME_SDK_DOCS_DIR "${ME_SDK_REPO_DIR}/docs" CACHE PATH "Markdown docs to feed to Doxygen")
  # Off by default: Doxygen repeats every inherited member on each of ~2,500 class pages, so the
  # full reference takes about 2 minutes and ~1.2 GB (the guides and API pages alone are ~3 MB).
  option(ME_SDK_DOCS_CLASS_REFERENCE "Include every generated SDK class in the docs (~1.2 GB)" OFF)

  if(NOT EXISTS "${ME_SDK_DOCS_DIR}/index.md")
    message(FATAL_ERROR "ME_SDK_DOCS_DIR (${ME_SDK_DOCS_DIR}) has no index.md. "
      "Point it at the repo's docs/ folder or configure with -DME_SDK_BUILD_DOCS=OFF.")
  endif()

  # Markdown is pre-processed into the build tree: Doxygen has no Mermaid support, so the
  # script rewrites ```mermaid blocks into client-side mermaid.js diagrams.
  set(ME_SDK_DOCS_MD_DIR "${CMAKE_CURRENT_BINARY_DIR}/docs-md")
  add_custom_target(me_sdk_docs_markdown
    COMMAND ${CMAKE_COMMAND}
      -DSRC_DIR=${ME_SDK_DOCS_DIR}
      -DDST_DIR=${ME_SDK_DOCS_MD_DIR}/docs
      -DCHANGELOG=${ME_SDK_REPO_DIR}/CHANGELOG.md
      -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/PrepareDocsMarkdown.cmake
    COMMENT "Preparing Markdown docs for Doxygen"
    VERBATIM)

  set(ME_SDK_DOCS_INPUTS "${ME_SDK_DOCS_MD_DIR}")

  # Framework headers documented by the API reference, when building inside the mmultiplayer repo
  foreach(header addon.h engine.h menu.h settings.h debug.h util.h string_utils.h imgui/imgui_mmultiplayer.h)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../${header}")
      list(APPEND ME_SDK_DOCS_INPUTS "${CMAKE_CURRENT_SOURCE_DIR}/../${header}")
    endif()
  endforeach()

  if(ME_SDK_DOCS_CLASS_REFERENCE)
    file(GLOB ME_SDK_DOCS_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/ME_*.hpp)
    list(APPEND ME_SDK_DOCS_INPUTS ${ME_SDK_DOCS_HEADERS})
  else()
    list(APPEND ME_SDK_DOCS_INPUTS "${CMAKE_CURRENT_SOURCE_DIR}/ME_SDK.hpp")
  endif()

  set(DOXYGEN_PROJECT_NAME "Mirror's Edge SDK")
  set(DOXYGEN_PROJECT_NUMBER ${PROJECT_VERSION})
  set(DOXYGEN_PROJECT_BRIEF "Addon framework and generated game SDK for the mmultiplayer client")
  set(DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/docs")
  set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${ME_SDK_DOCS_MD_DIR}/docs/index.md")
  set(DOXYGEN_FILE_PATTERNS *.md *.h *.hpp)
  set(DOXYGEN_RECURSIVE YES)
  set(DOXYGEN_MARKDOWN_ID_STYLE GITHUB)    # heading anchors match GitHub, so page.md#anchor links work
  set(DOXYGEN_TOC_INCLUDE_HEADINGS 3)
  set(DOXYGEN_STRIP_FROM_PATH "${ME_SDK_REPO_DIR}" "${ME_SDK_DOCS_MD_DIR}")
  set(DOXYGEN_EXTRACT_ALL YES)             # generated code carries no doc comments
  set(DOXYGEN_EXTRACT_STATIC YES)          # util.h / string_utils.h helpers are file-static
  set(DOXYGEN_WARN_IF_UNDOCUMENTED NO)
  set(DOXYGEN_GENERATE_TREEVIEW YES)
  set(DOXYGEN_FULL_SIDEBAR NO)
  set(DOXYGEN_HAVE_DOT NO)                 # dot graphs for thousands of classes take far too long
  set(DOXYGEN_SOURCE_BROWSER NO)
  set(DOXYGEN_VERBATIM_HEADERS YES)        # header listings show the field offset comments
  set(DOXYGEN_SEARCHENGINE YES)
  set(DOXYGEN_QUIET YES)

  doxygen_add_docs(me_sdk_docs ${ME_SDK_DOCS_INPUTS}
    COMMENT "Generating Mirror's Edge SDK documentation with Doxygen")
  add_dependencies(me_sdk_docs me_sdk_docs_markdown)
endif()
