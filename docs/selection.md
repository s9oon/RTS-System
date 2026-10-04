# Selection

`RTS.Client.Selection` holds which of the player's minions are selected, and their control groups. It lives only on the client: the server never sees it and other players can't either. Selected minions get a yellow outline only that player sees.

Only minions the player owns can be selected. Selecting anything else does nothing.

```lua
local Selection = RTS.Client.Selection
```

## Selecting

| | Description |
|---|---|
| `Selection.select(model)` | Adds a minion to the selection. |
| `Selection.deselect(model)` | Removes it. |
| `Selection.toggle(model)` | Selects it if it isn't, deselects it if it is. |
| `Selection.selectAll()` | Selects every minion the player owns. |
| `Selection.clear()` | Deselects everything. |
| `Selection.isSelected(model)` | `true` if it's selected. |
| `Selection.hasSelection()` | `true` if anything is selected. |
| `Selection.getSelected()` | The selected minion models, oldest first. |
| `Selection.getOwned()` | Every minion model the player owns, oldest first. |

## Control groups

Groups 1 to 9 each remember a set of minions.

| | Description |
|---|---|
| `Selection.saveGroup(group)` | Saves the current selection as the group. Saving an empty selection clears it. |
| `Selection.selectGroup(group)` | Replaces the selection with the group's minions. |
| `Selection.clearGroup(group)` | Empties the group. The minions and the selection stay as they are. |
| `Selection.getGroup(group)` | The group's minion models, oldest first. |

When a minion is removed, e.g. it dies, it's taken out of the selection and every group automatically.

## Reacting to changes

```lua
Selection.changed:Connect(function()
	print(#Selection.getSelected(), "selected")
end)
```

`changed` fires once after the player's minions, the selection or a group changes. Changes made in the same frame, like selecting a whole group, fire it once.

## Controls

How players select is up to each game, so the library doesn't bind any selection keys. Call these functions from your own input or UI: clicking minions, dragging a box, a unit panel, number keys for groups, whatever fits your game.

The demo has a simple example: G toggles the minion under the mouse, H selects all and J deselects all. See `demo/client/main.client.luau` and [demo.md](demo.md).
