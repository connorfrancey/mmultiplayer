# Helpers

## `util.h`

**Header:** `Client/util.h`

`util.h` **isn't self-contained**. It uses `Classes::FVector`, `json` and `ImVec4` without including their headers. Include `engine.h`, `imgui/imgui.h` and `settings.h` first:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"
#include "../settings.h"
#include "../util.h"
```

Everything here is `static` or a macro, so each file that includes it gets its own copy.

### Virtual-key macros

`VK_NONE` (0x0), `VK_0`–`VK_9` (0x30–0x39) and `VK_A`–`VK_Z` (0x41–0x5A). These are the codes `<WinUser.h>` leaves unnamed. Function and navigation keys (`VK_F1`, `VK_INSERT`, `VK_SPACE`, ...) come from Windows.

### Map-name macros

Lower-case level names for comparison with `GetLowercasedLevelName(levelName)`:

`Map_MainMenu` `"tdmainmenu"` · `Map_Prologue` `"edge_p"` · `Map_Flight` `"escape_p"` · `Map_Jacknife` `"stromdrain_p"` · `Map_Heat` `"cranes_p"` · `Map_Ropeburn` `"subway_p"` · `Map_NewEden` `"mall_p"` · `Map_Factory` `"factory_p"` · `Map_TheBoat` `"boat_p"` · `Map_Kate` `"convoy_p"` · `Map_TheShard` `"scraper_p"`

`GameMode_None` `""` and `GameMode_Tag` `"tag"` are used by the multiplayer client.

### `Distance`

```cpp
static float Distance(const Classes::FVector &from, const Classes::FVector &to);
```

The Euclidean distance **in metres**: the Unreal-unit distance divided by 100.

### `PressKey` / `ReleaseKey`

```cpp
static void PressKey(int keyCode);
static void ReleaseKey();
```

Synthesise a key press and release through `SendInput`. `ReleaseKey` releases whatever key the last `PressKey` *in the same file* pressed: both use a file-static `INPUT` struct.

### JSON converters

```cpp
static json ImVec4ToJson(const ImVec4 &v);           // {"R","G","B","A"}
static ImVec4 JsonToImVec4(const json &j);
static json FVectorToJson(const Classes::FVector &v); // X,Y,Z stored as {"R","G","B"}
static Classes::FVector JsonToFVector(const json &j);
```

The `JsonTo*` functions use `j.at(...)`, so a missing key throws `json::out_of_range`.

## `string_utils.h`

**Header:** `Client/string_utils.h`. Self-contained apart from `<Windows.h>` types (include `engine.h` first or `<Windows.h>`).

```cpp
static std::wstring ConvertUtf8ToWideString(const std::string_view utf8String);
static std::string ConvertWideStringToString(std::wstring_view wideString);
static std::string GetLowercasedLevelName(std::wstring_view UppercasedLevelName);
```

- Each conversion uses `MultiByteToWideChar` or `WideCharToMultiByte` and returns an empty string on failure. The input **must be null-terminated**: the functions pass `-1` as the length, so a `string_view` into the middle of a buffer reads past its end.
- `GetLowercasedLevelName` converts to UTF-8 and lower-cases it, for comparison with the `Map_*` macros.

```cpp
#include "../engine.h"
#include "../string_utils.h"

static void OnPostLevelLoad(const wchar_t *levelName) {
    const std::string level = GetLowercasedLevelName(levelName);
}
```
