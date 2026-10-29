# Examples

Complete addons that you can drop into `Client/addons/`. Each one is a header and a source file, registered like the [Hello world](../getting-started/hello-world.md) addon.

| Example | Shows |
|---|---|
| [Hello tab](../getting-started/hello-world.md) | The minimum addon: a menu tab that reads the player's position |
| [Speed HUD](speed-hud.md) | A screen overlay, a persisted toggle |
| [Hotkey command](hotkey-command.md) | A bindable key, console commands, string settings |
| [Level logger](level-logger.md) | Level-load and death callbacks, debug-console output |
| [Event spy](event-spy.md) | `OnProcessEvent`, discovering script events |

## How these were verified

Every example was **type-checked against the real headers** in this repository. It was compiled with `-fsyntax-only` as if it sat in `Client/addons/`, using MinGW GCC (`i686-w64-mingw32-g++ -std=c++17`). The edited `main.cpp` registration was checked the same way. That catches wrong names, signatures, field names and types.

The examples have **not** been built with MSVC, linked into `mmultiplayer.dll`, or run in the game. <!-- TODO: verify each example in-game with an MSVC build -->

More real-world code: the built-in addons in `Client/addons/`. `misc.cpp` is the smallest and the easiest to follow.
