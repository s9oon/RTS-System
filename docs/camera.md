# Camera

`RTS.Client.start()` replaces the player's camera with a top-down RTS camera.

| Control | Does |
|---|---|
| `pan` keybind (Shift + left click), then drag | Moves the camera. The point you grabbed stays under the mouse. |
| Scroll wheel | Zooms in and out, between 15 and 150 studs above the ground. |
| `follow` keybind (Space) | Locks onto the oldest selected minion. Press it again on the same minion, or with nothing selected, to unlock. |

The camera stays locked until you press the follow key again or the followed minion is removed. Panning does nothing while it is locked.

## From code

```lua
local Camera = RTS.Client.Camera

Camera.follow(model)       -- Lock onto any model.
Camera.follow(nil)         -- Unlock.
Camera.getFollowTarget()   -- The model being followed, or nil.
```

The camera starts 60 studs up looking at the world origin. Its height limits and speeds aren't configurable.
