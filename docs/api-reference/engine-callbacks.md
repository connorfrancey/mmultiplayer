# Engine: callbacks

**Header:** `Client/engine.h` · **Namespace:** `Engine` (registration functions); the typedefs are global

**Common behaviour**

- Callbacks are plain function pointers. Lambdas must have **no captures**.
- Callbacks of one kind run in registration order. You **can't unregister** a callback.
- **Lifecycle:** register from `Addon::Initialize()` only. The callback vectors aren't synchronized; see [Addon lifecycle](../concepts/addon-lifecycle.md#register-only-during-initialize).
- Nothing in the hooks catches C++ exceptions. One that escapes your callback unwinds into game code and will most likely reach the [crash handler](debug.md#crash-handler). Don't let exceptions escape; nlohmann/json conversions are the usual source.

Timing and threads: see [Callbacks and threads](../concepts/callbacks-and-threads.md).

## Typedefs

```cpp
typedef void (*RenderSceneCallback)(IDirect3DDevice9 *device);
typedef bool (*ProcessEventCallback)(Classes::UObject *, Classes::UFunction *, void *, void *);
typedef void (*LevelLoadCallback)(const wchar_t *levelName);
typedef void (*DeathCallback)();
typedef void (*ActorTickCallback)(Classes::AActor *actor);
typedef void (*BonesTickCallback)(Classes::TArray<Classes::FBoneAtom> *atoms);
typedef void (*TickCallback)(float delta);
typedef void (*InputCallback)(unsigned int &message, int keycode);
```

## `OnTick`

```cpp
void OnTick(TickCallback callback);
```

Called once per engine tick, with the tick's `delta`, before the original tick runs. Before your callbacks, the framework refreshes `GetPlayerPawn(true)` and, if a pawn exists, drains the [`ExecuteCommand`](engine-utilities.md#executecommand) and [`SpawnCharacter`](engine-utilities.md#spawncharacter) queues.

This is the right place to change game state. <!-- TODO: verify that delta is in seconds -->

<!-- verify: wrap() -->
```cpp
Engine::OnTick([](float delta) { /* per-tick logic */ });
```

## `OnRenderScene`

```cpp
void OnRenderScene(RenderSceneCallback callback);
```

Called every frame from the hooked `IDirect3DDevice9::EndScene`, after `ImGui::NewFrame()` and before `ImGui::EndFrame()`/`Render()`. `device` is the game's D3D9 device. Use it for ImGui drawing and [`WorldToScreen`](engine-utilities.md#worldtoscreen).

**Edge cases:** it doesn't run until the framework has hooked the device and resolved the game window. On the first frame ImGui is created and the window procedure is subclassed. The main menu is drawn from a render callback registered by `Menu::Initialize()`, which runs before every addon's, so addon overlays draw after it in the ImGui draw order.

Guide: [Drawing overlays](../guides/drawing-overlays.md)

## `OnProcessEvent`

```cpp
void OnProcessEvent(ProcessEventCallback callback);
```

Called before every `UObject::ProcessEvent(object, function, args, result)`. That includes calls made by SDK wrappers.

**Return value:** `false` lets the event run. `true` blocks it: the framework adds up all callbacks' returns, and if the sum is non-zero it skips the original and returns `0`. Every callback runs regardless.

**Cost:** very high call frequency; keep it cheap. Guide: [Intercepting script events](../guides/intercepting-events.md)

## `OnPreLevelLoad` / `OnPostLevelLoad`

```cpp
void OnPreLevelLoad(LevelLoadCallback callback);
void OnPostLevelLoad(LevelLoadCallback callback);
```

Called before and after the engine's level-load routine. `levelName` is the level's name as the engine passes it (mixed case). Lower-case it with `GetLowercasedLevelName` before comparing it with the `Map_*` macros.

Between the two calls:
- the spawn queue is cleared;
- `GetWorld`, `GetPlayerController`, `GetPlayerPawn`, `GetTimeTrialGame` and `GetLevelRace` return `nullptr`.

Guide: [Reacting to level loads and death](../guides/reacting-to-levels-and-death.md)

## `OnPreDeath` / `OnPostDeath`

```cpp
void OnPreDeath(DeathCallback callback);
void OnPostDeath(DeathCallback callback);
```

Called before and after the engine routine the framework identifies as death handling. `OnPostDeath` runs after the original returns. <!-- TODO: verify exactly what the PreDeath/PostDeath patterns hook -->

## `OnActorTick`

```cpp
void OnActorTick(ActorTickCallback callback);
```

Called for **every ticking actor**, before that actor's native tick. `actor` can be null; check it. Typical use: match `actor` against an actor you own and set its `Location`/`Rotation`, as the multiplayer client and the Dolly addon do.

## `OnBonesTick`

```cpp
void OnBonesTick(BonesTickCallback callback);
```

Called after the engine computes a skeletal mesh's local bone atoms, only when `atoms->Num() > 0`. To identify which mesh the atoms belong to, compare `atoms->Buffer()` with `mesh->LocalAtoms.Buffer()`. Overwrite the atoms in place, for example with [`TransformBones`](engine-utilities.md#transformbones). Guide: [Spawning characters](../guides/spawning-characters.md#moving-and-animating)

## `OnInput`

```cpp
// Adds a standard input callback. Will not trigger if the menu is blocking input.
void OnInput(InputCallback callback);
```

Called on keyboard state **transitions**. `message` is `WM_KEYDOWN`, `WM_SYSKEYDOWN`, `WM_KEYUP` or `WM_SYSKEYUP`, and `keycode` is the virtual-key code (`< 0x100`). It's skipped while [`BlockInput(true)`](engine-utilities.md#blockinput) is in effect. Mouse buttons aren't reported.

`message` is a reference to the real message. Changing it changes what the game receives. <!-- TODO: verify this is intended -->

Guide: [Handling input](../guides/handling-input.md)

## `OnSuperInput`

```cpp
// Adds a super input callback. A super input callback will trigger even if the
// menu is blocking input.
void OnSuperInput(InputCallback callback);
```

Same as `OnInput`, but it also fires while input is blocked. Super callbacks run before normal ones. The menu uses one to close itself on its toggle key or Escape.
