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
24. `ME_Basic.hpp`: `TArray`'s `template <class T> friend struct TTransArray;` shadows the outer `T`. MSVC accepts it; GCC and Clang reject it. It's the only change needed to parse the SDK with another compiler.
25. The `Misc` addon's UI and settings keys say "Consequtive" (misspelt). That's user-visible; renaming the setting key would break existing settings.
