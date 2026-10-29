# Hotkey command

Binds a key (default F8) to a console command. You pick both in the menu.

**Uses:** ImGui::Hotkey, OnInput, ExecuteCommand, Settings

## `Client/addons/hotkeycmd.h`

```cpp
#pragma once

#include "../addon.h"

class HotkeyCommand : public Addon {
  public:
    bool Initialize() override;
    std::string GetName() override;
};
```

## `Client/addons/hotkeycmd.cpp`

```cpp
#include <string>

#include "hotkeycmd.h"

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../menu.h"
#include "../settings.h"
#include "../string_utils.h"

static int Key = VK_F8;
static char Command[256] = {0};

static void HotkeyCommandTab() {
    if (ImGui::Hotkey("Key##hotkeycmd-key", &Key)) {
        Settings::SetSetting({"HotkeyCommand", "Key"}, Key);
    }

    if (ImGui::InputText("Command##hotkeycmd-command", Command, sizeof(Command))) {
        Settings::SetSetting({"HotkeyCommand", "Command"}, std::string(Command));
    }
}

static void OnInput(unsigned int &msg, int keycode) {
    if (msg != WM_KEYDOWN || keycode != Key || !Command[0]) {
        return;
    }

    // Queued; runs on the next game tick.
    Engine::ExecuteCommand(ConvertUtf8ToWideString(Command).c_str());
}

bool HotkeyCommand::Initialize() {
    Key = Settings::GetSetting({"HotkeyCommand", "Key"}, VK_F8);

    const std::string saved = Settings::GetSetting({"HotkeyCommand", "Command"}, "");
    strncpy_s(Command, saved.c_str(), sizeof(Command) - 1);

    Menu::AddTab("Hotkey Command", HotkeyCommandTab);
    Engine::OnInput(OnInput);
    return true;
}

std::string HotkeyCommand::GetName() { return "Hotkey Command"; }
```

## Add it to the build

1. Add `addons\hotkeycmd.h` (`ClInclude`) and `addons\hotkeycmd.cpp` (`ClCompile`) to `Client/Client.vcxproj`.
2. In `Client/main.cpp`, add `#include "addons/hotkeycmd.h"` and append `new HotkeyCommand()` to the `addons` array.
3. Build and run; see [Hello world](../getting-started/hello-world.md#2-add-the-files-to-the-project) for the details.

## Try it

1. Open the **Hotkey Command** tab, type a command, and optionally rebind the key.
2. Close the menu and press the key in a level. The command runs on the next tick.

**See also:** [Handling input](../guides/handling-input.md) · [Running console commands](../guides/console-commands.md)
