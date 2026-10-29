# Code issues found while documenting

No source was modified. Each item is something the docs had to work around or warn about. Ordered by likely impact.

## Likely bugs

1. **Callback registration races live hooks.** `Client/main.cpp`: `Engine::Initialize()` installs the hooks, then `Menu::Initialize()` and every `addon->Initialize()` `push_back` into the callback vectors in `engine.cpp` (`tick.Callbacks`, `renderScene.Callbacks`, ...) from `InitThread`. Meanwhile the game thread iterates them in `TickHook`, `EndSceneHook` and the rest. A reallocation during iteration is undefined behaviour and a plausible intermittent startup crash. *Fix:* register before hooking, or guard the vectors.
2. **Mouse bindings never fire.** `ImGui::Hotkey` (`imgui/imgui_mmultiplayer.cpp`) captures `VK_LBUTTON`..`VK_XBUTTON2`, but `Engine::IsKeyDown` and `OnInput` only see `WM_(SYS)KEY*` messages (`engine.cpp`, `HandleMessage`). Trainer and Dolly bindings set to a mouse button silently do nothing.
3. **`VK_TO_KEY[0x4C]` is empty** (`imgui_mmultiplayer.cpp`): an **L** binding displays as blank.
4. **Wrong failure message.** `engine.cpp`, PostDeath hook: `MessageBoxA(..., "Failed to hook PreDeath", ...)` should say PostDeath.
5. **Operator precedence.** `addons/misc.cpp`, `OnRender`: `if (!pawn && !controller || LevelName == Map_MainMenu)` continues when only one of them is null, then uses neither. The intent was probably `!pawn || !controller || ...`.
6. **Unlocked reads.** `engine.cpp`, `TickHook`: `commands.Queue.size()` and `spawns.Queue.size()` are read before the mutex is taken, while `ExecuteCommand`/`SpawnCharacter` may push from another thread.
7. **Unchecked `world->Game`.** `Engine::GetTimeTrialGame` / `GetLevelRace` call `world->Game->GetName()` without a null check.
8. **`UnTrampolineHook` no-op assignment.** `hook.cpp`: `original = nullptr;` assigns the by-value parameter, so callers' pointers aren't cleared. It also re-measures instruction lengths from `original`, which is wrong for hooks created through the `0xE9` (already-jumped) path, where `original` is a 5-byte relative jump. Copying that back verbatim breaks the relative offset. This is relevant to the `menl_hooks.dll` unhook/rehook path.
9. **String conversions ignore the view length.** `string_utils.h`: `ConvertUtf8ToWideString(std::string_view)` and `ConvertWideStringToString(std::wstring_view)` pass `-1` (null-terminated) to the Win32 conversion functions, so a non-terminated view reads past its end.
10. **`FString::ToString()` on an invalid string.** `ME_Basic.hpp`: it calls `wcslen(nullptr)` when `Data` is null.

## Performance

11. **`Settings::GetSetting` writes the file.** `settings.cpp`: every `GetSetting` call ends in `Settings::Save()`, even when nothing changed. At startup that's dozens of full-file writes.
12. **A full `GObjects` scan every tick.** `TickHook` calls `GetPlayerPawn(true)`, which cascades to `GetWorld(true)`, a linear scan of all objects (up to the first match), every tick.

## Misleading names / inconsistencies

