# Documentation outline

**Audience:** modders writing addons for the mmultiplayer client (`mmultiplayer.dll`).
**Skill level:** intermediate C++ (pointers, lambdas, function pointers, Visual Studio), comfortable reading game-engine class hierarchies. No prior UE3 or hooking knowledge assumed.
**Scope:** the addon framework (`Engine`, `Menu`, `Settings`, `Addon`, helpers) plus how to use the generated game SDK (`Client/sdk/`). The generated classes aren't documented one by one (~2,500 classes); the reference explains how to read them and covers the handful the framework hands you. Hook/Pattern internals appear only where they explain behaviour.
**Tooling:** none exists in the repo, so this is plain Markdown with Mermaid diagrams (renders on GitHub).

```
docs/
├── index.md                      What it is, who it's for, features, docs map
├── getting-started/
│   ├── requirements.md           Windows, VS 2022 v143, DirectX SDK June 2010, 32-bit, game version
│   ├── building.md               Clone, build.sh / VS Code task / Visual Studio, outputs, running via Launcher
│   └── hello-world.md            Minimal addon: class, register in main.cpp + vcxproj, menu tab, build, see it in game
├── concepts/
│   ├── architecture.md           Launcher → DLL injection → InitThread sequence; layers diagram
│   ├── addon-lifecycle.md        Construction, Initialize(), registration-only-at-init, no teardown
│   ├── callbacks-and-threads.md  Each hook: when it fires, order, ordering vs. queues, what's safe where
│   ├── game-sdk.md               UE3 object model: UObject/UClass, GObjects/GNames, StaticClass, IsA, casting,
│   │                             FName/FString/TArray, function wrappers via ProcessEvent, STATIC_, Params structs
│   └── object-accessors.md       Cached accessors, update flag, nullptr during loads
├── guides/
│   ├── adding-a-menu-tab.md      ImGui in a tab, project ImGui extensions, persisting settings
│   ├── persisting-settings.md    Key paths, defaults, save-on-every-call caveat, JSON helpers
│   ├── reading-player-state.md   Pawn/controller fields, movement state, per-tick logic, null checks
│   ├── handling-input.md         OnInput vs OnSuperInput, BlockInput, IsKeyDown, Hotkey widget
│   ├── drawing-overlays.md       OnRenderScene, BeginRawScene, WorldToScreen
│   ├── reacting-to-levels-and-death.md   Pre/Post level load & death, level-name macros
│   ├── console-commands.md       ExecuteCommand queue
│   ├── spawning-characters.md    SpawnCharacter/Despawn/TransformBones, pointer-reference contract
│   ├── intercepting-events.md    OnProcessEvent, filtering by UFunction, swallowing events
│   └── finding-game-classes.md   Navigating the generated headers, FindObject/FindClass, debugging
├── api-reference/
│   ├── index.md
│   ├── addon.md                  Addon
│   ├── engine-accessors.md       GetEngine … GetLevelRace, GetWindow
│   ├── engine-callbacks.md       On* functions + callback typedefs
│   ├── engine-utilities.md       ExecuteCommand, BlockInput, IsKeyDown, WorldToScreen, Spawn/Despawn/TransformBones, Character
│   ├── menu.md                   Menu namespace + MenuTab
│   ├── settings.md               Settings namespace
│   ├── debug.md                  Debug namespace + crash handler
│   ├── imgui-extensions.md       imgui_mmultiplayer.h
│   ├── helpers.md                util.h, string_utils.h
│   └── sdk-basics.md             ME_Basic.hpp types + UObject core members
├── examples/
│   ├── index.md
│   ├── hello-tab.md              (from hello-world)
│   ├── speed-hud.md              Overlay showing player speed, persisted toggle
│   ├── hotkey-command.md         Bindable key that runs a console command
│   └── level-logger.md           Logs level loads/deaths to the debug console
├── troubleshooting.md            Startup message boxes, pattern-scan failures, crashes, nullptr accessors, build errors
├── faq.md
└── changelog.md                  Link to CHANGELOG + API-relevant changes / migration notes (2.2.0 settings format, 2.3.x settings path)
```

**Example verification:** every snippet that compiles standalone is syntax-checked against the real headers (MinGW, see `exploration.md`). Fragments get wrapped in a harness for checking.
