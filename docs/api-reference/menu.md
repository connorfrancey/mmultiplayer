# Menu

**Header:** `Client/menu.h` · **Namespace:** `Menu`

The in-game menu: an ImGui window titled `MMultiplayer 2.5.2` with one tab per registered tab callback.

<!-- verify: skip (restates menu.h declarations; checked by signature check) -->
```cpp
typedef void (*MenuTabCallback)();
typedef void (*MenuCallback)(bool show);

typedef struct {
    std::string Name;
    MenuTabCallback Callback;
} MenuTab;
```

## `AddTab`

```cpp
void AddTab(const char *name, MenuTabCallback callback);
```

Appends a tab. While the menu is open and the tab is selected, `callback` runs every frame inside `ImGui::BeginTabItem(name)` / `EndTabItem()`.

| | |
|---|---|
| **Parameters** | `name`: the tab label, copied into a `std::string`. Two tabs with the same label collide in ImGui. `callback`: plain function or capture-less lambda. |
| **Order** | The built-in **Engine** and **World** tabs come first, then addon tabs in registration order. |
| **Lifecycle** | Call from `Addon::Initialize()`. There's no removal. |

<!-- verify: wrap() -->
```cpp
Menu::AddTab("My Tab", []() { ImGui::Text("Hi"); });
```

Guide: [Adding a menu tab](../guides/adding-a-menu-tab.md)

## `Show` / `Hide`

```cpp
void Show();
void Hide();
```

Open or close the menu. Each one calls `Engine::BlockInput(true/false)`, then every `OnVisibilityChange` callback with `true`/`false`.

The user toggles the menu with the key stored at settings path `{"Menu", "ShowKeybind"}` (default `VK_INSERT`, rebindable in the Engine tab). The menu opens on that key's **key-up**; it closes on the same key or **Escape**. `{"Menu", "ShowMenuAtStartup"}` (default `true`) opens it on the first rendered frame. Opening it at startup doesn't fire `OnVisibilityChange`.

## `OnVisibilityChange`

```cpp
void OnVisibilityChange(MenuCallback callback);
```

Registers `callback(show)` to run whenever `Show()` or `Hide()` is called. It doesn't fire for the automatic open at startup.

<!-- verify: wrap() -->
```cpp
Menu::OnVisibilityChange([](bool show) { /* pause or resume something */ });
```

## `Initialize`

```cpp
bool Initialize();
```

Framework-internal; `main.cpp` calls it once. It reads the menu settings, registers the render and input callbacks, and adds the Engine and World tabs. It always returns `true`.
