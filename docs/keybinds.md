# Keybinds

Every key the library listens to is in `RTS.Keybinds`. Change one by setting it to a key name:

```lua
RTS.Keybinds.setDestination = "MouseButton2"
RTS.Keybinds.follow = "F"
```

Changes take effect straight away, before or after `RTS.Client.start()`.

## Defaults

| Keybind | Default | Does |
|---|---|---|
| `pan` | Left Shift + left click | Hold and drag to move the camera. |
| `follow` | Space | Locks the camera onto the oldest selected minion. |
| `spawn` | Right click | Spawns a minion at the mouse, if the game allows it. |
| `setDestination` | F | Moves the selected minions to the mouse. |

## Key names

Use the names from Roblox's [`Enum.KeyCode`](https://create.roblox.com/docs/reference/engine/enums/KeyCode), like `"F"`, `"Space"`, `"LeftShift"` or `"LeftControl"`. Single letters can be lowercase.

For mouse buttons use [`Enum.UserInputType`](https://create.roblox.com/docs/reference/engine/enums/UserInputType) names:

| Name | Button |
|---|---|
| `"MouseButton1"` | Left click |
| `"MouseButton2"` | Right click |
| `"MouseButton3"` | Middle click |

A name that doesn't exist prints a warning, e.g. `"Ctrl"` should be `"LeftControl"`.

## Combinations

A keybind can be a list of keys that all have to be held together:

```lua
RTS.Keybinds.pan = { "LeftControl", "MouseButton1" } -- Ctrl + left click
RTS.Keybinds.pan = "MouseButton3"                     -- Just middle click
```

A single key and a list with one key work the same. The keys in a combination can be pressed in any order.

## Using keybinds in your own code

```lua
UserInputService.InputBegan:Connect(function(input)
	if RTS.Keybinds.isPressed(input, "follow") then
		-- The follow key was just pressed.
	end
end)

if RTS.Keybinds.isHeld("pan") then
	-- Every key in the pan combination is held down right now.
end
```
