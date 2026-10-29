# Adding a menu tab

The in-game menu is one ImGui window, titled `MMultiplayer 2.5.2`, that holds a tab bar. You add a tab with [`Menu::AddTab`](../api-reference/menu.md#addtab). Your function is called every frame while the menu is open and your tab is selected, between `BeginTabItem` and `EndTabItem`. Call any ImGui widget inside it.

```cpp
#include "../imgui/imgui.h"
#include "../menu.h"

static bool Enabled = false;
static float Strength = 1.0f;

static void MyTab() {
    ImGui::Checkbox("Enabled##mytab-enabled", &Enabled);

    if (!Enabled) {
        return;
    }

    ImGui::Separator(5.0f);
    ImGui::SliderFloat("Strength##mytab-strength", &Strength, 0.0f, 2.0f);
    ImGui::HelpMarker("How strong the effect is. Default 1.0");
}

// In your Initialize():
//     Menu::AddTab("My Tab", MyTab);
```

## Conventions used by the built-in tabs

- **Unique IDs.** ImGui identifies widgets by label, so the built-in addons add a `##<addon>-<widget>` suffix (for example, `"Execute Command##engine-execute-command"`). Do the same so your widgets don't collide with another tab's.
- **An "Enabled" gate.** `Misc` shows a single **Enabled** checkbox and returns early when it's off. Its tick and render callbacks check the same flag.
- **Null-check game objects** before showing controls that edit them. The **World** tab draws nothing while `Engine::GetWorld()` is null.
- **Persist on change.** Call `Settings::SetSetting` inside the `if (ImGui::Checkbox(...))` branch, so it only runs when the value changes. See [Persisting settings](persisting-settings.md).

## Project ImGui widgets

`imgui.h` pulls in `imgui_mmultiplayer.h` automatically (through `IMGUI_USER_H_FILENAME`), which adds these widgets to `namespace ImGui`:

| Widget | Use |
|---|---|
| `Separator(float height)` | A separator with `height/2` of padding above and below |
| `HelpMarker(const char *desc)` | A `(?)` on the same line with a tooltip |
| `Hotkey(label, int *key, size)` | A key-binding picker; see [Handling input](handling-input.md) |
| `DummyVertical(float height)` | Vertical spacing |
| `SmallArrowButton(id, dir, size)` | A sized arrow button |
| `BeginWindow` | `Begin` plus position handling (used for the main menu) |
| `BeginRawScene` / `EndRawScene` | A full-screen transparent drawing surface; see [Drawing overlays](drawing-overlays.md) |

Full signatures: [ImGui extensions](../api-reference/imgui-extensions.md).

## Reacting to the menu opening or closing

While the menu is open, the framework blocks game input (`Engine::BlockInput(true)`) and draws a mouse cursor. To find out when this happens, register with `Menu::OnVisibilityChange`:

```cpp
#include "../menu.h"

static bool MenuOpen = false;

static void RegisterMenuWatcher() {
    Menu::OnVisibilityChange([](bool show) { MenuOpen = show; });
}
```

The trainer uses this to hide its speedometer editor windows when the menu closes and restore them when it reopens.

Example: [Hello world](../getting-started/hello-world.md) · [Speed HUD](../examples/speed-hud.md)
