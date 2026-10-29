# The game SDK

`Client/sdk/` holds a C++ mirror of Mirror's Edge's UnrealScript classes. Every header is stamped `// Mirror's Edge (1.0) SDK`. You include it all at once with `#include "ME_SDK.hpp"` (or the client's `sdk.h`, which forwards to it and is what `engine.h` includes). Everything lives in `namespace Classes`.

<!-- TODO: verify which tool generated Client/sdk and whether regeneration is supported; the files have been hand-edited since. -->

## File layout

Each of the 17 UnrealScript packages produces four files:

| File | Contains |
|---|---|
| `ME_<Pkg>_structs.hpp` | `struct F...` (value types) and `enum class E... : uint8_t`, plus `CONST_...` macros |
| `ME_<Pkg>_classes.hpp` | `class U...` / `A...` with field layouts and member function declarations |
| `ME_<Pkg>_parameters.hpp` | `<Class>_<Function>_Params` structs, one per script function |
| `ME_<Pkg>_functions.cpp` | Function wrapper bodies |

The packages that matter most: **Core** (`UObject`, `UClass`, `UFunction`, math structs), **Engine** (`AActor`, `APawn`, `AWorldInfo`, components; about 1,150 classes) and **TdGame** (Mirror's Edge gameplay: `ATdPlayerPawn`, `ATdPlayerController`, `UTdMove_*`; about 900 classes). [Finding game classes](../guides/finding-game-classes.md) explains how to search them.

## Packing and compilers

Each generated header sets its own packing with `#pragma pack(push, ...)`. Most use 4 bytes, but **`ME_Engine_classes.hpp` packs to 1 byte**. This packing now applies on every compiler (it used to be MSVC-only), so MSVC and MinGW (GCC or Clang) produce the same layouts. One exception: on 56 fields across 17 rarely used classes (`FUIAnchorPosition`, `UTdMove_Stumble`, ...), MinGW matches the generator's offsets and MSVC doesn't, because MSVC never reuses a base struct's tail padding. Don't change the packing around SDK includes. Details: [code issues](../_notes/code-issues.md).

## Naming

The UE3 prefixes carry over:

| Prefix | Meaning | Example |
|---|---|---|
| `U` | Object (non-actor) | `UTdGameEngine`, `USkeletalMeshComponent` |
| `A` | Actor (placed or spawned in the world) | `AWorldInfo`, `ATdPlayerPawn` |
| `F` | Struct (value type) | `FVector`, `FRotator`, `FName` |
| `E` | Enum | `EMovement` |
| `T` | Template | `TArray`, `TEnumAsByte` |

## Objects and classes

Every object derives from `Classes::UObject`. The fields you'll use most:

- `Outer`: the containing object.
- `Name`: an [`FName`](../api-reference/sdk-basics.md#fname).
- `Class`: a `UClass*`.

The engine keeps every live object in a global array, `UObject::GObjects`, and every name string in `FName::GNames`. Both are **null until `Engine::Initialize()`** finds them by pattern scan.

- **`StaticClass()`**: every generated class has one. It returns that class's `UClass*`, looked up by full name the first time (for example, `"Class TdGame.TdPlayerPawn"`) and cached in a function-local static.
- **`IsA(UClass*)`**: walks `Class` → `SuperField` to test inheritance. It's wrapped in `__try`, so it returns `false` instead of crashing on a bad object.
- **Casting**: once `IsA` says yes, use `static_cast`. There's no checked cast.

<!-- verify: wrap(Classes::AActor *actor) -->
```cpp
if (actor->IsA(Classes::ATdPlayerPawn::StaticClass())) {
    auto pawn = static_cast<Classes::ATdPlayerPawn *>(actor);
}
```

- **`GetName()`** returns the object's name, for example `TdPlayerPawn_0`. **`GetFullName()`** returns `"<ClassName> <Outer chain>.<Name>"`, for example `"Function TdGame.TdPlayerPawn.TakeDamage"`.
- **`FindObject<T>(fullName)`** and **`FindClass(fullName)`** scan *all* of `GObjects`, comparing `GetFullName()` strings. That's slow, so cache the result.

## Fields

Fields are laid out to match the game's memory, and the offset is in a trailing comment:

<!-- verify: skip (excerpt of a generated header) -->
```cpp
struct FVector  Location;   // 0x00E8(0x000C) (Edit, Const, Net)
```

Reading or writing a field is a plain memory access. The engine isn't notified. For some properties, such as `Location`, the engine expects you to go through a function (for example, `SetLocation`) so collision and replication stay consistent.
<!-- TODO: verify which direct writes are safe; the built-in addons write Location/Rotation/Velocity directly in several places -->

Bitfield flags such as `bHidden` are declared as `unsigned long bHidden : 1;`. Enum-typed fields are `TEnumAsByte<E>` and convert implicitly to the enum:

<!-- verify: wrap(Classes::ATdPlayerPawn *pawn) -->
```cpp
if (pawn->MovementState == Classes::EMovement::MOVE_WallClimbing) { /* ... */ }
```

## Calling script functions

Each UnrealScript function becomes a member function. The wrapper:

1. looks up the `UFunction` once, by full name, and caches it in a function-local static;
2. fills a `<Class>_<Function>_Params` struct with your arguments;
3. temporarily sets `FunctionFlags |= 0x400` (Native) and calls `UObject::ProcessEvent(fn, &params)`, which is a call through vtable slot 61;
4. restores the flags and returns `params.ReturnValue`, or copies `out` params back through pointer arguments.

Consequences:

- **There are no default arguments.** `OptionalParm` parameters are ordinary C++ parameters. Pass a sensible value, usually `0`, `nullptr` or `false`.
- **Static script functions** have a `STATIC_` prefix but are still members. Call them on any instance, for example `actor->STATIC_DynamicLoadObject(...)`.
- **Out parameters** are pointers, for example `STATIC_GetAngularDegreesFromRadians(struct FVector2D* OutFOV)`.
- **Your calls go through the hooked `ProcessEvent`**, so `OnProcessEvent` callbacks (including your own) see them.
- If the function lookup fails, `fn` is null and the wrapper crashes on `fn->FunctionFlags`. That's unlikely for functions in the shipped game. <!-- TODO: verify -->

Example from `Client/engine.cpp`, which spawns an actor and loads a mesh:

<!-- verify: wrap(Classes::ATdPlayerPawn *player) -->
```cpp
const auto actor = static_cast<Classes::ASkeletalMeshActorSpawnable *>(
    player->Spawn(Classes::ASkeletalMeshActorSpawnable::StaticClass(), nullptr, 0,
                  {0}, {0}, nullptr, true));

actor->SetCollisionType(Classes::ECollisionType::COLLIDE_NoCollision);
```

`Spawn` has seven parameters in UnrealScript, and all seven are passed.

## Strings, names, arrays

- **`FString`**: a wide string. `FString(L"...")` **wraps your buffer without copying it**, so the literal or buffer must outlive the call. Use `c_str()` and `ToString()` to read one.
- **`FName`**: an index into `GNames`. `FName("Neck")` does a **linear search** of the name table, with a small cache. `GetName()` returns the string.
- **`TArray<T>`**: `Num()`, `operator[]`, `GetByIndex()`, `IsValidIndex()`, `Buffer()`. It's read-only in practice: there's no add or remove, because the engine owns the memory.

Full details are in [SDK basics](../api-reference/sdk-basics.md).

## Units and conventions

- Distances are in Unreal units. The framework treats **100 units = 1 metre** (`Distance()` in `util.h`).
- `FRotator` components are **65536 units = 360°**. The trainer converts with `(r % 0x10000) / 65536.0f * 360.0f`. In this SDK the fields are declared `unsigned int`; see [code issues](../_notes/code-issues.md).

Related: [Object accessors](object-accessors.md) · [Finding game classes](../guides/finding-game-classes.md) · [Intercepting script events](../guides/intercepting-events.md)
