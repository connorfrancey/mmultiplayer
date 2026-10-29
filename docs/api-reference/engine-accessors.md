# Engine: accessors

**Header:** `Client/engine.h` · **Namespace:** `Engine`

Cached getters for the game's core objects. Read [Object accessors](../concepts/object-accessors.md) first; it explains caching, the `update` flag, and why results can be `nullptr`.

**Common behaviour**

- Each function caches its result in a function-local static. `update = true` re-resolves it and propagates down the chain.
- **Lifecycle:** valid only after `Engine::Initialize()`, so call them from `Initialize()` or later, never from a constructor.
- **Thread:** the caches aren't synchronized. Calling from engine-thread callbacks is safe. Render and input callbacks also call them throughout the built-in addons. <!-- TODO: verify thread model -->
- **Always null-check the result.**

## `GetEngine`

```cpp
Classes::UTdGameEngine *GetEngine(bool update = false);
```

The game engine object. It's the first `UTdGameEngine` in `GObjects` whose `Outer` is named `"Transient"`.

**Returns:** the engine, or `nullptr` if none is found. A null result isn't cached, so the next call scans again.
**Cost:** a full `GObjects` scan when the cache is empty or `update` is `true`.

## `GetViewportClient`

```cpp
Classes::UTdGameViewportClient *GetViewportClient(bool update = false);
```

`GetEngine(update)->GameViewport`, cast to `UTdGameViewportClient`. Returns `nullptr` if there's no engine.

## `GetConsole`

```cpp
Classes::UTdConsole *GetConsole(bool update = false);
```

`GetViewportClient(update)->ViewportConsole`, cast to `UTdConsole`. Returns `nullptr` if there's no viewport client. To run a command, use [`ExecuteCommand`](engine-utilities.md#executecommand) instead of calling `ConsoleCommand` on this object yourself; `ExecuteCommand` defers the call to the tick.

## `GetWorld`

```cpp
Classes::AWorldInfo *GetWorld(const bool update = false);
```

The `AWorldInfo` whose `ControllerList` contains the player controller: a `TdGame.TdPlayerController`, or Softimer's `MirrorsEdgeTweaksScripts.SofTimerPlayerController`.

**Returns** `nullptr`:
- while a level is loading, whatever is cached;
- when no world has a player controller.

**Cost:** a full `GObjects` scan when the cache is empty or `update` is `true`. The framework calls `GetPlayerPawn(true)` every tick, which refreshes this.

## `GetPlayerController`

```cpp
Classes::ATdPlayerController *GetPlayerController(bool update = false);
```

The player controller from `GetWorld(update)->ControllerList`.

**Returns** `nullptr`:
- while a level is loading;
- when there's no world;
- when the controller's `PlayerCamera` is null, so a non-null result always has a camera.

## `GetPlayerPawn`

```cpp
Classes::ATdPlayerPawn *GetPlayerPawn(bool update = false);
```

`GetPlayerController(update)->AcknowledgedPawn`, cast to `ATdPlayerPawn`.

**Returns** `nullptr`:
- while a level is loading;
- when there's no controller;
- when the controller has no acknowledged pawn, for example in the main menu.

**Note:** the framework calls `GetPlayerPawn(true)` at the start of every tick, so the plain call is current as of this tick.

```cpp
#include "../engine.h"

static void OnTick(float delta) {
    if (const auto pawn = Engine::GetPlayerPawn()) {
        pawn->Health = pawn->MaxHealth;
    }
}
```

## `GetTimeTrialGame`

```cpp
Classes::ATdSPTimeTrialGame *GetTimeTrialGame(bool update = false);
```

`GetWorld(update)->Game`, if its object name contains `"TdSPTimeTrialGame"`.

**Returns** `nullptr` while loading, when there's no world, or when the current game mode isn't a time trial.
**Edge case:** it dereferences `world->Game` without a null check. <!-- TODO: verify Game is never null while a world exists -->

## `GetLevelRace`

```cpp
Classes::ATdSPLevelRace *GetLevelRace(bool update = false);
```

Same as `GetTimeTrialGame`, but matches `"TdSPLevelRace"`, with the same edge case.

## `GetWindow`

```cpp
HWND GetWindow();
```

The game's window handle, as resolved when ImGui initialized on the first `EndScene` (and updated after a successful device `Reset`). Returns `nullptr` before the first frame has rendered. Not cached per call; it returns the stored value directly.

Related guides: [Reading player state](../guides/reading-player-state.md) · [Finding game classes](../guides/finding-game-classes.md)
