# Reading and changing player state

You get the player through the [object accessors](../concepts/object-accessors.md). Read state anywhere. **Change it from `OnTick`** so the change lands in sync with the game (see [threads](../concepts/callbacks-and-threads.md#threads)).

## The objects

| Object | Type | Useful fields (all verified in the generated headers) |
|---|---|---|
| `Engine::GetPlayerPawn()` | `Classes::ATdPlayerPawn *` | `Location`, `Rotation`, `Velocity` (from `AActor`); `Health`, `MaxHealth` (from `APawn`); `MovementState` (`TEnumAsByte<EMovement>`, from `ATdPawn`); `Mesh1p`, `Mesh3p` |
| `Engine::GetPlayerController()` | `Classes::ATdPlayerController *` | `Rotation` (view rotation), `PlayerCamera`, `PlayerInput` |
| `Engine::GetWorld()` | `Classes::AWorldInfo *` | `TimeDilation`, `WorldGravityZ`, `Game`, `StreamingLevels`, `ControllerList` |

## Read: a speed and state readout

```cpp
#include <cmath>

#include "../engine.h"
#include "../imgui/imgui.h"

static void PlayerInfoTab() {
    const auto pawn = Engine::GetPlayerPawn();
    const auto controller = Engine::GetPlayerController();
    if (!pawn || !controller) {
        ImGui::TextDisabled("No player");
        return;
    }

    // Horizontal speed, as the trainer's speedometer computes it
    const float speed = sqrtf(pawn->Velocity.X * pawn->Velocity.X +
                              pawn->Velocity.Y * pawn->Velocity.Y);

    // Rotator units: 65536 = 360 degrees
    const float yaw = static_cast<float>(controller->Rotation.Yaw % 0x10000) / 65536.0f * 360.0f;

    ImGui::Text("Speed:  %.2f m/s", speed / 100.0f);
    ImGui::Text("Yaw:    %.1f deg", yaw);
    ImGui::Text("Health: %d / %d", pawn->Health, pawn->MaxHealth);
    ImGui::Text("Wall climbing: %s",
                pawn->MovementState == Classes::EMovement::MOVE_WallClimbing ? "yes" : "no");
}
```

`EMovement` (in `ME_TdGame_structs.hpp`) lists every movement state: `MOVE_Walking`, `MOVE_Falling`, `MOVE_WallRunningLeft`, `MOVE_WallRunningRight`, `MOVE_WallClimbing`, `MOVE_SpringBoarding`, `MOVE_FallingUncontrolled`, and many more.

## Write: keep the player alive

This is how the trainer's god mode works (`Client/addons/trainer.cpp`). It resets health and the fall-damage reference height every tick:

```cpp
#include "../engine.h"

static bool God = false;

static void OnTick(float delta) {
    if (!God) {
        return;
    }

    const auto pawn = Engine::GetPlayerPawn();
    if (!pawn) {
        return;
    }

    pawn->Health = pawn->MaxHealth;
    pawn->EnterFallingHeight = -1e30f;
}

// In Initialize():  Engine::OnTick(OnTick);
```

Other patterns from the built-in addons:

- **Change game speed**: `pawn->WorldInfo->TimeDilation = 0.25f;` (Misc "Permanent Game Speed").
- **Colour-grade the camera**: `controller->PlayerCamera->ColorScale = Classes::FVector{1, 0.5f, 0.5f};` (Misc "Color Scale"). Check `PlayerCamera` for null first.
- **Reach a movement object**: `pawn->Moves[static_cast<size_t>(Classes::EMovement::MOVE_WallRunningRight)]`, cast to `Classes::UTdMove_WallRun *` (Misc "No Consecutive Wallruns Limit").
- **Call into game logic**: `static_cast<Classes::ATdGameInfo *>(world->Game)->TdGameData->QuitToMainMenu();` (Chaos "Go To MainMenu").

## Teleporting

Teleporting by writing `pawn->Location` works, but it leaves movement state behind; the changelog lists many teleport fixes. The trainer's save/load state (`Client/addons/trainer.cpp`, `Load()`) restores many more fields. Read it before you write your own teleport.

Related: [Object accessors](../concepts/object-accessors.md) · [Finding game classes](finding-game-classes.md)
