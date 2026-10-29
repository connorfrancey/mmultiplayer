# Building and running

## Repository layout

```
Client/          mmultiplayer.dll: framework, addons, generated SDK
  addons/        built-in addons (client, trainer, dolly, misc, chaos/)
  imgui/         Dear ImGui 1.90.2 + project extensions
  sdk/           generated Mirror's Edge SDK (ME_<Package>_*.hpp/.cpp)
  main.cpp       DLL entry point; the list of addons lives here
Launcher/        Launcher.exe: injects mmultiplayer.dll into the game
Server/          multiplayer server (Go); not needed for addon work
resources/       installer sources
cmake/           MinGW i686 toolchain file
CMakeLists.txt   CMake build for Client, Launcher and the SDK
build.sh         builds Client and Launcher into Release/ (MSBuild)
package.sh       builds the installer
```

## Get the source

```bash
git clone https://github.com/softsoundd/mmultiplayer.git
cd mmultiplayer
```

## Build

Pick one of these options. Each one produces `Release/mmultiplayer.dll` and `Release/Launcher.exe`.

**Option A: `build.sh` (Git Bash).** You need `MSBuild.exe` on your `PATH`.

```bash
./build.sh
```

This runs:

```bash
MSBuild.exe Client/Client.vcxproj -property:Configuration=Release -property:Platform=x86 -property:OutDir=../Release/ -t:Build
MSBuild.exe Launcher/Launcher.vcxproj -property:Configuration=Release -property:Platform=x86 -property:OutDir=../Release/ -t:Build
```

<!-- TODO: verify — Client.vcxproj only declares the Win32 platform; confirm MSBuild accepts Platform=x86 here -->

**Option B: VS Code.** Run the **Client Build** and **Launcher Build** tasks from `.vscode/tasks.json`. The tasks put MSBuild from `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin` on the `PATH`. That path is for Visual Studio **18** Build Tools, while the project asks for toolset **v143** (the Visual Studio 2022 toolset). Make sure v143 is installed in whichever Visual Studio you use, and edit the path if your MSBuild lives elsewhere. <!-- TODO: verify which Visual Studio version maintainers build with -->

**Option C: Visual Studio.** Open `Client/Client.sln`, choose **Release | x86** or **Debug | x86**, and build. The solution's `x86` maps to the project's `Win32` configuration. No `OutDir` is set in the project, so the IDE uses Visual Studio's default (`$(SolutionDir)$(Configuration)\`, for example `Client\Release\`). Copy `mmultiplayer.dll` next to `Launcher.exe` yourself.

