# Settings

**Header:** `Client/settings.h` · **Namespace:** `Settings`

Process-wide JSON settings, persisted to `%APPDATA%\MMultiplayer\mmultiplayer-settings.json`. The directory is created on first use. `json` is `nlohmann::ordered_json` (nlohmann/json 3.11.2, `Client/json.h`).

`settings.h` includes only `json.h`. Include `engine.h` or `<Windows.h>` yourself if you need `VK_*` codes.

**Thread:** no locking. Every call reads or writes one shared `json` object and the file. Call from one context at a time, normally `Initialize()` and UI callbacks.

## `GetSetting`

```cpp
json GetSetting(const std::vector<std::string> &keys, const json &defaultValue);
```

Returns the value at the key path `keys`.

| | |
|---|---|
| **Parameters** | `keys`: path of nested object keys, for example `{"MyAddon", "Overlay", "Size"}`. `defaultValue`: stored and returned if the path is missing. |
| **Returns** | A **copy** of the stored value. It converts implicitly to the target type (`bool`, `int`, `float`, `std::string`, ...). |
| **Side effects** | Creates missing objects along the path, stores `defaultValue` at the leaf if it's missing, and **saves the file on every call**. |
| **Errors** | If an intermediate key holds a non-object (for example, a number where an object is expected), nlohmann throws. Converting to a mismatched type also throws `json::type_error`. |

<!-- verify: wrap() -->
```cpp
const bool enabled = Settings::GetSetting({"MyAddon", "Enabled"}, false);
const std::string name = Settings::GetSetting({"MyAddon", "Name"}, "Faith");
```

## `SetSetting`

```cpp
void SetSetting(const std::vector<std::string> &keys, const json &value);
```

Stores `value` at `keys`, creating intermediate objects, then **saves the file**. Call it on change, not every frame.

<!-- verify: wrap() -->
```cpp
Settings::SetSetting({"MyAddon", "Enabled"}, true);
```

## `Load`

```cpp
void Load();
```

Framework-internal; `main.cpp` calls it once, before addons are constructed. It parses the file. If the file is missing or fails with `json::parse_error`, it calls `Reset()`, **discarding the old file's contents**.

## `Reset`

```cpp
void Reset();
```

Replaces all settings with `{}` and saves. In-memory addon state isn't reloaded.

## `Save`

```cpp
void Save();
```

Writes the whole document. On failure it prints `settings: failed to save <path>` to stdout, which is visible in the [debug console](debug.md). There's no other error reporting.

Guide: [Persisting settings](../guides/persisting-settings.md)
