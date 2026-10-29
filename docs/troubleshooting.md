# Troubleshooting

Every message below is quoted from the source.

## Building

### `Cannot open include file: 'd3dx9.h'` / unresolved `d3d9.lib`

The DirectX SDK (June 2010) isn't installed, or `DXSDK_DIR` isn't set. The project reads `$(DXSDK_DIR)Include` and `$(DXSDK_DIR)Lib\x86`. Install the SDK, then restart Visual Studio or your shell so it sees the variable. See [Requirements](getting-started/requirements.md).

### Builds in Debug, fails in Release (or the reverse)

Debug compiles as **C++20** and Release as **C++17**. A C++20 feature (designated initializers, `std::span`, `<=>`, ...) compiles in Debug only. Stick to C++17.

### `cannot convert ... lambda ... to 'TickCallback'` (or another callback type)

Your lambda captures something, or its parameters don't match the typedef exactly. Callbacks are plain function pointers; see [Engine callbacks](api-reference/engine-callbacks.md#typedefs). Move captured state into file-scope `static` variables.

### `'json' does not name a type` / `'ImVec4' undeclared` from `util.h`

`util.h` depends on headers it doesn't include. Include `engine.h`, `imgui/imgui.h` and `settings.h` before it. See [Helpers](api-reference/helpers.md#utilh).

### `VK_F8` (or another `VK_*`) undeclared

`settings.h` and `addon.h` don't pull in `<Windows.h>`. Include `engine.h` first.

### Linker errors for your addon's functions

Your `.cpp` isn't in `Client/Client.vcxproj`. Add a `<ClCompile Include="addons\yourfile.cpp" />` entry. See [Hello world, step 2](getting-started/hello-world.md#2-add-the-files-to-the-project).

## Launching

| Message (title "Failure") | Cause / fix |
|---|---|
| `Failed to adjust privileges to debug` | The launcher couldn't enable debug privilege for its process token. Run it as administrator. |
| `Failed to open a handle to the process` | `OpenProcess(PROCESS_ALL_ACCESS)` on `MirrorsEdge.exe` failed. Run the launcher as administrator, especially if the game is elevated. |
| `Failed to get dll path` | The launcher couldn't resolve its own path. |
| `Failed to allocate virtual memory` / `Failed to write process memory` / `Failed to create remote thread` | Injection was blocked, often by antivirus. On Windows, check `Get-MpThreatDetection` in PowerShell (see `CONTRIBUTING.md`). |

The launcher shows "Waiting for Mirror's Edge to start. Click OK to stop." until the game has loaded `d3d9.dll`. If the game never gets that far, the launcher keeps waiting.

**My new code isn't running.** The launcher loads `mmultiplayer.dll` **from its own directory**, so make sure you copied the new build there. If the DLL is already loaded, for example from an earlier launch, the launcher exits without injecting again, so restart the game.

**Installer problems.** Logs are in `%localappdata%\Temp` (`Setup Log <date> #NNN.txt`, `mirrors-edge-multiplayer-installer-helper-*.log`).

## Startup message boxes (title "Fatal" or "Failure")

| Message | Meaning |
|---|---|
| `Failed to initialize D3D hooks` | Couldn't hook `LoadLibraryA/W/ExW`. Nothing else loads. |
| `Failed to find GNames` / `GObjects` / `ProcessEvent` / `LevelLoad` / `PreDeath (1)` / `PreDeath (2)` / `PostDeath` / `ActorTick` / `BonesTick` / `ProjectionTick` / `Tick` | A byte-pattern scan failed. The game executable isn't the build these patterns were written for (a different version or store build, or a patched exe). Then `Failed to initialize engine` appears and no addons load. |
| `Failed to hook PeekMessageW` / `Failed to hook <X>` | The function was found but couldn't be patched. Another tool may have hooked it in an incompatible way. |
| `Failed to hook PreDeath` (after PreDeath already succeeded) | Despite the text, this is the **PostDeath** hook failing. See [code issues](_notes/code-issues.md). |
| `Failed to initialize menu` | `Menu::Initialize()` returned false. It currently always returns true. |
| `Failed to initialize "<name>"` | An addon's `Initialize()` returned `false`. The others still load. |

## At runtime

### The menu never appears

ImGui initializes on the first `EndScene` the framework hooks. If you use a D3D9 wrapper (ReShade, DXVK, ...), the framework tries the `Direct3DCreate9` → `CreateDevice` path first. If that fails, it runs a fallback probe every second for two minutes, starting 2 seconds in. Wait, then press **Insert**. If you rebound the key, check `{"Menu","ShowKeybind"}` in the settings file.

### `GetPlayerPawn()` / `GetWorld()` returns `nullptr`

That's expected in the main menu, during loads, and briefly after a level starts. See [Object accessors](concepts/object-accessors.md#nullptr-cases). Check every time.

### My hotkey bound to a mouse button never fires

The framework only tracks keyboard messages. See [Handling input](guides/handling-input.md#gotchas).

### My hotkey stops working while the menu is open

`OnInput` and `IsKeyDown` are disabled while input is blocked. Use `OnSuperInput` for keys that must work then.

### `SpawnCharacter` never sets my pointer

- No player pawn existed during the ticks after the call (for example, in the main menu).
- A level load cleared the queue.
- The pointer was already non-null.
- The variable went out of scope. It must outlive the request.

See [Spawning characters](guides/spawning-characters.md).

### `ExecuteCommand` does nothing

The queue only drains while a player pawn exists. The command might also not be valid for this game.

### My settings were wiped

`Settings::Load()` resets to `{}` if the file is missing **or isn't valid JSON**. A hand-edit with a syntax error discards the whole file. Also, settings files from before 2.2.0 aren't compatible; see [Changelog](changelog.md).

### Frame rate drops after adding my addon

The usual causes:

- `Settings::GetSetting`/`SetSetting` called every frame. Each call writes the file.
- `FindObject`/`FindClass`/`FName("...")` called every frame. Each is a linear scan; cache the result.
- `GetEngine(true)`/`GetWorld(true)` every frame (a full `GObjects` scan).
- Heavy work in `OnProcessEvent` or `OnActorTick`.

### The game closes and a console shows "An unhandled exception occured at:"

That's the framework's [crash handler](api-reference/debug.md#crash-handler). The first line names the faulting module and offset. If it's `mmultiplayer.dll+0x...`, the crash is in mod code. Look up the offset in the `.pdb` from your build; Release also generates debug info. To catch it live, start the game, **attach Visual Studio's debugger** to `MirrorsEdge.exe`, and reproduce: with a debugger attached, the handler steps aside.

Common causes in addon code:

- dereferencing a `nullptr` from an accessor;
- an actor pointer kept across a level load;
- an SDK call made from a constructor (before `Engine::Initialize()`);
- `FString::ToString()` on an invalid string;
- an out-of-range `TArray` index.