**Option D: CMake.** The top-level `CMakeLists.txt` builds `mmultiplayer.dll` and `Launcher.exe` into `build/bin/`, with MSVC or MinGW i686 (see [Building with CMake](#building-with-cmake)).

The generated SDK makes the first build slow: `ME_TdGame_functions.cpp` and `ME_Engine_functions.cpp` are several megabytes each.

## Building with CMake

The repository root is a CMake project. It builds three targets:

| Target | Output | Source |
|---|---|---|
| `mmultiplayer_client` | `build/bin/mmultiplayer.dll` | `Client/CMakeLists.txt` |
| `mmultiplayer_launcher` | `build/bin/Launcher.exe` | `Launcher/CMakeLists.txt` |
| `me_sdk` | static library, linked into the client | `Client/sdk/CMakeLists.txt` |

```bash
# MSVC (Developer Command Prompt). The client needs d3dx9 from the DirectX SDK (June 2010):
# it is found through the DXSDK_DIR environment variable the installer sets, or -DDXSDK_DIR=...
cmake -B build -A Win32
cmake --build build --config Release

# MinGW i686, natively (MSYS2) or cross-compiling from Linux. MinGW ships d3dx9, so no DirectX SDK.
cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-i686.cmake -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

- The client sources are globbed (`Client/*.cpp`, `Client/imgui/*.cpp`, `Client/addons/**/*.cpp`), so a new addon `.cpp` is picked up when you re-run the build. You don't need to edit `CMakeLists.txt`.
- Both targets compile as C++17 and link the C/C++ runtime statically, like the Release vcxproj configuration.
- MinGW builds of the client pass `-fpermissive`: the hook code converts function pointers to `void*` implicitly, which only MSVC accepts. The MinGW Launcher doesn't embed the `requireAdministrator` manifest that MSVC Release builds get.
- `-DMMULTIPLAYER_BUILD_CLIENT=OFF` or `-DMMULTIPLAYER_BUILD_LAUNCHER=OFF` skip a target. `-DME_SDK_BUILD_DOCS=ON` adds the docs target (off by default from the root).

The `.sln`/`.vcxproj` files are still maintained, and `build.sh` still uses them.

## Building the SDK with CMake

`Client/sdk/` is also a standalone CMake project. It builds the generated SDK as the static library `me_sdk` (alias `mirrorsedge::sdk`) and has an optional Doxygen docs target.

**Use it from another project**, such as an injected mod of your own:

```cmake
add_subdirectory(path/to/mmultiplayer/Client/sdk ${CMAKE_BINARY_DIR}/me_sdk)
target_link_libraries(my_mod PRIVATE mirrorsedge::sdk)
```

<!-- verify: skip (needs the me_sdk include path; exercised by building memenu against it) -->
```cpp
#include <ME_SDK.hpp>   // everything in namespace Classes
```

- **Compilers:** MSVC (x86) or MinGW i686 (GCC or Clang). 32-bit only; configure fails otherwise.
- **Include path:** only the `sdk/` folder is exposed, as SYSTEM includes, so `/W4` or `-Wall -Wextra` in your project produce no warnings from generated code.
- **Build time:** a full build of the library takes about 2 minutes. `ME_TdGame_functions.cpp` and `ME_Engine_functions.cpp` are large; MinGW builds pass `-Wa,-mbig-obj` and MSVC builds `/bigobj`.

**Build it standalone:**

```bash
# MSVC (Developer Command Prompt)
cmake -S Client/sdk -B build/sdk -A Win32
cmake --build build/sdk --config Release

# MinGW, e.g. cross-compiling from Linux
cmake -S Client/sdk -B build/sdk -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-i686.cmake
cmake --build build/sdk
```

### Generating the docs (Doxygen)

When `Client/sdk` is the top-level project, it adds a `me_sdk_docs` target that renders `docs/` with Doxygen. That covers every page here, including Mermaid diagrams (drawn in the browser by mermaid.js from a CDN), plus the framework headers. Docs work on any OS; turn the library off if you aren't on Windows:

```bash
cmake -S Client/sdk -B build/docs -G Ninja -DME_SDK_BUILD_LIBRARY=OFF
cmake --build build/docs --target me_sdk_docs
# open build/docs/docs/html/index.html
```

| Option | Default | Effect |
|---|---|---|
| `ME_SDK_BUILD_LIBRARY` | `ON` | Build `me_sdk` (requires a 32-bit Windows toolchain) |
| `ME_SDK_BUILD_DOCS` | `ON` when top-level | Add the `me_sdk_docs` target |
| `ME_SDK_DOCS_CLASS_REFERENCE` | `OFF` | Also document all ~2,500 generated classes. Takes about 2 minutes and about **1.2 GB** of HTML, because Doxygen repeats inherited members on every class page. The guides alone are about 3 MB. |
| `ME_SDK_DOCS_DIR` | `<repo>/docs` | Markdown source folder |

## Run

1. Put `mmultiplayer.dll` in the **same directory as `Launcher.exe`**. The launcher loads the DLL from its own folder. `build.sh` already puts both in `Release/`. If you installed the mod with the installer, it lives in `C:\Program Files\Mirror's Edge Multiplayer` (since 2.1.1). You can replace the DLL there instead, but keep a backup.
2. Start `Launcher.exe`, before or after the game.
3. Start Mirror's Edge. Until it does, the launcher shows "Waiting for Mirror's Edge to start. Click OK to stop." It polls every 50 ms for `MirrorsEdge.exe`. Once the game has loaded `d3d9.dll`, the launcher injects `mmultiplayer.dll` and exits. If the DLL is already loaded, the launcher exits without doing anything.
4. The menu opens at startup by default. Press **Insert** to toggle it and **Escape** to close it. The menu key can be rebound in the **Engine** tab.

The launcher opens the game process with `PROCESS_ALL_ACCESS`. If that fails, it shows "Failed to open a handle to the process". Try running the launcher as administrator.
<!-- TODO: verify whether administrator rights are normally required -->

## Iterating

The DLL can't be unloaded or reloaded in a running game; nothing tears down the hooks. To test a change:

1. Quit the game.
2. Rebuild.
3. Run the launcher and the game again.

Next: [Hello world](hello-world.md).
