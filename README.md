# RTS System

Reusable RTS unit control system for Roblox, distributed as a [Wally](https://wally.run) package.

## Install

Add it to your game's `wally.toml`:

```toml
[dependencies]
RTS = "s9oon/rts-system@0.1.0"
```

Then run `wally install` and start it from your game:

```lua
-- ServerScriptService/RTS.server.luau
local RTS = require(game.ReplicatedStorage.Packages.RTS)
RTS.Server.start()
```

```lua
-- StarterPlayerScripts/RTS.client.luau
local RTS = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("RTS"))
RTS.Client.start()
```

## Development

```
src/                  the package, this is all that gets published
  init.luau           entry point, returns { Server, Client, Shared }
  server/ client/ shared/
demo/                 scripts for the dev place, not published
default.project.json  the package, used by games that install it
dev.project.json      a test place with the package and a baseplate
```

```bash
wally install
rojo serve dev.project.json
```

Publish a new version by bumping `version` in `wally.toml`, then `wally publish`.
