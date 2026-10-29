# Changelog and migration notes

The project changelog is [`CHANGELOG.md`](../CHANGELOG.md) (Keep a Changelog format, semantic versioning). The current version is **2.5.2**. This page pulls out the changes that affect addon authors.

## 2.5.x

- **2.5.2**: fixed a performance regression when Softimer isn't active. The Softimer class lookup is now cached and reset on each level load.
- **2.5.1**: Softimer handling moved out of the generated SDK and into `engine.cpp`. `GetWorld`/`GetPlayerController` now accept Softimer's player controller. If you edited `Client/sdk/` around `TdPlayerController`, re-check your changes.
- **2.5.0 to 2.5.1**: Direct3D hooking was reworked to support ReShade, DXVK and other D3D9 wrappers (commits `aec600b`, `f5ef5a1`). The current code hooks `Direct3DCreate9` → `CreateDevice` → device vtable, with a probe-device fallback. **Migration:** none for addons; `OnRenderScene` is unchanged.

## 2.4.0

- x64 configurations were removed. Build Win32/x86 only.
- Internal code cleanup.

## 2.3.x: settings file location

| Version | Settings file |
|---|---|
| ≤ 2.2.x | `mmultiplayer.settings`, in a temp folder |
| 2.3.0 | `mmultiplayer-settings.json`, next to the game's exe |
| 2.3.1 | `%userprofile%\Documents\EA Games\Mirror's Edge\mmultiplayer-settings.json` |
| ≥ 2.3.2 | `%APPDATA%\MMultiplayer\mmultiplayer-settings.json` |

Files aren't migrated automatically. Users who upgrade start with defaults unless they copy the file across.

## 2.2.0: Settings API change (breaking)

The settings API moved from a fixed two-level `(sub, key)` lookup to arbitrary key paths:

<!-- verify: skip (old and new declarations side by side) -->
```cpp
// Before 2.2.0
json GetSetting(const char *sub, const char *key, json defaultValue);
void SetSetting(const char *sub, const char *key, json value);

// 2.2.0 and later
json GetSetting(const std::vector<std::string> &keys, const json &defaultValue);
void SetSetting(const std::vector<std::string> &keys, const json &value);
```

**Migration:** replace `GetSetting("MyAddon", "Enabled", false)` with `GetSetting({"MyAddon", "Enabled"}, false)`. The changelog notes that old settings files aren't compatible.

Also in 2.2.0: Dear ImGui went from 1.73 to 1.90.2, and nlohmann/json from 3.7.3 to 3.11.2. ImGui code from before 2.2.0 may need updating for API changes in 1.90; see the ImGui changelog.
