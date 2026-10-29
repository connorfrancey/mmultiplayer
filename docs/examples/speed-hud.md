# Speed HUD

Draws your horizontal speed in m/s at the bottom of the screen, with an on/off toggle in its own menu tab that persists between sessions.

**Uses:** OnRenderScene, BeginRawScene, Settings, Menu::AddTab

## `Client/addons/speedhud.h`

```cpp
#pragma once

#include "../addon.h"

class SpeedHud : public Addon {
  public:
    bool Initialize() override;
    std::string GetName() override;
};
```

## `Client/addons/speedhud.cpp`

```cpp
#include <cmath>

#include "speedhud.h"

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../menu.h"
#include "../settings.h"

static bool Enabled = false;

static void SpeedHudTab() {
    if (ImGui::Checkbox("Show speed overlay", &Enabled)) {
        Settings::SetSetting({"SpeedHud", "Enabled"}, Enabled);
    }
}

static void OnRender(IDirect3DDevice9 *device) {
    if (!Enabled) {
        return;
    }

    const auto pawn = Engine::GetPlayerPawn();
    if (!pawn) {
        return;
    }

    // Horizontal speed, same formula as the trainer's speedometer.
    // Unreal units are centimetres, so divide by 100 for m/s.
    const float speed =
        sqrtf(pawn->Velocity.X * pawn->Velocity.X + pawn->Velocity.Y * pawn->Velocity.Y);

    auto window = ImGui::BeginRawScene("##speedhud");
    const auto size = ImGui::GetIO().DisplaySize;

    char text[32];
    snprintf(text, sizeof(text), "%.1f m/s", speed / 100.0f);
    window->DrawList->AddText(ImVec2(size.x / 2 - 30, size.y - 80), IM_COL32_WHITE, text);

    ImGui::EndRawScene();
}

bool SpeedHud::Initialize() {
    Enabled = Settings::GetSetting({"SpeedHud", "Enabled"}, false);

    Menu::AddTab("Speed HUD", SpeedHudTab);
    Engine::OnRenderScene(OnRender);
    return true;
}

std::string SpeedHud::GetName() { return "Speed HUD"; }
```

## Add it to the build

1. Add `addons\speedhud.h` (`ClInclude`) and `addons\speedhud.cpp` (`ClCompile`) to `Client/Client.vcxproj`.
2. In `Client/main.cpp`, add `#include "addons/speedhud.h"` and append `new SpeedHud()` to the `addons` array.
3. Build and run; see [Hello world](../getting-started/hello-world.md#2-add-the-files-to-the-project) for the details.

## Try it

1. Load a level and enable **Show speed overlay** in the **Speed HUD** tab.
2. Start running. The number at the bottom centre changes with your speed.
3. Restart the game. The toggle keeps its state.

**See also:** [Drawing overlays](../guides/drawing-overlays.md) · [Persisting settings](../guides/persisting-settings.md) · [Reading player state](../guides/reading-player-state.md)
