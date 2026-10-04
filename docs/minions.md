# Minions

Minions are created, owned and moved by the **server**. Clients can only ask to spawn or move them, and the server checks every request, so a player can never control a minion they don't own. All of the functions on this page are server only.

## Defining a minion type

Define each type once, after `RTS.Server.start()`, then spawn it by name as many times as you like.

```lua
RTS.Server.defineMinion("Minion", {
	model = ServerStorage.Minion,
	walkSpeed = 12,
	animations = {
		idle = "rbxassetid://123",
		walk = "rbxassetid://456",
	},
})
```

| Field | Required | Description |
|---|---|---|
| `model` | Yes | The model minions are copied from. See requirements below. |
| `walkSpeed` | No | Studs per second. Defaults to `16`. |
| `animations` | No | `idle` and `walk`, each an asset id (`"rbxassetid://123"` or `123`) or an `Animation`. Any left out are taken from the model's `Animate` script, which player avatars and most rigs have. |

### Model requirements

The model can be anything with:

- a **Humanoid**, which gives the minion walking, health and animations, and
- a **PrimaryPart**, usually its `HumanoidRootPart`.

Every Roblox character has both. `defineMinion` errors straight away if either is missing.

You don't need to clean up the model first: `LocalScript`s (like `Animate`) and `ForceField`s are removed from minions, and accessories are made non-colliding so hats don't get in the way.

To use a character as a model, press Play, select the character in Workspace, tick **Archivable** in Properties, then right click > **Save to File**. Characters aren't Archivable by default, so without that step the file comes out empty.

## Letting players spawn

```lua
RTS.Server.allowPlayerSpawning("Minion") -- The spawn key now spawns Minions.
RTS.Server.allowPlayerSpawning(nil)      -- Players can't spawn anything.
```

Player spawning is off until you call this. Each player can own up to **50** minions.

## Spawning from code

```lua
local minion = RTS.Server.spawnMinion("Minion", player, position)
```

- `owner` can be `nil` for minions no player controls, e.g. enemies.
- Spawning from code isn't affected by `allowPlayerSpawning` or the 50 minion limit.

## The minion object

`spawnMinion` returns a minion:

| | Description |
|---|---|
| `minion:moveTo(position)` | Walks there, retrying until it arrives or is told to do something else. |
| `minion:stop()` | Stops where it is. |
| `minion:getPosition()` | Its current position. |
| `minion:destroy()` | Removes it. Safe to call more than once. |
| `minion.died` | Event, fires when its health reaches 0, just before it's removed. |
| `minion.destroyed` | Event, fires when it's removed for any reason. |
| `minion.id` | Its unique number. |
| `minion.owner` | The owning `Player`, or `nil`. |
| `minion.type` | The name it was defined with. |
| `minion.model` | Its model in Workspace. |
| `minion.humanoid` | Its Humanoid. |

```lua
minion.died:Connect(function()
	print(minion.owner, "lost a minion")
end)
```

## Finding minions

```lua
RTS.Server.getMinion(id)         -- One minion by id, or nil.
RTS.Server.getMinions(player)    -- Every minion the player owns, oldest first.
```

## Animations

- **idle** loops while standing still.
- **walk** plays while moving, sped up or slowed down with the minion's speed so feet don't slide.

Jump, fall and custom animations aren't supported yet. Minions can still jump, they just keep their idle pose in the air.

## On the client

Minion models live in `Workspace.RTSMinions`. The server sets these attributes on each model, which clients can read:

| Attribute | Description |
|---|---|
| `RTSMinionId` | The minion's id. |
| `RTSOwnerId` | The owner's `UserId`, or `0` for no owner. |
| `RTSMinionType` | The name it was defined with. |

The names are also in `RTS.Shared.attributes` and the folder name in `RTS.Shared.minionsFolderName`.

## Security

Everything a client sends is checked on the server:

- Players can only move minions they own.
- Positions must be real `Vector3`s, not NaN, and within 10,000 studs of the world origin.
- Move requests are capped at 50 minion ids.
- Each player can send at most 10 requests per second.
- Minion physics stays on the server, so a nearby player can't take control of a minion's movement.
