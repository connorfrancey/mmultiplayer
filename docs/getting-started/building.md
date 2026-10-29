# Building and running

## Repository layout

```
Client/          mmultiplayer.dll: framework, addons, generated SDK
  addons/        built-in addons (client, trainer, dolly, misc, chaos/)
  imgui/         Dear ImGui 1.90.2 + project extensions
  sdk/           generated Mirror's Edge SDK (ME_<Package>_*.hpp/.cpp)
  main.cpp       DLL entry point; the list of addons lives here
Launcher/        Launcher.exe: injects mmultiplayer.dll into the game
Server/          multiplayer server (Go); not needed for addon work
resources/       installer sources
build.sh         builds Client and Launcher into Release/
package.sh       builds the installer
```

## Get the source

```bash
git clone https://github.com/softsoundd/mmultiplayer.git
cd mmultiplayer
```

## Build

Pick one of these options. Each one produces `Release/mmultiplayer.dll` and `Release/Launcher.exe`.

**Option A: `build.sh` (Git Bash).** You need `MSBuild.exe` on your `PATH`.

```bash
./build.sh
```

This runs:

```bash
MSBuild.exe Client/Client.vcxproj -property:Configuration=Release -property:Platform=x86 -property:OutDir=../Release/ -t:Build
MSBuild.exe Launcher/Launcher.vcxproj -property:Configuration=Release -property:Platform=x86 -property:OutDir=../Release/ -t:Build
```

<!-- TODO: verify — Client.vcxproj only declares the Win32 platform; confirm MSBuild accepts Platform=x86 here -->

**Option B: VS Code.** Run the **Client Build** and **Launcher Build** tasks from `.vscode/tasks.json`. The tasks put MSBuild from `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\MSBuild\Current\Bin` on the `PATH`. That path is for Visual Studio **18** Build Tools, while the project asks for toolset **v143** (the Visual Studio 2022 toolset). Make sure v143 is installed in whichever Visual Studio you use, and edit the path if your MSBuild lives elsewhere. <!-- TODO: verify which Visual Studio version maintainers build with -->

**Option C: Visual Studio.** Open `Client/Client.sln`, choose **Release | x86** or **Debug | x86**, and build. The solution's `x86` maps to the project's `Win32` configuration. No `OutDir` is set in the project, so the IDE uses Visual Studio's default (`$(SolutionDir)$(Configuration)\`, for example `Client\Release\`). Copy `mmultiplayer.dll` next to `Launcher.exe` yourself.

The generated SDK makes the first build slow: `ME_TdGame_functions.cpp` and `ME_Engine_functions.cpp` are several megabytes each.

## Run

1. Put `mmultiplayer.dll` in the **same directory as `Launcher.exe`**. The launcher loads the DLL from its own folder. `build.sh` already puts both in `Release/`. If you installed the mod with the installer, it lives in `C:\Program Files\Mirror's Edge Multiplayer` (since 2.1.1). You can replace the DLL there instead, but keep a backup.
2. Start `Launcher.exe`, before or after the game.
3. Start Mirror's Edge. Until it does, the launcher shows "Waiting for Mirror's Edge to start. Click OK to stop." It polls every 50 ms for `MirrorsEdge.exe`. Once the game has loaded `d3d9.dll`, the launcher injects `mmultiplayer.dll` and exits. If the DLL is already loaded, the launcher exits without doing anything.
4. The menu opens at startup by default. Press **Insert** to toggle it and **Escape** to close it. The menu key can be rebound in the **Engine** tab.

The launcher opens the game process with `PROCESS_ALL_ACCESS`. If that fails, it shows "Failed to open a handle to the process". Try running the launcher as administrator.
<!-- TODO: verify whether administrator rights are normally required -->

## Iterating

The DLL can't be unloaded or reloaded in a running game; nothing tears down the hooks. To test a change:

1. Quit the game.
2. Rebuild.
3. Run the launcher and the game again.

Next: [Hello world](hello-world.md).
