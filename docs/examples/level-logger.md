# Level logger

Prints level loads and a per-level death count to the debug console. It has no UI.

**Uses:** OnPreLevelLoad, OnPostLevelLoad, OnPostDeath, GetLowercasedLevelName, Map_* macros

## `Client/addons/levellog.h`

```cpp
#pragma once

#include "../addon.h"

class LevelLogger : public Addon {
  public:
    bool Initialize() override;
    std::string GetName() override;
};
```

## `Client/addons/levellog.cpp`

```cpp
#include <cstdio>

#include "levellog.h"

#include "../engine.h"
#include "../imgui/imgui.h"
#include "../settings.h"
#include "../string_utils.h"
#include "../util.h" // needs imgui.h and settings.h first

static int Deaths = 0;

bool LevelLogger::Initialize() {
    Engine::OnPreLevelLoad([](const wchar_t *levelName) {
        printf("levellog: loading %ws\n", levelName);
    });

    Engine::OnPostLevelLoad([](const wchar_t *levelName) {
        const auto name = GetLowercasedLevelName(levelName);
        printf("levellog: loaded %s%s\n", name.c_str(),
               name == Map_MainMenu ? " (main menu)" : "");
        Deaths = 0;
    });

    Engine::OnPostDeath([]() { printf("levellog: death #%d on this level\n", ++Deaths); });

    return true;
}

std::string LevelLogger::GetName() { return "Level Logger"; }
```

## Add it to the build

1. Add `addons\levellog.h` (`ClInclude`) and `addons\levellog.cpp` (`ClCompile`) to `Client/Client.vcxproj`.
2. In `Client/main.cpp`, add `#include "addons/levellog.h"` and append `new LevelLogger()` to the `addons` array.
3. Build and run; see [Hello world](../getting-started/hello-world.md#2-add-the-files-to-the-project) for the details.

## Try it

1. Open **Engine tab > Debug Console**.
2. Load a chapter and die a few times. Lines prefixed `levellog:` appear in the console.

**See also:** [Reacting to level loads and death](../guides/reacting-to-levels-and-death.md) · [Debug](../api-reference/debug.md)
