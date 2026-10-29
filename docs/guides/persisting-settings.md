# Persisting settings

[`Settings`](../api-reference/settings.md) stores one JSON document for the whole mod at:

```
%APPDATA%\MMultiplayer\mmultiplayer-settings.json
```

You address values by a **key path**, a list of nested object keys. By convention the first key is your addon's name:

```json
{
  "Menu": { "ShowKeybind": 45, "ShowMenuAtStartup": true },
  "Misc": { "Enabled": false, "TunnelVision": { "Enabled": false, "Width": 128.0 } }
}
```

The type is `json`, an alias for `nlohmann::ordered_json` (nlohmann/json 3.11.2), so keys keep their insertion order.

## Read at startup, write on change

```cpp
#include "../engine.h"   // pulls in <Windows.h> for VK_F8; settings.h does not
#include "../settings.h"

static bool Enabled = false;
static float Size = 128.0f;
static int Key = VK_F8;

static void LoadMySettings() {
    Enabled = Settings::GetSetting({"MyAddon", "Enabled"}, false);
    Size = Settings::GetSetting({"MyAddon", "Overlay", "Size"}, 128.0f);
    Key = Settings::GetSetting({"MyAddon", "Key"}, VK_F8);
}

static void SaveEnabled() {
    Settings::SetSetting({"MyAddon", "Enabled"}, Enabled);
}
```

- `GetSetting(path, default)` returns the stored value. **If the path doesn't exist, it writes `default` there.** The returned `json` converts implicitly to `bool`, `int`, `float` or `std::string`. If the stored type doesn't match, nlohmann throws `json::type_error`. To avoid that, use `.get<T>()` after checking `.is_number()` and similar.
- `SetSetting(path, value)` creates any missing intermediate objects and overwrites the leaf.

## Both functions write the file every time

`GetSetting` and `SetSetting` **both rewrite the settings file on every call**. That includes `GetSetting` when the key already exists. Follow these rules:

- Call `GetSetting` once per value in `Initialize()`, not every frame.
- Call `SetSetting` only when a value actually changes, for example inside `if (ImGui::Checkbox(...))`. For text and number fields, the built-in addons pass `ImGuiInputTextFlags_EnterReturnsTrue` so they save on Enter rather than on every keystroke.

## Storing structs

`util.h` has converters for ImGui colours and vectors:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"
#include "../settings.h"
#include "../util.h" // needs imgui.h and settings.h included first

static Classes::FVector Scale = {1.0f, 1.0f, 1.0f};

static void LoadScale() {
    Scale = JsonToFVector(
        Settings::GetSetting({"MyAddon", "Scale"}, FVectorToJson(Classes::FVector{1, 1, 1})));
}
```

`FVectorToJson` stores X/Y/Z under the keys `"R"`, `"G"` and `"B"`, because it was written for colour scales. Expect those keys in the file.

## Load, reset, failure

- `Settings::Load()` runs once at startup, before addons are constructed. If the file is missing or isn't valid JSON, the settings are **reset to `{}`** and saved, which loses the old contents.
- `Settings::Reset()` clears everything and saves.
- If the file can't be written, `Save()` prints `settings: failed to save <path>` to stdout. You'll only see it if the [debug console](../api-reference/debug.md) is open.

Before 2.2.0 the API took exactly two keys, `GetSetting(sub, key, default)`. Key paths replaced it, and older settings files aren't compatible. See [Changelog and migration notes](../changelog.md).
