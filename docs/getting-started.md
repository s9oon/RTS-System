# Getting started

## Install

Add the package to your game's `wally.toml`:

```toml
[dependencies]
RTS = "s9oon/rts-system@0.1.0"
```

Then install it:

```bash
wally install
```

This puts the package in your game's `Packages/` folder. Make sure your Rojo project maps that folder to `ReplicatedStorage.Packages`, the usual Wally setup:

```json
"ReplicatedStorage": {
  "Packages": { "$path": "Packages" }
}
```

## Start it

The library doesn't run on its own. Your game starts it with two small scripts, one on each side.

**Server**, e.g. `ServerScriptService/RTS.server.luau`:

```lua
local ServerStorage = game:GetService("ServerStorage")
local RTS = require(game:GetService("ReplicatedStorage").Packages.RTS)

RTS.Server.start()

RTS.Server.defineMinion("Minion", { model = ServerStorage.Minion }) -- ServerStorage.Minion is any character model you put there.
RTS.Server.allowPlayerSpawning("Minion") -- Players can spawn Minions with the spawn key.
```

**Client**, e.g. `StarterPlayerScripts/RTS.client.luau`:

```lua
local RTS = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("RTS"))

RTS.Keybinds.setDestination = "MouseButton1" -- Optional: left click moves instead of F, see keybinds.md.

RTS.Client.start()
```

Call each `start()` once. Change keybinds before `RTS.Client.start()`, or at any time after, they take effect straight away.

## Recommended place settings

The RTS camera replaces the player's own view, so most games want:

- **Players.CharacterAutoLoads = false** if players shouldn't have a character of their own walking around.
- **Workspace.StreamingEnabled = false** for now. With streaming on, the client only loads the area around the player's character, so the camera shows nothing when the character is far away or missing. Streaming around the camera is planned.

## What's in the package

| | Side | Docs |
|---|---|---|
| `RTS.Server` | Server | [minions.md](minions.md) |
| `RTS.Client.Selection` | Client | [selection.md](selection.md) |
| `RTS.Client.Commands` | Client | [commands.md](commands.md) |
| `RTS.Client.Camera` | Client | [camera.md](camera.md) |
| `RTS.Keybinds` | Client | [keybinds.md](keybinds.md) |

## Try the demo

The repo has a demo place that uses the library the same way a game would. See [demo.md](demo.md).
