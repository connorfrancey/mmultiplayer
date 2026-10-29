# Mirror's Edge Multiplayer SDK

The **mmultiplayer SDK** is the C++ code you build on to write *addons*: features that run inside Mirror's Edge (2008, Unreal Engine 3) as part of the mmultiplayer client, `mmultiplayer.dll`. The multiplayer client, trainer, dolly camera, misc tweaks and chaos mode that ship with the mod are all addons written against this SDK.

It has two layers:

| Layer | Where | What you get |
|---|---|---|
| **Mod framework** | `Client/*.h` | An `Addon` base class, game callbacks (tick, render, input, level load, death, script events), cached access to the engine/world/player, an in-game ImGui menu, and JSON settings that persist between sessions. |
| **Generated game SDK** | `Client/sdk/` (its own CMake project), included through `ME_SDK.hpp` or `Client/sdk.h` | C++ declarations for roughly 2,500 of the game's UnrealScript classes, structs and enums in `namespace Classes`. You can read and write object fields and call script functions directly. |

## Who this is for

You're a modder who knows intermediate C++ and Visual Studio and wants to add features to the mmultiplayer client. These docs assume no prior Unreal Engine 3 or function-hooking knowledge.

## Key features

- **Callbacks** for every frame, every game tick, each actor tick, skeletal bone updates, key presses, level loads, player death, and every UnrealScript event (with the option to block it). See [Callbacks and threads](concepts/callbacks-and-threads.md).
- **Typed game access**, such as `Engine::GetPlayerPawn()->Velocity` or `controller->PlayerCamera->ColorScale`. See [The game SDK](concepts/game-sdk.md).
- **In-game UI** through Dear ImGui 1.90.2, plus mod-specific widgets such as a key-binding picker. See [Adding a menu tab](guides/adding-a-menu-tab.md).
- **Persistent settings** in `%APPDATA%\MMultiplayer\mmultiplayer-settings.json`. See [Persisting settings](guides/persisting-settings.md).
- **Character spawning**, console commands, and world-to-screen projection for overlays.

## Platform

Windows only, 32-bit only. You build with Visual Studio 2022 (toolset v143) and the DirectX SDK (June 2010). Mirror's Edge 1.0 is the target. See [Requirements](getting-started/requirements.md).

## Building these docs

The pages are plain Markdown and render on GitHub. To build an HTML site with Doxygen, configure the SDK's CMake project and build `me_sdk_docs`. See [Building the SDK with CMake](getting-started/building.md#building-the-sdk-with-cmake).

## Docs map

**Getting started**
- [Requirements](getting-started/requirements.md)
- [Building and running](getting-started/building.md)
- [Hello world: your first addon](getting-started/hello-world.md)

**Concepts**
- [Architecture](concepts/architecture.md): how the DLL gets into the game and starts up
- [Addon lifecycle](concepts/addon-lifecycle.md)
- [Callbacks and threads](concepts/callbacks-and-threads.md)
- [The game SDK](concepts/game-sdk.md): UE3 objects, classes, names, and script function calls
- [Object accessors](concepts/object-accessors.md): `GetWorld`, `GetPlayerPawn` and their caching

**Guides**
- [Adding a menu tab](guides/adding-a-menu-tab.md)
- [Persisting settings](guides/persisting-settings.md)
- [Reading and changing player state](guides/reading-player-state.md)
- [Handling input and hotkeys](guides/handling-input.md)
- [Drawing overlays](guides/drawing-overlays.md)
- [Reacting to level loads and death](guides/reacting-to-levels-and-death.md)
- [Running console commands](guides/console-commands.md)
- [Spawning characters](guides/spawning-characters.md)
- [Intercepting script events](guides/intercepting-events.md)
- [Finding game classes and functions](guides/finding-game-classes.md)

**Reference**
- [API reference index](api-reference/index.md)
- [Examples](examples/index.md)
- [Troubleshooting](troubleshooting.md)
- [FAQ](faq.md)
- [Changelog and migration notes](changelog.md)
