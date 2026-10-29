# Requirements

## To build

| Requirement | Why | Source |
|---|---|---|
| Windows 10 or later | The project uses Win32 APIs throughout and targets Windows SDK 10.0. | `Client/Client.vcxproj` (`WindowsTargetPlatformVersion`) |
| Visual Studio 2022 or Build Tools with the **Desktop development with C++** workload (toolset **v143**) | The project is MSVC-only. The SDK relies on MSVC behaviour such as `__try`/`__except` and `__thiscall` vtable calls. | `PlatformToolset` |
| **DirectX SDK (June 2010)** | Provides `d3dx9.h`. The project reads `$(DXSDK_DIR)Include` and `$(DXSDK_DIR)Lib\x86`. The installer sets `DXSDK_DIR`. | `IncludePath`, `LibraryPath`, `CONTRIBUTING.md` |
| Git Bash (optional) | Runs `./build.sh`. | `CONTRIBUTING.md` |
| Go and Inno Setup (optional) | Only needed to build the installer with `package.sh`. | `CONTRIBUTING.md` |

The project builds **32-bit (Win32) only**. Mirror's Edge is a 32-bit game, and the x64 configurations were removed in 2.4.0.

### Language standard

The **Debug** configuration compiles with `/std:c++20` and **Release** with `/std:c++17`. Write addon code that compiles as C++17. Otherwise it builds in Debug but fails in the Release build that `build.sh` produces.
<!-- TODO: verify whether the C++17/C++20 split is intentional -->

## To run

- **Mirror's Edge 1.0**, the PC version (`MirrorsEdge.exe`). The framework finds engine internals by byte-pattern scanning the executable. A different build of the game can make those scans fail; see [Troubleshooting](../troubleshooting.md#startup-message-boxes-title-fatal-or-failure) for what that looks like.
  <!-- TODO: verify which store builds (Steam / EA App / GOG / Origin) are supported -->
- Compatible tools: the framework has explicit handling for **Mirror's Edge Tweaks** (`menl_hooks.dll`) and **Softimer**. The changelog also lists ReShade and DXVK support (2.5.0).

Next: [Building and running](building.md).
