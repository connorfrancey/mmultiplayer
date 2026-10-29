# SDK basics

**Headers:** `Client/sdk/ME_Basic.hpp`, `Client/sdk/ME_Core_structs.hpp`, `Client/sdk/ME_Core_classes.hpp` · **Namespace:** `Classes`

**Umbrella header:** `Client/sdk/ME_SDK.hpp` (the client's `Client/sdk.h` forwards to it). Each generated header sets its own packing, 4 bytes except `ME_Engine_classes.hpp` at 1 byte, so layouts match the game's memory. Don't change packing around SDK includes. See [Packing and compilers](../concepts/game-sdk.md#packing-and-compilers).

Concepts first: [The game SDK](../concepts/game-sdk.md).

## `TArray<T>`

A view of an engine-owned dynamic array: `{T* Data; int32_t Count; int32_t Max;}`.

| Member | Notes |
|---|---|
| `T *Buffer() const` | Raw pointer to the data |
| `size_t Num() const` | Element count |
| `T &operator[](size_t)`, `GetByIndex(size_t)` | **No bounds check** |
| `bool IsValidIndex(size_t) const` | `i < Num()` |

There's no API to add or remove elements. Don't construct `TArray`s to pass into the engine unless you know who frees the memory.

## `FString`

A wide string, based on `TArray<wchar_t>`.

| Member | Notes |
|---|---|
| `FString(const wchar_t *other)` | **Wraps `other` without copying it.** The pointer must stay valid for as long as the engine uses it, so pass literals or long-lived buffers. |
| `const wchar_t *c_str() const` | |
| `bool IsValid() const` | `Data != nullptr` |
| `std::string ToString() const` | Narrows using the current locale. Non-representable characters become `?`. **Crashes on an invalid (`IsValid() == false`) string**, so check first. |

## `FName`

An index into the global name table: `{int32_t Index; int32_t Number;}`.

| Member | Notes |
|---|---|
| `FName(const char *nameToFind)` | **Linear search** of `GNames`, with a small cache of previously found indices. If the name doesn't exist, the index stays 0. |
| `FName(int32_t i)` | From an index |
| `std::string GetName() const` | The name, plus `_<Number-1>` when `Number > 0` |
| `operator==` | Compares index and number |
| `static TArray<FNameEntry*> *GNames` | Set by `Engine::Initialize()` |

## `TEnumAsByte<E>`

A one-byte enum holder. It converts implicitly to `E` and can be constructed from `E`. Use `GetValue()` for an explicit read.

## `UObject` (core members)

| Member | Notes |
|---|---|
| `Outer`, `Name`, `Class`, `ObjectFlags`, `ObjectArchetype` | Header fields |
| `static TArray<UObject*> *GObjects` / `GetGlobalObjects()` | All objects. **Entries can be null.** |
| `std::string GetName() const` | For example `"TdPlayerPawn_0"` |
| `std::string GetObjectName()` | The name with the last `_suffix` stripped |
| `std::string GetFullName() const` | `"<Class> <Outer...>.<Name>"` |
| `template<T> static T *FindObject(const std::string &fullName)` | Linear scan comparing `GetFullName()`. Slow; cache the result. |
| `static UClass *FindClass(const std::string &fullName)` | `FindObject<UClass>`. Pass `"Class Pkg.Name"`. |
| `template<T> static T *GetObjectCasted(size_t index)` | Unchecked cast of `GObjects[index]` |
| `bool IsA(UClass *cmp) const` | Inheritance test; returns `false` on access faults (SEH-guarded) |
| `static UClass *StaticClass()` | Present on every class |
| `void ProcessEvent(UFunction *, void *parms)` | Calls vtable slot 61, passing a dummy result pointer. All script-function wrappers use it. |

```cpp
#include "../engine.h"

static bool IsPlayerPawn(Classes::UObject *object) {
    return object && object->IsA(Classes::ATdPlayerPawn::StaticClass());
}
```

## Core structs

From `ME_Core_structs.hpp`:

| Struct | Fields | Notes |
|---|---|---|
| `FVector` | `float X, Y, Z` | Unreal units (100 = 1 m) |
| `FRotator` | `unsigned int Pitch, Yaw, Roll` | 65536 = 360°. Unsigned in this SDK. |
| `FVector2D`, `FQuat`, `FMatrix`, `FColor`, `FLinearColor`, ... | | See the header |

`CONST_Pi` (`3.1415926535897932f`) and other `CONST_*` macros are defined there too.
