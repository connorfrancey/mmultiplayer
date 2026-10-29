# Running console commands

[`Engine::ExecuteCommand`](../api-reference/engine-utilities.md#executecommand) runs a command through the game console (`UTdConsole::ConsoleCommand`), as if typed at the in-game console. The **Engine** tab's command box uses it.

```cpp
#include "../engine.h"

static void RestartLevel() {
    Engine::ExecuteCommand(L"open edge_p");
}
```

<!-- TODO: verify which console commands Mirror's Edge honours; `open <map>` is the standard UE3 command but isn't used anywhere in this repo -->

## It's queued

`ExecuteCommand` **doesn't run the command immediately**. It copies the string into a queue, which the framework drains at the start of the next engine tick (see [order within a tick](../concepts/callbacks-and-threads.md#order-within-a-tick)). That means:

- You can call it from any callback or thread. The queue is mutex-protected, and the string is copied, so a temporary is fine.
- It only drains **while a player pawn exists**. Commands queued in the main menu or during a load wait until a pawn appears.
- There's no return value and no output capture.

## From UTF-8 text

ImGui text input is UTF-8 and `ExecuteCommand` takes a wide string. Convert with `ConvertUtf8ToWideString` from `string_utils.h`, as the Engine tab does:

```cpp
#include "../engine.h"
#include "../string_utils.h"

static void Run(const char *utf8Command) {
    Engine::ExecuteCommand(ConvertUtf8ToWideString(utf8Command).c_str());
}
```

Example: [Hotkey command](../examples/hotkey-command.md)
