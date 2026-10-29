# Engine: utilities

**Header:** `Client/engine.h` · **Namespace:** `Engine`

## `ExecuteCommand`

```cpp
void ExecuteCommand(const wchar_t *command);
```

Queues `command` to run through `UTdConsole::ConsoleCommand` at the start of the next tick where a player pawn exists.

| | |
|---|---|
| **Parameters** | `command`: wide, null-terminated. It's copied, so a temporary is fine. |
| **Returns** | Nothing. There's no success indicator or output. |
| **Thread** | Any. The queue is mutex-protected on push and drain. |
| **Edge cases** | Commands queued while there's no pawn (main menu, loading) wait. The console comes from `GetConsole()`; if that's null, the queue isn't drained that tick. |

<!-- verify: wrap() -->
```cpp
Engine::ExecuteCommand(L"open edge_p");  // UE3 "open <map>"; see the guide
```

Guide: [Running console commands](../guides/console-commands.md)

## `BlockInput`

```cpp
void BlockInput(bool block);
```

When `block` is `true`:
- keyboard and mouse messages go to ImGui instead of the game, except `WM_SYSCOMMAND`, `WM_ACTIVATEAPP` and `WM_PAINT`;
- `OnInput` callbacks stop;
- `IsKeyDown` returns `false`;
- ImGui draws a software mouse cursor.

`Menu::Show()` and `Menu::Hide()` call this function, so they override whatever you set.

| | |
|---|---|
| **Thread** | Writes a plain `bool`. The built-in addons call it from input and render callbacks. |

## `IsKeyDown`

```cpp
bool IsKeyDown(int);
```

`true` while the virtual key is held, as tracked from the window's keyboard messages.

| | |
|---|---|
| **Returns** | `false` if input is blocked, the code is outside `0..255`, or the key isn't held. |
| **Edge cases** | Mouse buttons are never tracked. The state is only as fresh as the last processed message. |

```cpp
#include "../engine.h"

static void OnTick(float delta) {
    if (Engine::IsKeyDown(VK_SHIFT)) {
        // sprinting modifier held
    }
}
```

## `WorldToScreen`

```cpp
bool WorldToScreen(IDirect3DDevice9 *device, Classes::FVector &inOutLocation);
```

Projects a world-space point to screen pixels using the last projection matrix the engine computed, the device's current view and world transforms, and the player camera's FOV.

| | |
|---|---|
| **Parameters** | `device`: the device passed to your render callback. `inOutLocation`: the world position on input. On output, `X`/`Y` are pixel coordinates and `Z` is clip-space `w`. |
| **Returns** | `false` if the point is behind the camera, there's no player controller, or the projection hook hasn't run yet. When the point is behind the camera, `inOutLocation` is still overwritten, so pass a copy. When there's no controller or projection, it's left untouched. |
| **Lifecycle** | Call from `OnRenderScene`; it reads ImGui's `DisplaySize`. |

Guide: [Drawing overlays](../guides/drawing-overlays.md#labels-at-world-positions)

## `Character` / `Characters`

<!-- verify: skip (restates engine.h declarations; checked by signature check) -->
```cpp
static const char *Characters[] = {"Faith", "Kate", "Celeste", "Assault Celeste", "Jacknife",
                                   "Miller", "Kreeg", "Pursuit Cop", "Ghost"};

enum class Character { Faith, Kate, Celeste, AssaultCeleste, Jacknife, Miller, Kreeg, PursuitCop, Ghost, Max };
```

The characters `SpawnCharacter` can create. `Characters[i]` is the display name for `static_cast<Character>(i)`. `Max` is a count, not a character.

## `SpawnCharacter`

<!-- verify: skip (signature restated from the header; checked by the signature check) -->
```cpp
void SpawnCharacter(Character character, Classes::ASkeletalMeshActorSpawnable *&spawned);
```

Queues a character spawn and **writes the new actor into `spawned` later**.

| | |
|---|---|
| **Parameters** | `character`: which model. `spawned`: **a reference that's stored**. It's set to `nullptr` now and to the actor on the next tick where a pawn exists. |
| **Returns** | Nothing. Poll `spawned`. |
| **Lifetime** | `spawned` must stay valid until the spawn completes or the next level load clears the queue. Use a static or long-lived member. |
| **Edge cases** | If the variable is already non-null when the queue drains, the spawn is skipped. A level load drops pending spawns. The actor has no collision and `bUpdateSkelWhenNotRendered = true`. |

Guide: [Spawning characters](../guides/spawning-characters.md)

## `Despawn`

```cpp
void Despawn(Classes::ASkeletalMeshActorSpawnable *actor);
```

Calls `actor->ShutDown()`. Does nothing if `actor` is `nullptr`. It doesn't clear your pointer.

## `TransformBones`

<!-- verify: skip (signature restated from the header; checked by the signature check) -->
```cpp
#define PLAYER_PAWN_BONE_COUNT (108)

void TransformBones(Character character, Classes::TArray<Classes::FBoneAtom> *dest,
                    Classes::FBoneAtom *src);
```

Copies a player-pawn pose (`src`, `PLAYER_PAWN_BONE_COUNT` atoms) into `dest`, the bone atoms of a spawned `character`, remapping bone indices per character. Faith and Ghost are copied 1:1.

| | |
|---|---|
| **Lifecycle** | Call from `OnBonesTick` with that callback's `atoms` as `dest`. |
| **Edge cases** | No bounds checks. `dest` must be the matching character's skeleton, or memory is corrupted. `Max` copies nothing. |
