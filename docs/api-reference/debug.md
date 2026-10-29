# Debug

**Header:** `Client/debug.h` · **Namespace:** `Debug`

A Win32 console for `printf` output, plus a crash handler.

## `ToggleConsole` / `CreateConsole` / `CloseConsole`

```cpp
void ToggleConsole();
void CreateConsole();
void CloseConsole();
```

- `CreateConsole()` calls `AllocConsole()` and reopens `stdin`, `stdout` and `stderr` on it. Anything you `printf` afterwards appears there.
- `CloseConsole()` frees it and points the streams at `NUL:`.
- `ToggleConsole()` switches between the two. The **Engine** tab's **Debug Console** button calls it.

Output written before the console is opened is lost. By convention, prefix messages with your addon name, as the built-in addons do (`printf("client: ...\n")`).

```cpp
#include <cstdio>

static void Log() {
    printf("myaddon: hello\n");
}
```

Since 2.3.0, closing the console window this way no longer closes the game. Closing it with the window's **X** button may still end the process. <!-- TODO: verify -->

**Edge case:** `IsConsoleOpened` is declared `static` in the header, so every file that includes `debug.h` gets its own copy. Only the copy in `debug.cpp` is meaningful; don't read it from addon code.

## Crash handler

`Debug::Initialize()` (framework-internal) installs an unhandled-exception filter, stops anything else from replacing it, and also hooks the game's own crash path. On a crash, when **no debugger is attached**, it:

1. suspends all other threads and destroys the game window;
2. opens a console and prints the faulting address as `module+offset`, the exception code, the registers, and every stack value that points into a loaded module;
3. asks you to report the crash at `https://github.com/softsoundd/mmultiplayer/issues`, waits for a key, and exits with code 1.

With a debugger attached, the exception goes to the debugger. That makes Visual Studio's **Debug > Attach to Process** the best way to debug an addon crash. See [Troubleshooting](../troubleshooting.md#the-game-closes-and-a-console-shows-an-unhandled-exception-occured-at).
