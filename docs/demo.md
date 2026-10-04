# Demo

The repo includes a small demo place that uses the library exactly the way a game would, through `RTS.Server`, `RTS.Client` and `RTS.Keybinds`. The demo isn't part of the Wally package, games that install the library don't get it.

## Running it

You need [Rojo](https://rojo.space) and [Wally](https://wally.run), both listed in `aftman.toml`.

```bash
wally install
rojo serve dev.project.json
```

Then in Roblox Studio, open an empty place, connect the Rojo plugin **in Edit mode**, and press Play.

Note `rojo serve dev.project.json`, not plain `rojo serve`. Plain `rojo serve` uses `default.project.json`, which is just the library on its own. After editing a `.project.json` file, restart `rojo serve` so it picks up the change.

## Controls

| Key | Does |
|---|---|
| Right click | Spawn a minion |
| G | Select or deselect the minion under the mouse |
| H | Select all your minions |
| J | Deselect all |
| F | Move the selected minions to the mouse |
| Space | Follow the oldest selected minion |
| Shift + left click drag | Pan the camera |
| Scroll | Zoom |

G, H and J are written in the demo's own script, `demo/client/main.client.luau`, as an example of building controls on `RTS.Client.Selection`. The rest come from the library.

## Files

| | |
|---|---|
| `dev.project.json` | The demo place: the library at `ReplicatedStorage.Packages.RTS`, the demo scripts, a baseplate and the minion model. |
| `demo/server/main.server.luau` | Starts the server, defines the minion and allows spawning. |
| `demo/client/main.client.luau` | Starts the client, sets keybinds and adds the G/H/J test keys. |
| `demo/models/` | The character model the demo's minions are copied from. |