13. `FVectorToJson` / `JsonToFVector` (`util.h`) store X/Y/Z under `"R"`, `"G"`, `"B"`.
14. `Debug::IsConsoleOpened` is `static` in `debug.h`, so each translation unit gets its own copy.
15. `util.h` isn't self-contained: it needs `json`, `ImVec4` and `Classes::FVector` from headers it doesn't include.
16. The `InputCallback` `msg` parameter is a mutable reference that aliases the real message. Writes change what the game receives. It's undocumented in `engine.h`, and it's unclear whether that's intended.
17. Swapped ImGui IDs in `menu.cpp`: `"Min Smoothed Framerate##engine-max-smoothed"` and `"Max Smoothed Framerate##engine-min-smoothed"`.
18. `FRotator` fields are `unsigned int` in `ME_Core_structs.hpp`; UE3 declares them `int`. Negative pitch and similar values wrap.
19. Debug builds use `stdcpp20` and Release `stdcpp17` (`Client.vcxproj`).
20. `Client.vcxproj` references `SDK\...` while the directory is `sdk/`. That's harmless on Windows but breaks case-sensitive tools.
21. `build.sh` passes `Platform=x86` to a `.vcxproj` that only defines `Win32` (the `.sln` maps x86 → Win32; the project file itself doesn't).
22. The version is hard-coded in the menu title (`menu.cpp`: `"MMultiplayer 2.5.2"`) separately from `CHANGELOG.md`.
23. `imgui_mmultiplayer.cpp` and some `addons/chaos/effects/*.cpp` files start with `#pragma once`, which does nothing in a `.cpp`.
24. ~~`ME_Basic.hpp`: `TArray`'s `template <class T> friend struct TTransArray;` shadows the outer `T`.~~ Fixed on branch `sdk-cmake` (renamed to `U`).
25. The `Misc` addon's UI and settings keys say "Consequtive" (misspelt). That's user-visible; renaming the setting key would break existing settings.

## SDK portability and layout (found while adding the CMake project)

Fixed on branch `sdk-cmake`:

26. **Packing applied only under MSVC.** Every generated header wrapped its `#pragma pack(push, ...)` / `pop` in `#ifdef _MSC_VER`. Under MinGW the packing silently disappeared. `ME_Engine_classes.hpp` packs to **1 byte**, so all Engine classes got padded and their fields landed at wrong offsets. The guards are removed, so the pragmas apply on every compiler.
27. **Missing `<cstdint>`.** The headers use `uint8_t` and friends without including it; MSVC pulls it in transitively. `ME_SDK.hpp` now includes it.
28. **SEH in `UObject::IsA`.** `__try`/`__except` is MSVC-only. It's now guarded by `_MSC_VER`; other compilers run the same loop without the fault guard.
29. **`GetVFunction` casts away `const`** (`ME_Basic.hpp`), which Clang and clang-cl reject. It now reads the vtable through `void* const* const*`.
30. **`_functions.cpp` included `../sdk.h`**, so the SDK folder couldn't build on its own. They include `ME_SDK.hpp` now, and `Client/sdk.h` forwards to it.

Found, not fixed (generated code):

31. **Stale offset comments.** Comparing every `// 0xOFFS(0xSIZE)` comment (11,472 fields, 2,963 records) with real compiler layouts gives 586 mismatches that are identical under MSVC, MinGW GCC and MinGW Clang. These are comments the generator wrote before hand edits (for example `UField` is commented 0x44, but the code is 0x40 because `SuperField` was moved to `UStruct`), not compiler effects. The code is what the tested MSVC build uses.
32. **MSVC never reuses base-class tail padding; the game data does.** In 56 fields across 17 classes, the generator's offsets (taken from the game) put a derived struct's first field inside the base's tail padding, for example `FUIAnchorPosition::UnknownData00` at 0x0A. MinGW (Itanium-style layout) matches those offsets; MSVC puts the field at 0x0C. Affected: `FUIAnchorPosition`, `FUIRotation`, `ATdMPTeamPursuitGame`, `UTdMove_Stumble*` (7 classes), and `UTd*Message` classes (7). None are used by the built-in addons or memenu. Fixing it for MSVC would mean flattening those bases into explicit padding.

How it was checked: a generated test (`static_assert` on every commented offset and size) compiled with MinGW GCC, MinGW Clang, and Clang in MSVC-ABI mode (`--target=i686-pc-windows-msvc`, with minimal std stubs), plus a direct GCC-vs-MSVC-ABI comparison of all 3,015 records. After the fixes above, MinGW and MSVC agree on every record except item 32.
