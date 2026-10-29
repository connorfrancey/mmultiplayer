# FAQ

**Can I ship my addon as a separate DLL, without forking?**
Not with the current code. There's no plugin loader: addons are compiled into `mmultiplayer.dll` and listed in `Client/main.cpp`. <!-- TODO: verify whether a plugin mechanism is planned -->

**Can I reload my addon without restarting the game?**
No. The framework never unhooks or unloads. See [Iterating](getting-started/building.md#iterating).

**Can I use a capturing lambda as a callback?**
No. Callbacks are raw function pointers. Keep state in file-scope `static`s, as every built-in addon does.

**Can I unregister a callback?**
No. Register once in `Initialize()` and gate it with a flag.

**Is it 64-bit?**
No. The game is 32-bit, and so is the DLL.

**C++17 or C++20?**
Write C++17. Release, the configuration `build.sh` uses, compiles as C++17; Debug uses C++20.

**What units do positions and speeds use?**
Unreal units, where 100 units = 1 metre (`Distance()` in `util.h`). Velocity is in units per second. Rotators use 65536 units per full turn.

**Where are settings stored?**
`%APPDATA%\MMultiplayer\mmultiplayer-settings.json`. Older versions stored it elsewhere; see [Changelog](changelog.md).

**How do I find the class or field for something in the game?**
See [Finding game classes and functions](guides/finding-game-classes.md). Searching `Client/sdk/ME_TdGame_classes.hpp` is usually the fastest route.

**Can I call any UnrealScript function?**
Any function the SDK declares can be called through its wrapper. It's executed through `ProcessEvent`, with the Native flag set temporarily. Whether calling it at an arbitrary moment is *safe* depends on the function. Prefer calling from `OnTick`. See [The game SDK](concepts/game-sdk.md#calling-script-functions).

**Does the multiplayer server matter for addon development?**
No. `Server/` (Go) is only used by the multiplayer `Client` addon.
