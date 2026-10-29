# Intercepting script events

`UObject::ProcessEvent` is the engine's entry point for invoking an UnrealScript function on an object. [`Engine::OnProcessEvent`](../api-reference/engine-callbacks.md#onprocessevent) lets you see every call and optionally block it.

```cpp
typedef bool (*ProcessEventCallback)(Classes::UObject *object, Classes::UFunction *function,
                                     void *args, void *result);
```

| Parameter | Meaning |
|---|---|
| `object` | The object the function runs on |
| `function` | The `UFunction` being called. Identify it with `function->GetFullName()`, for example `"Function TdGame.TdPlayerPawn.TakeDamage"` |
| `args` | Pointer to the parameter block. Cast it to the matching `<Class>_<Function>_Params` struct from `ME_<Pkg>_parameters.hpp` |
| `result` | Pointer to the return slot |

**Return `false` to let the event run. Return `true` to block it.** The framework adds up all callbacks' return values; if any callback returns `true`, the original `ProcessEvent` isn't called. Every registered callback still runs.

## Discover what's being called

Start by logging. This is the [Event spy example](../examples/event-spy.md), trimmed:

```cpp
#include <map>
#include <string>

#include "../engine.h"

static std::map<std::string, int> Seen;

static bool OnProcessEvent(Classes::UObject *object, Classes::UFunction *function, void *args,
                           void *result) {
    if (object && function && object == Engine::GetPlayerPawn()) {
        ++Seen[function->GetFullName()];
    }
    return false;
}
```

## Inspect or modify arguments

Cast `args` once you've matched the function. Compare `UFunction` **pointers**, not strings, on the hot path. Look the function up once and cache it:

```cpp
#include "../engine.h"

static bool HalveDamage(Classes::UObject *object, Classes::UFunction *function, void *args,
                        void *result) {
    static auto takeDamage = Classes::UObject::FindObject<Classes::UFunction>(
        "Function TdGame.TdPlayerPawn.TakeDamage");

    if (function == takeDamage && object == Engine::GetPlayerPawn()) {
        auto params = static_cast<Classes::ATdPlayerPawn_TakeDamage_Params *>(args);
        params->Damage /= 2;
    }
    return false;
}
```

To block the call instead, return `true` in the matched branch.

<!-- TODO: verify that ATdPlayerPawn.TakeDamage is actually dispatched through ProcessEvent in-game. In UE3, script-to-script calls normally run through the script VM without ProcessEvent, so only calls that originate in native code (events) reach this hook. Run the event spy to confirm before relying on any particular function. -->

## Costs and caveats

- **It's hot.** The hook runs for every `ProcessEvent` in the game, plus every SDK wrapper call you make, because those go through `ProcessEvent` too. Keep the callback cheap: one or two pointer compares, then `return false`. `GetFullName()` builds a string by walking the outer chain, so the logging example above is a debugging tool, not something to leave on.
- **Recursion.** Calling an SDK function from inside your callback re-enters the hook.
- **Blocked events return 0.** The framework doesn't touch `result` when it blocks, so any return value or out parameter keeps whatever the caller put there.
- **Which functions reach the hook?** Calls the engine makes from native code do. Whether a script-to-script call does depends on the engine; use the event spy to check. <!-- TODO: verify -->
- None of the built-in addons use this hook yet, so it's had less field testing than the others.

Related: [The game SDK](../concepts/game-sdk.md#calling-script-functions)
