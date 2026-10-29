# API reference

Public API for addon authors. Signatures are copied from the headers in `Client/`.

| Page | Header | Contents |
|---|---|---|
| [Addon](addon.md) | `addon.h` | `class Addon` |
| [Engine: accessors](engine-accessors.md) | `engine.h` | `GetEngine`, `GetViewportClient`, `GetConsole`, `GetWorld`, `GetPlayerController`, `GetPlayerPawn`, `GetTimeTrialGame`, `GetLevelRace`, `GetWindow` |
| [Engine: callbacks](engine-callbacks.md) | `engine.h` | `OnTick`, `OnRenderScene`, `OnProcessEvent`, `OnPreLevelLoad`, `OnPostLevelLoad`, `OnPreDeath`, `OnPostDeath`, `OnActorTick`, `OnBonesTick`, `OnInput`, `OnSuperInput`, callback typedefs |
| [Engine: utilities](engine-utilities.md) | `engine.h` | `ExecuteCommand`, `BlockInput`, `IsKeyDown`, `WorldToScreen`, `SpawnCharacter`, `Despawn`, `TransformBones`, `Character`, `Characters`, `PLAYER_PAWN_BONE_COUNT` |
| [Menu](menu.md) | `menu.h` | `AddTab`, `Show`, `Hide`, `OnVisibilityChange`, `MenuTab` |
| [Settings](settings.md) | `settings.h` | `GetSetting`, `SetSetting`, `Load`, `Save`, `Reset` |
| [Debug](debug.md) | `debug.h` | `ToggleConsole`, `CreateConsole`, `CloseConsole`, crash handler |
| [ImGui extensions](imgui-extensions.md) | `imgui/imgui_mmultiplayer.h` | `Hotkey`, `BeginRawScene`, `EndRawScene`, `Separator(float)`, `HelpMarker`, `DummyVertical`, `SmallArrowButton`, `BeginWindow` |
| [Helpers](helpers.md) | `util.h`, `string_utils.h` | Virtual-key and map-name macros, `Distance`, JSON converters, string conversion |
| [SDK basics](sdk-basics.md) | `sdk/ME_Basic.hpp`, `sdk/ME_Core_*.hpp` | `TArray`, `FString`, `FName`, `TEnumAsByte`, `UObject` core members, core structs |

## Framework-internal

These are reachable from addon code but exist to support the framework. Treat them as unstable:

- `Engine::Initialize()`, `Engine::InitializeD3D()`, `Menu::Initialize()`, `Debug::Initialize()`: called once by `main.cpp`. **Don't call them from an addon.**
- `Hook::TrampolineHook`, `Hook::UnTrampolineHook`, `Hook::SetJMP` (`hook.h`) and `Pattern::FindPattern` (`pattern.h`). The trainer and Dolly addons use them to patch game code directly. The hook only relocates instructions its built-in length table recognises, and it doesn't fix up relative jumps or calls inside the relocated bytes.
- The `D3D9_EXPORT_*` enum in `engine.h`: `IDirect3DDevice9` vtable indices.

## Conventions on these pages

- **Lifecycle** says when you may call the function.
- **Thread** says which context it's safe from, based on the code. See [Callbacks and threads](../concepts/callbacks-and-threads.md#threads) for what's still unverified.
