# Event spy

Records which UnrealScript functions run on the player pawn through `ProcessEvent`, with call counts. Use it to find out which events are interceptable before writing an `OnProcessEvent` hook.

**Uses:** OnProcessEvent, UObject::GetFullName, Menu::AddTab

## `Client/addons/eventspy.h`

```cpp
#pragma once

#include "../addon.h"

class EventSpy : public Addon {
  public:
    bool Initialize() override;
    std::string GetName() override;
};
```

## `Client/addons/eventspy.cpp`

```cpp
#include <map>
#include <string>

#include "eventspy.h"

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../menu.h"

static bool Recording = false;
static std::map<std::string, int> Seen;

static bool OnProcessEvent(Classes::UObject *object, Classes::UFunction *function, void *args,
                           void *result) {
    if (Recording && object && function && object == Engine::GetPlayerPawn()) {
        ++Seen[function->GetFullName()];
    }

    // false = let the event run normally.
    return false;
}

static void EventSpyTab() {
    ImGui::Checkbox("Record player pawn events", &Recording);
    ImGui::SameLine();
    if (ImGui::Button("Clear##eventspy-clear")) {
        Seen.clear();
    }

    ImGui::Separator(5.0f);

    for (const auto &[name, count] : Seen) {
        ImGui::Text("%6d  %s", count, name.c_str());
    }
}

bool EventSpy::Initialize() {
    Engine::OnProcessEvent(OnProcessEvent);
    Menu::AddTab("Event Spy", EventSpyTab);
    return true;
}

std::string EventSpy::GetName() { return "Event Spy"; }
```

## Add it to the build

1. Add `addons\eventspy.h` (`ClInclude`) and `addons\eventspy.cpp` (`ClCompile`) to `Client/Client.vcxproj`.
2. In `Client/main.cpp`, add `#include "addons/eventspy.h"` and append `new EventSpy()` to the `addons` array.
3. Build and run; see [Hello world](../getting-started/hello-world.md#2-add-the-files-to-the-project) for the details.

## Try it

1. Open the **Event Spy** tab and tick **Record player pawn events**.
2. Play for a few seconds, then reopen the menu to see the list.
3. Untick it when you're done. `GetFullName()` on every pawn event is expensive.

**See also:** [Intercepting script events](../guides/intercepting-events.md) · [The game SDK](../concepts/game-sdk.md)
