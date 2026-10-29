# Drawing overlays

Everything on screen is drawn with ImGui inside an [`Engine::OnRenderScene`](../api-reference/engine-callbacks.md#onrenderscene) callback. It runs every frame, whether or not the menu is open.

## Free-form drawing with a raw scene

`ImGui::BeginRawScene(name)` opens a borderless, transparent, unmovable window that covers the whole display, and returns its `ImGuiWindow *`. Draw with that window's `DrawList`, then call `ImGui::EndRawScene()`:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"

static void OnRender(IDirect3DDevice9 *device) {
    const auto pawn = Engine::GetPlayerPawn();
    if (!pawn) {
        return;
    }

    auto window = ImGui::BeginRawScene("##myaddon-overlay");
    const auto size = ImGui::GetIO().DisplaySize;

    // Crosshair dot
    window->DrawList->AddCircleFilled(ImVec2(size.x / 2, size.y / 2), 3.0f, IM_COL32_WHITE);

    ImGui::EndRawScene();
}

// In Initialize():  Engine::OnRenderScene(OnRender);
```

- Give each raw scene a unique name starting with `##`, so it has no visible title.
- `BeginRawScene(name, true)` lets ImGui save the window's settings to `imgui.ini`. The default is `false`.
- Always pair it with `EndRawScene()`. It pops the clip rect, window, colour and style vars that `BeginRawScene` pushed.

The Misc addon's **Tunnel Vision** is a complete example (`Client/addons/misc.cpp`, `OnRender`).

## Labels at world positions

[`Engine::WorldToScreen`](../api-reference/engine-utilities.md#worldtoscreen) converts a world location to screen pixels **in place**:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"

static Classes::FVector Marker = {0, 0, 0};

static void OnRender(IDirect3DDevice9 *device) {
    auto pos = Marker;  // copy: WorldToScreen overwrites its argument
    if (!Engine::WorldToScreen(device, pos)) {
        return;  // behind the camera, or no controller/projection yet
    }

    auto window = ImGui::BeginRawScene("##myaddon-marker");
    window->DrawList->AddText(ImVec2(pos.X, pos.Y), IM_COL32_WHITE, "Marker");
    ImGui::EndRawScene();
}
```

After the call, `pos.X` and `pos.Y` are pixel coordinates and `pos.Z` is the clip-space `w` (a depth value). The function returns `false` when the point is behind the camera, when there's no player controller, or before the projection hook has run once. The multiplayer client (`client.cpp`) and the Dolly addon (`dolly.cpp`) both use it to draw world-anchored overlays.

## Floating windows

For a movable panel, such as the trainer's speedometer, use a normal ImGui window inside `OnRenderScene`:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"

static bool ShowPanel = true;

static void OnRender(IDirect3DDevice9 *device) {
    if (!ShowPanel) {
        return;
    }

    ImGui::SetNextWindowPos(ImVec2(60, 60), ImGuiCond_FirstUseEver);
    ImGui::Begin("My Panel##myaddon-panel", &ShowPanel, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Text("Hello");
    ImGui::End();
}
```

The game still has the mouse while the menu is closed, so you can't click a floating window until you open the menu (which calls `BlockInput(true)`).

Example: [Speed HUD](../examples/speed-hud.md)
