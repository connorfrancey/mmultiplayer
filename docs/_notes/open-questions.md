# Open questions

Every `<!-- TODO: verify -->` in the docs maps to one of these. Most need either a maintainer's knowledge or an in-game test with an MSVC build. Neither was possible here (Linux, no game).

## Need maintainer input

1. **Scope and plugin story.** Is a third-party addon expected to fork the repo, or is a plugin mechanism planned? (`faq.md`)
2. **SDK provenance.** Which generator produced `Client/sdk/`? Can it be regenerated, and how are the hand edits tracked? (`concepts/game-sdk.md`)
3. **C++ standard.** Is Debug = C++20 / Release = C++17 intentional? Should addon code target C++17? (`getting-started/requirements.md`)
4. **Supported game builds.** Which store versions of `MirrorsEdge.exe` do the byte patterns match (Steam, EA App/Origin, GOG)? (`getting-started/requirements.md`)
5. **Input `msg` reference.** Is modifying `msg` in an `InputCallback` (to swallow or rewrite a message) a supported use? (`concepts/callbacks-and-threads.md`, `api-reference/engine-callbacks.md`)
6. **Is `OnProcessEvent` public API?** None of the built-in addons use it.

## Need an in-game test (MSVC build)

7. **Thread model.** Do `EndScene` (`OnRenderScene`) and the message pump (`OnInput`) run on the same thread as the engine tick? This decides the thread-safety guidance. (`concepts/callbacks-and-threads.md`, `api-reference/engine-accessors.md`)
8. **`OnTick` `delta` units.** Seconds? (`concepts/callbacks-and-threads.md`, `api-reference/engine-callbacks.md`)
9. **Death hooks.** Which routine do the PreDeath/PostDeath patterns hook? Do they fire on checkpoint reloads? Are spawned characters destroyed on death? (`guides/reacting-to-levels-and-death.md`, `api-reference/engine-callbacks.md`, `guides/spawning-characters.md`)
10. **ProcessEvent coverage.** Is `TdPlayerPawn.TakeDamage` (or any script-to-script call) routed through `ProcessEvent`? Run the Event spy example to find out. (`guides/intercepting-events.md`)
11. **Console commands.** Does `open <map>` work through `ExecuteCommand`? Which other commands are honoured? (`guides/console-commands.md`)
12. **Direct field writes.** Which direct writes are safe (`Location`, `Rotation`, `Velocity`) and which need `SetLocation` and friends? (`concepts/game-sdk.md`)
13. **`world->Game` nullness.** Can `Game` be null while `GetWorld()` is non-null? (`api-reference/engine-accessors.md`)
14. **Debug console close button.** Does closing the console window with **X** still end the game? (`api-reference/debug.md`)
15. **Run all examples in-game.** (`examples/index.md`)

## Need a Windows build machine

16. Does `MSBuild Client.vcxproj -property:Platform=x86` build, given that the project only declares `Win32`? (`getting-started/building.md`)
17. Does the launcher normally need administrator rights? (`getting-started/building.md`)
18. Which Visual Studio version do maintainers build with? `.vscode/tasks.json` points at VS 18 Build Tools, but the project pins toolset v143. (`getting-started/building.md`)
