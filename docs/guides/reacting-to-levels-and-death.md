# Reacting to level loads and death

## Level loads

```cpp
#include <string>

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../settings.h"
#include "../string_utils.h"
#include "../util.h" // needs imgui.h and settings.h first

static std::string Level;

static void RegisterLevelHooks() {
    Engine::OnPreLevelLoad([](const wchar_t *levelName) {
        // Drop anything that points into the old level
    });

    Engine::OnPostLevelLoad([](const wchar_t *levelName) {
        Level = GetLowercasedLevelName(levelName);
        if (Level == Map_MainMenu) {
            // in the main menu
        }
    });
}
```

What happens around a load:

1. `OnPreLevelLoad(levelName)` runs.
2. The framework clears the `SpawnCharacter` queue. Pending spawns are dropped and never written.
3. While the engine loads, `GetWorld`, `GetPlayerController`, `GetPlayerPawn`, `GetTimeTrialGame` and `GetLevelRace` return `nullptr`.
4. `OnPostLevelLoad(levelName)` runs with the same name.

**Pointers to actors don't survive a level change.** Set them to null in `OnPreLevelLoad`, and re-create or re-find them in `OnPostLevelLoad`. The multiplayer client and the Dolly addon do exactly this for their spawned characters.

### Level names

The name the engine passes keeps its original case. Compare in lower case with `GetLowercasedLevelName` (`string_utils.h`) against the macros in `util.h`:

| Macro | Value | Macro | Value |
|---|---|---|---|
| `Map_MainMenu` | `"tdmainmenu"` | `Map_NewEden` | `"mall_p"` |
| `Map_Prologue` | `"edge_p"` | `Map_Factory` | `"factory_p"` |
| `Map_Flight` | `"escape_p"` | `Map_TheBoat` | `"boat_p"` |
| `Map_Jacknife` | `"stromdrain_p"` | `Map_Kate` | `"convoy_p"` |
| `Map_Heat` | `"cranes_p"` | `Map_TheShard` | `"scraper_p"` |
| `Map_Ropeburn` | `"subway_p"` | | |

The World tab gets the current map with `world->GetMapName(false)` and lists the streaming sublevels from `world->StreamingLevels`.

## Death

`Engine::OnPreDeath` and `Engine::OnPostDeath` take no arguments and fire around the engine's death/respawn routine:

```cpp
#include "../engine.h"

static bool ToolActive = false;

static void RegisterDeathHooks() {
    Engine::OnPreDeath([]() { ToolActive = false; });   // as the trainer does
    Engine::OnPostDeath([]() { /* respawn helpers, reset counters */ });
}
```

The multiplayer client treats the gap between them like a level load: it pauses updates in `OnPreDeath` and respawns other players' characters in `OnPostDeath`.
<!-- TODO: verify exactly which engine routine the PreDeath/PostDeath patterns hook and whether it also fires on checkpoint reloads -->

Example: [Level logger](../examples/level-logger.md)
