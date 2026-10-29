# `Addon`

**Header:** `Client/addon.h`

The abstract base class for every addon.

```cpp
class Addon {
public:
    Addon(const Addon &Other) = default;
    Addon(Addon &&Other) noexcept = default;
    Addon &operator=(const Addon &Other) = default;
    Addon &operator=(Addon &&Other) noexcept = default;
    Addon() = default;
    virtual ~Addon() = default;
    virtual bool Initialize() = 0;
    virtual std::string GetName() = 0;
};
```

## `Initialize`

```cpp
virtual bool Initialize() = 0;
```

Called once at startup, from `InitThread`, after `Engine::Initialize()`, `Debug::Initialize()` and `Menu::Initialize()` have succeeded. Addons are initialized in the order they appear in the `addons[]` array in `Client/main.cpp`.

**Returns:** `true` on success. If you return `false`, the framework shows a "Fatal" message box, `Failed to initialize "<GetName()>"`, and continues with the next addon. Nothing is undone: callbacks and tabs you registered before failing stay active.

**Do here:** read settings, register callbacks and tabs, start threads. See [Addon lifecycle](../concepts/addon-lifecycle.md).

## `GetName`

```cpp
virtual std::string GetName() = 0;
```

A human-readable name. The framework only uses it in the initialization failure message. The built-in addons return `"Multiplayer Client"`, `"Misc"`, and so on.

## Registering an addon

There's no discovery mechanism. Add `new YourAddon()` to the array in `Client/main.cpp` and add your files to `Client/Client.vcxproj`. See [Hello world](../getting-started/hello-world.md#3-register-the-addon).

## Lifetime

- Construction happens **before** `Engine::Initialize()`, so the SDK isn't usable in constructors.
- Addons are never deleted on the success path, so destructors don't run.
- If `Engine::Initialize()` or `Menu::Initialize()` fails, every addon is deleted without `Initialize()` ever being called.

## Example

```cpp
#include "../addon.h"
#include "../menu.h"

class Minimal : public Addon {
  public:
    bool Initialize() override {
        Menu::AddTab("Minimal", []() {});
        return true;
    }

    std::string GetName() override { return "Minimal"; }
};
```
