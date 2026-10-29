# Spawning characters

The framework can spawn a non-colliding skeletal-mesh actor that looks like one of nine characters. The multiplayer client uses it to show other players, and the Dolly addon uses it to play back recordings.

<!-- verify: skip (summary of the declaration in engine.h) -->
```cpp
enum class Engine::Character { Faith, Kate, Celeste, AssaultCeleste, Jacknife, Miller, Kreeg, PursuitCop, Ghost, Max };
```

`Engine::Characters[]` holds matching display names (`"Faith"`, ..., `"Ghost"`) for combo boxes.

## Spawn, asynchronously

```cpp
#include "../engine.h"

// Must outlive the call: the framework keeps a reference to it.
static Classes::ASkeletalMeshActorSpawnable *Clone = nullptr;

static void SpawnClone() {
    Engine::SpawnCharacter(Engine::Character::Kate, Clone);
    // Clone is nullptr here. It's set on the next tick.
}

static void OnTick(float delta) {
    if (!Clone) {
        return;  // not spawned yet (or spawn was dropped)
    }

    const auto pawn = Engine::GetPlayerPawn();
    if (pawn) {
        Clone->Location = pawn->Location;
        Clone->Location.X += 200.0f;  // 2 m beside the player
    }
}
```

The contract of [`SpawnCharacter(character, spawned)`](../api-reference/engine-utilities.md#spawncharacter):

1. It sets `spawned = nullptr` immediately and queues the request along with **a reference to your pointer variable**.
2. On the next tick where a player pawn exists, the framework spawns the actor (via `player->Spawn`), loads the character's mesh and materials, disables collision, and **writes the result into your variable**.
3. If a level load starts first, the queue is cleared and your variable stays `nullptr`.

So the variable **must outlive the request**. Use a `static`, a global, or a member of an object that lives forever, as the built-in addons do. A local variable leaves a dangling reference.

Kate, Miller and Kreeg get `PrePivot.Z = 94` to correct their mesh origin.

## Moving and animating

- Set `Location` and `Rotation` directly. The built-in addons do this from `OnActorTick` when `actor == yourActor`, so the change applies right before that actor ticks.
- To pose the character, copy bone data in [`OnBonesTick`](../api-reference/engine-callbacks.md#onbonestick) with [`Engine::TransformBones`](../api-reference/engine-utilities.md#transformbones). It maps a 108-bone player-pawn skeleton (`PLAYER_PAWN_BONE_COUNT`) onto each character's skeleton:

```cpp
#include "../engine.h"

static Classes::ASkeletalMeshActorSpawnable *Clone = nullptr;
static Classes::FBoneAtom RecordedBones[PLAYER_PAWN_BONE_COUNT];

static void OnBonesTick(Classes::TArray<Classes::FBoneAtom> *bones) {
    if (Clone && Clone->SkeletalMeshComponent &&
        Clone->SkeletalMeshComponent->LocalAtoms.Buffer() == bones->Buffer()) {
        Engine::TransformBones(Engine::Character::Kate, bones, RecordedBones);
    }
}
```

`src` must point to at least `PLAYER_PAWN_BONE_COUNT` atoms. The destination layout per character is hard-coded in `engine.cpp`.

## Despawn

<!-- verify: wrap(Classes::ASkeletalMeshActorSpawnable *Clone) -->
```cpp
Engine::Despawn(Clone);  // calls Clone->ShutDown(); does nothing for nullptr
Clone = nullptr;
```

## Across level loads

Spawned actors belong to the level. Copy what the built-in addons do:

```cpp
#include "../engine.h"

static Classes::ASkeletalMeshActorSpawnable *Clone = nullptr;

// Call from Initialize()
static void RegisterLevelHooks() {
    Engine::OnPreLevelLoad([](const wchar_t *) { Clone = nullptr; });
    Engine::OnPostLevelLoad([](const wchar_t *) {
        Engine::SpawnCharacter(Engine::Character::Kate, Clone);
    });
}
```

The multiplayer client also respawns in `OnPostDeath`. <!-- TODO: verify whether spawned actors are destroyed on death/respawn -->
