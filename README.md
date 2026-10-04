# RTS System

## Overview

A modular and extensible RTS system for Roblox, designed with clean architecture and reusable components in mind. Distributed as a [Wally](https://wally.run) package.

- **Minions** from any character model, with idle and walk animations, owned and moved by the server.
- **Selection** and control groups 1 to 9, kept on each player's client.
- **Top-down camera** with drag to pan, scroll to zoom and following a minion.
- **Rebindable keys**, including key combinations.
- **Server checks** on every request, so players can only control their own minions.

## Install

```toml
# your game's wally.toml
[dependencies]
RTS = "s9oon/rts-system@0.2.1"
```

Run `wally install`, then make sure your Rojo project puts the `Packages` folder in ReplicatedStorage:

```json
"ReplicatedStorage": {
  "Packages": { "$path": "Packages" }
}
```

```lua
-- Server
local RTS = require(game:GetService("ReplicatedStorage").Packages.RTS)

RTS.Server.start()
-- "Minion" is the name you give this type. ServerStorage.Minion is any character model you put there.
RTS.Server.defineMinion("Minion", { model = game:GetService("ServerStorage").Minion })
RTS.Server.allowPlayerSpawning("Minion")
```

```lua
-- Client
local RTS = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("RTS"))

RTS.Client.start()
```

Right click spawns a Minion. Select minions with `RTS.Client.Selection` and press F to send them to the mouse, or call `RTS.Client.Commands.setDestination(position)` from your own code.

## Docs

- [Getting started](docs/getting-started.md): install, starting the library, recommended place settings
- [Minions](docs/minions.md): defining, spawning and controlling minions on the server
- [Selection](docs/selection.md): selecting minions and control groups
- [Commands](docs/commands.md): asking the server to spawn and move minions
- [Keybinds](docs/keybinds.md): every key and how to change it
- [Camera](docs/camera.md): pan, zoom and follow
- [Demo](docs/demo.md): running the demo place

## Development

```
src/                  the package, this is all that gets published
  init.luau           entry point, returns { Server, Client, Shared, Keybinds }
  server/             minions, spawning, remotes and their checks
  client/             camera, selection, commands, keybinds
  shared/             remotes and attribute names used by both sides
demo/                 the demo place's scripts and model, not published
docs/                 these docs
default.project.json  the package, used by games that install it
dev.project.json      the demo place
```

```bash
wally install
rojo serve dev.project.json
```

Publish a new version by bumping `version` in `wally.toml`, then `wally publish`.

## License

[MIT](LICENSE)
