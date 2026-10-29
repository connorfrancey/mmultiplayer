# Hello world: your first addon

In this walkthrough you build an addon that adds a **Hello** tab to the in-game menu and shows the player's position. It takes four steps: write the class, add the files to the project, register the addon, then build and run.

An **addon** is a class derived from [`Addon`](../api-reference/addon.md). It's compiled into `mmultiplayer.dll`. The framework has no plugin loader, so every addon is listed by hand in `Client/main.cpp`.

## 1. Write the addon

Create `Client/addons/hello.h`:

```cpp
#pragma once

#include "../addon.h"

class Hello : public Addon {
  public:
    bool Initialize() override;
    std::string GetName() override;
};
```

Create `Client/addons/hello.cpp`:

```cpp
#include "hello.h"

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../menu.h"

static void HelloTab() {
    ImGui::Text("Hello from my first addon!");

    const auto pawn = Engine::GetPlayerPawn();
    if (!pawn) {
        ImGui::TextDisabled("Load a level to see your position.");
        return;
    }

    ImGui::Text("Position: %.0f, %.0f, %.0f", pawn->Location.X, pawn->Location.Y,
                pawn->Location.Z);
}

bool Hello::Initialize() {
    Menu::AddTab("Hello", HelloTab);
    return true;
}

std::string Hello::GetName() { return "Hello"; }
```

What's going on:

- `Initialize()` runs once at startup, after the engine hooks and menu are ready. Register all your callbacks here. See [Addon lifecycle](../concepts/addon-lifecycle.md).
- [`Menu::AddTab`](../api-reference/menu.md#addtab) calls `HelloTab` every frame while your tab is selected. ImGui calls are valid inside it.
- [`Engine::GetPlayerPawn`](../api-reference/engine-accessors.md#getplayerpawn) returns `nullptr` in the main menu and during level loads. **Always check it.**
- `pawn->Location` is a field of the generated `Classes::AActor`, an [`FVector`](../api-reference/sdk-basics.md#core-structs) in Unreal units.

## 2. Add the files to the project

Add the two files to `Client/Client.vcxproj`. In Visual Studio, use **Add > Existing Item**. To do it by hand, add these lines next to the other addon entries:

```xml
<ClInclude Include="addons\hello.h" />
```

```xml
<ClCompile Include="addons\hello.cpp" />
```

`Client.vcxproj.filters` only controls the Solution Explorer folders and is optional. The CMake build globs `Client/addons/`, so it needs no change.

## 3. Register the addon

In `Client/main.cpp`, include the header and add an instance to the `addons` array:

<!-- verify: skip (main.cpp excerpt; the edited main.cpp is checked as a whole) -->
```cpp
#include "addons/chaos/chaos.h"
#include "addons/hello.h"   // add
```

<!-- verify: skip (main.cpp excerpt; the edited main.cpp is checked as a whole) -->
```cpp
Addon *addons[] = { new Client(), new Trainer(), new Dolly(), new Misc(), new Chaos(), new Hello() };
```

Tabs appear in the order addons register them, after the built-in **Engine** and **World** tabs.

## 4. Build and run

1. Build Release; see [Building and running](building.md).
2. Copy `mmultiplayer.dll` next to `Launcher.exe`, run the launcher, then start the game.
3. The menu opens at startup. If it's closed, press **Insert**. Select the **Hello** tab.
4. Load any level. The tab now shows your position, and the numbers change as you move.

If `Initialize()` returns `false`, a message box says `Failed to initialize "Hello"`. The other addons still load.

## Next steps

- Draw on screen instead of in the menu: [Drawing overlays](../guides/drawing-overlays.md)
- Remember a setting between sessions: [Persisting settings](../guides/persisting-settings.md)
- See more complete addons: [Examples](../examples/index.md)
