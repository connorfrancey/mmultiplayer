# ImGui extensions

**Header:** `Client/imgui/imgui_mmultiplayer.h`, pulled in automatically by `imgui.h` through `IMGUI_USER_H_FILENAME` · **Namespace:** `ImGui`

The bundled Dear ImGui is **1.90.2**. Everything in upstream ImGui is available too. These are the project additions:

```cpp
namespace ImGui {
    bool BeginWindow(const char* name, bool* p_open = NULL, ImGuiWindowFlags flags = 0);
    ImGuiWindow* BeginRawScene(const char* name, bool saveSettings = false);
    void EndRawScene();
    bool Hotkey(const char* label, int* k, const ImVec2& size_arg = ImVec2(0, 0));
    void Separator(const float& height);
    void HelpMarker(const char* desc);
    void DummyVertical(const float& height);
    bool SmallArrowButton(const char* str_id, ImGuiDir dir, ImVec2 size);
}
```

**Lifecycle:** call these only inside `OnRenderScene` callbacks or menu tabs, where an ImGui frame is active.

## `Hotkey`

A key-binding field.

| | |
|---|---|
| **Parameters** | `label`: shown to the left; use a `##id` suffix for uniqueness. `k`: the virtual-key code, read and written. `size_arg`: frame size (0 = default). |
| **Returns** | `true` on the frame a new binding is captured (including a clear via Escape). |
| **Behaviour** | Click to capture. The next mouse button (left, right, middle, X1, X2) or key in `VK_BACK..VK_RMENU` becomes the binding. **Escape** sets it to `0` ("None"). If `*k` is out of the name table's range, it's reset to `0`. |
| **Edge cases** | The label table has no entry for `VK_L` (0x4C), so an L binding displays blank. Mouse bindings are captured but never reported by `OnInput`/`IsKeyDown` (see [handling input](../guides/handling-input.md#gotchas)). |

```cpp
static int Key = VK_F8;

static void Tab() {
    if (ImGui::Hotkey("Teleport##myaddon-teleport", &Key)) {
        Settings::SetSetting({"MyAddon", "TeleportKey"}, Key);
    }
}
```

## `BeginRawScene` / `EndRawScene`

`BeginRawScene` opens a full-screen, transparent, borderless, unmovable window that doesn't take focus. It pushes a full-screen clip rect and returns the `ImGuiWindow *`, so you can use `window->DrawList`. `saveSettings = false` adds `ImGuiWindowFlags_NoSavedSettings`. **Always** call `EndRawScene()` afterwards; it pops the clip rect, two style vars and one colour, then calls `End()`.

Guide: [Drawing overlays](../guides/drawing-overlays.md)

## `Separator(float)`

`Dummy(height/2)`, `Separator()`, `Dummy(height/2)`. The built-in tabs use `Separator(5.0f)` between sections.

## `HelpMarker`

Draws `(?)` on the same line as the previous widget, with `desc` as a wrapped tooltip.

## `DummyVertical`

`Dummy(ImVec2(0, height))`.

## `SmallArrowButton`

`ArrowButtonEx(str_id, dir, size)`: an arrow button with an explicit size.

## `BeginWindow`

`Begin()` plus a workaround that restores a saved window position when the window is at specific default coordinates. The main menu uses it. For your own windows, plain `ImGui::Begin` is fine.
