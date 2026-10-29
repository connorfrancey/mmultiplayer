# Handling input and hotkeys

The framework watches the game window's keyboard messages and gives you three tools:

| API | Use |
|---|---|
| [`Engine::OnInput`](../api-reference/engine-callbacks.md#oninput) | React to key down/up while the game has input (menu closed) |
| [`Engine::OnSuperInput`](../api-reference/engine-callbacks.md#onsuperinput) | React to keys even while the menu or chat has blocked input |
| [`Engine::IsKeyDown`](../api-reference/engine-utilities.md#iskeydown) | Poll whether a key is currently held (always `false` while input is blocked) |

## A bindable hotkey

Store the key as a Win32 virtual-key code, let the user rebind it with `ImGui::Hotkey`, and compare it in `OnInput`:

```cpp
#include "../engine.h"
#include "../imgui/imgui.h"
#include "../settings.h"

static int ToggleKey = VK_F8;
static bool Active = false;

static void MyTab() {
    if (ImGui::Hotkey("Toggle##myaddon-toggle", &ToggleKey)) {
        Settings::SetSetting({"MyAddon", "ToggleKey"}, ToggleKey);
    }
}

static void OnInput(unsigned int &msg, int keycode) {
    if (msg == WM_KEYDOWN && keycode == ToggleKey) {
        Active = !Active;
    }
}

// In Initialize():
//     ToggleKey = Settings::GetSetting({"MyAddon", "ToggleKey"}, VK_F8);
//     Engine::OnInput(OnInput);
```

`ImGui::Hotkey` behaviour:

- Clicking the field puts it in "<Press a key>" mode. The next mouse button or key between `VK_BACK` and `VK_RMENU` becomes the binding, and the function returns `true`.
- **Escape** clears the binding to `0` (shown as "None"). Because Escape also closes the menu, the menu closes at the same moment.
- Out-of-range values are clamped to `0`.

`keycode == 0` never arrives as a key, so a binding of `0` disables the hotkey without any extra check.

`util.h` defines `VK_0` to `VK_9` and `VK_A` to `VK_Z` for readability, plus `VK_NONE` (0). Windows already provides `VK_F1`, `VK_INSERT` and the rest.

## Taking keyboard focus yourself

The multiplayer chat captures typing by blocking input and listening with `OnSuperInput`:

```cpp
#include "../engine.h"

static bool Typing = false;

static void OnSuperInput(unsigned int &msg, int keycode) {
    if (Typing && msg == WM_KEYUP && (keycode == VK_RETURN || keycode == VK_ESCAPE)) {
        Typing = false;
        Engine::BlockInput(false);
    }
}

static void StartTyping() {
    Typing = true;
    Engine::BlockInput(true);
}
```

While input is blocked, the game stops receiving keyboard and mouse messages. ImGui gets them instead and draws a mouse cursor. `Menu::Show()` and `Menu::Hide()` call `BlockInput` themselves, so if you block input while the menu is open, closing the menu unblocks it.

## Gotchas

- Only state **transitions** are delivered. Holding a key gives one `WM_KEYDOWN` and later one `WM_KEYUP`. For continuous actions, set a flag in `OnInput` or poll `IsKeyDown` in `OnTick`.
- The menu toggles on `WM_KEYUP` of its key (default **Insert**). Avoid binding your own action to the same key.
- `Hotkey` accepts mouse buttons (`VK_LBUTTON`, `VK_XBUTTON1`, ...), but **neither `OnInput` nor `IsKeyDown` sees mouse buttons**; the framework only tracks keyboard messages. A mouse binding never fires through the framework, and that includes the built-in addons' bindings. To support mouse buttons, poll `GetAsyncKeyState(key) & 0x8000` yourself. The Dolly addon uses that call to check the Ctrl modifier.

Example: [Hotkey command](../examples/hotkey-command.md)
