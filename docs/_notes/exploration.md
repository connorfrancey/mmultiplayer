# Exploration findings

Working notes from Phase 1. Sources read: `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `build.sh`, `package.sh`, `.vscode/*`, `Client/Client.vcxproj`, `Client/*.h|*.cpp`, `Client/sdk/ME_Basic.*`, `Client/sdk/ME_Core_*` (sampled), key classes in `ME_Engine_classes.hpp` / `ME_TdGame_classes.hpp`, `Client/addons/*` (init code of every addon, all of `misc.cpp`), `Launcher/main.cpp`.

## What "the SDK" is

There are two layers, and newcomers need both:

1. **Generated game SDK** (`Client/sdk/`, umbrella header `Client/sdk.h`). C++ mirror of Mirror's Edge 1.0's UnrealScript class tree (Unreal Engine 3), all in `namespace Classes`. Every header carries the banner `// Mirror's Edge (1.0) SDK`. It has been hand-edited since generation (e.g. `UObject::IsA` wrapped in `__try`, `UObject::GetObjectName`, Softimer changes in git history).
   - 17 packages, 4 files each: `ME_<Pkg>_structs.hpp`, `_classes.hpp`, `_parameters.hpp`, `_functions.cpp`.
   - Size: ~2,500 classes (Engine 1,147, TdGame 918, UnrealEd 142, Editor 140, Core 44, Tp 44, ...).
   - Basic types in `ME_Basic.hpp`: `TArray<T>`, `TTransArray<T>`, `FString`, `FName`, `FNameEntry`, `TEnumAsByte<E>`, `FScriptInterface`, `TScriptInterface<I>`, `FScriptDelegate`, `GetVFunction`.
   - Every class has `static UClass* StaticClass()` (lazy `FindClass("Class Pkg.Name")`).
   - Every UnrealScript function becomes a C++ member. The wrapper fills a `<Class>_<Fn>_Params` struct and calls `UObject::ProcessEvent` (vtable index 61), with `FunctionFlags |= 0x400` set temporarily. Static UnrealScript functions get a `STATIC_` prefix. Optional params have no C++ defaults, so you must pass every argument.
   - `GObjects` and `GNames` are null until `Engine::Initialize()` pattern-scans for them.

2. **Mod framework** (`Client/*.h`): the API that addons actually program against.
   - `Addon` (`addon.h`): abstract base, `bool Initialize()` + `std::string GetName()`.
   - `Engine` (`engine.h`): object accessors (`GetEngine`, `GetWorld`, `GetPlayerController`, `GetPlayerPawn`, ...), callback registration (`OnTick`, `OnRenderScene`, `OnProcessEvent`, `OnPre/PostLevelLoad`, `OnPre/PostDeath`, `OnActorTick`, `OnBonesTick`, `OnInput`, `OnSuperInput`), utilities (`ExecuteCommand`, `SpawnCharacter`, `Despawn`, `TransformBones`, `IsKeyDown`, `WorldToScreen`, `GetWindow`, `BlockInput`), and `Character` enum + `Characters[]` names.
   - `Menu` (`menu.h`): `AddTab`, `Show`, `Hide`, `OnVisibilityChange`.
   - `Settings` (`settings.h`): JSON key-path get/set persisted to `%APPDATA%\MMultiplayer\mmultiplayer-settings.json` (nlohmann json 3.11.2 in `json.h`).
   - `Debug` (`debug.h`): console toggle + crash handler.
   - Helpers: `util.h` (VK_ letter/digit codes, `Map_*` level-name macros, `Distance`, JSON<->ImVec4/FVector), `string_utils.h` (UTF-8/wide conversion, `GetLowercasedLevelName`).
   - ImGui 1.90.2 with project extensions in `imgui/imgui_mmultiplayer.h` (`BeginWindow`, `BeginRawScene`/`EndRawScene`, `Hotkey`, `Separator(float)`, `HelpMarker`, `DummyVertical`, `SmallArrowButton`). It's wired in via `IMGUI_USER_H_FILENAME` in `imconfig.h`.
   - Internals: `Hook` (trampoline hooks, x86 length disassembler), `Pattern` (signature scan). These are needed to explain behaviour but aren't intended addon API.

**Audience implication:** there is no plugin loader. Addons are compiled into `mmultiplayer.dll` and registered by hand in `main.cpp`'s `addons[]` array, plus `Client.vcxproj`. A "hello world" means adding a class to the project and rebuilding.

## Platforms, toolchain, dependencies

- Target: Windows, **32-bit (Win32) only**; the game is 32-bit (CHANGELOG 2.4.0 removed x64 configs). Game: Mirror's Edge 1.0 (`MirrorsEdge.exe`), UE3, D3D9.
- Toolchain: Visual Studio 2022 toolset `v143`, Windows 10 SDK. Debug builds use `/std:c++20`; Release builds use `/std:c++17`. Release uses static CRT (`/MT`).
- DirectX SDK (June 2010) via `$(DXSDK_DIR)` include/lib paths. `engine.cpp` defines `D3DXMatrixMultiply`/`D3DXVec4Transform` itself "to remove the D3DX dependency", but still includes `d3dx9.h`.
- Build: `./build.sh` (Git Bash, MSBuild on PATH) or the VS Code task. Output goes to `Release/mmultiplayer.dll` and `Release/Launcher.exe`.
- Installer: `VERSION=x.y.z ./package.sh` (Go + Inno Setup).
- Runtime: `Launcher.exe` polls for `MirrorsEdge.exe`, waits until `d3d9.dll` is loaded, then injects `mmultiplayer.dll` **from the launcher's own directory** with `CreateRemoteThread(LoadLibraryW)`.

## Lifecycle (from `main.cpp`)

`DllMain` → `InitThread`: `Engine::InitializeD3D()` → `Settings::Load()` → construct addons → `Engine::Initialize()` (pattern scans + hooks) → `Debug::Initialize()` → `Menu::Initialize()` (adds Engine/World tabs) → `addon->Initialize()` for each addon. An addon init failure shows a message box but doesn't abort. Addons are never destroyed on the success path.

## Behaviour worth documenting

- **Callback dispatch:** callbacks fire in registration order and can't be removed. Registration isn't synchronized, so register during `Initialize()`.
- **`OnProcessEvent`:** the return values of all callbacks are summed. If any callback returns `true`, the **original event is skipped** and the hook returns 0. No addon in the repo uses it. SDK wrapper calls go through `ProcessEvent`, so they also hit this hook.
- **`OnTick`:** callbacks receive `delta`. The `ExecuteCommand` and `SpawnCharacter` queues drain at the start of a tick, before callbacks, and only while `GetPlayerPawn(true)` is non-null.
- **`OnRenderScene`:** runs inside the `EndScene` hook between `ImGui::NewFrame()` and `ImGui::EndFrame()`, so ImGui calls are valid here.
- **Input:** `OnSuperInput` always fires and `OnInput` is suppressed while `BlockInput(true)`. Only `WM_(SYS)KEYDOWN/UP` transitions are reported (no auto-repeat). `IsKeyDown` returns false while input is blocked.
- **Accessors:** results are cached in a function-local static. `update=true` re-resolves the object (O(GObjects) scan for `GetWorld`/`GetEngine`). The world, controller, pawn, time-trial and race accessors return `nullptr` while a level is loading. `GetPlayerController` also returns `nullptr` if `PlayerCamera` is null. `GetPlayerPawn(true)` is called every tick by the framework, so the pawn cache is refreshed each tick.
- **`SpawnCharacter`** is asynchronous. It stores a *reference* to your pointer, writes it on the next tick, and the queue is cleared on level load. Pre-level-load hooks in the addons null their actor pointers, and post-load hooks respawn.
- **`Settings::GetSetting`** writes the default into the tree **and saves the file on every call**. `SetSetting` also saves on every call.
- **Menu:** the toggle key is `Settings["Menu"]["ShowKeybind"]` (default `VK_INSERT`). Escape also closes the menu. Built-in tabs "Engine" and "World" come first, and addon tabs follow in registration order.
- **Crash handler:** on an unhandled exception it destroys the game window, opens a console, prints registers and a stack scan, and waits for a key. It's skipped when a debugger is attached.
- **Compatibility:** `menl_hooks.dll` (Mirror's Edge tweaks) loading triggers temporary removal and re-application of the level-load/death hooks. Softimer's `SofTimerPlayerController` is accepted as a player controller.

## Undocumented / inconsistent / suspicious

Bugs and misleading names are detailed in `code-issues.md`. In short:
- Debug uses C++20 and Release uses C++17, so code can compile in Debug and fail in Release.
- `FVectorToJson` / `JsonToFVector` use keys `R`,`G`,`B` for X,Y,Z.
- `FRotator` fields are `unsigned int`, while UE3 uses signed `int`.
- The PostDeath hook failure message says "Failed to hook PreDeath".
- `Misc` `OnRender` condition `!pawn && !controller || ...` has a precedence bug.
- `Debug::IsConsoleOpened` is `static` in a header, so each translation unit gets its own copy.
- `UnTrampolineHook` assigns `original = nullptr` to its by-value parameter, which has no effect.
- `commands.Queue.size()` / `spawns.Queue.size()` are read without the lock.
- `GetTimeTrialGame` / `GetLevelRace` dereference `world->Game` without a null check.
- The vcxproj lists `SDK\...` but the directory is `sdk/`. That's harmless on Windows but breaks case-sensitive tooling.
- `build.sh` passes `Platform=x86` while the vcxproj only defines `Win32`.
- The menu title hard-codes `"MMultiplayer 2.5.2"`; the version also lives in CHANGELOG.
- There are no tests, no existing docs tooling (no Doxygen/MkDocs/etc.), and no API comments beyond a few in `engine.h` and `string_utils.h`.

## How examples will be verified

The project is MSVC-only and this machine is Linux. MinGW `i686-w64-mingw32-g++ -std=c++17 -fms-extensions -include cstdint -fsyntax-only` parses `sdk.h` + `engine.h` + `menu.h` + `settings.h` + ImGui in **strict mode**, after two workarounds that live only in a scratch copy:
- the template-parameter shadow in `ME_Basic.hpp` is renamed (MSVC accepts the original; GCC rejects it);
- case shims are added for `WinUser.h`, `Windows.h`, `Psapi.h` and `TlHelp32.h`.

`-fpermissive` was tried first and dropped, because it silently accepted a callback with the wrong signature. Doc snippets get full type-checking against the real declarations. They are **not** linked, built with MSVC, or run in-game.

## Open questions

1. Is the user's "SDK" the generated `Client/sdk/` only, or the whole addon framework? Assumed: both, framed for addon authors (see outline).
2. Which generator produced `Client/sdk/`, and is regenerating it supported? If so, how are hand edits preserved?
3. Which thread runs `EndScene` (`OnRenderScene`) relative to the game tick (`OnTick`)? Several addons read and write game objects from both. This decides the thread-safety guidance.
4. Does MSBuild accept `Platform=x86` for `Client.vcxproj` (it only declares `Win32`)? `build.sh` relies on it.
5. Which game builds are supported (Steam / Origin / EA App / GOG)? The pattern scans are exe-specific.
6. Is the C++17 (Release) vs C++20 (Debug) split intentional? Which standard should addon code target?
7. Is `Engine::OnProcessEvent`'s "return true to swallow the event" contract intended public API?
8. Is there a supported way to ship a third-party addon without forking the repo?
