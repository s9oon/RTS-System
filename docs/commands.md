# Commands

`RTS.Client.Commands` sends the player's requests to the server. They are only requests: the server checks each one and decides what happens (see [Security in minions.md](minions.md#security)).

| | Description |
|---|---|
| `Commands.spawn(position)` | Asks to spawn a minion. Only happens if the game called `allowPlayerSpawning` and the player owns fewer than 50 minions. |
| `Commands.move(models, position)` | Asks to move these minion models. Any the player doesn't own are ignored. |

```lua
local Commands = RTS.Client.Commands
local Selection = RTS.Client.Selection

Commands.move(Selection.getSelected(), Vector3.new(0, 0, 0))
```

## Built-in keys

The library already sends these for you:

| Keybind | Default | Does |
|---|---|---|
| `spawn` | Right click | `Commands.spawn` at the point under the mouse. |
| `setDestination` | F | `Commands.move` with the selected minions to the point under the mouse. |

Change them in [keybinds.md](keybinds.md). The point under the mouse ignores minions, so clicking on one targets the ground behind it.
