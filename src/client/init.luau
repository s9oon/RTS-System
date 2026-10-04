-- Client half of the package. Call Client.start() once from a LocalScript.

local Remotes = require(script.Parent.shared.remotes)
local Camera = require(script.camera)
local Commands = require(script.commands)
local Selection = require(script.selection)

local Client = {}

Client.Camera = Camera
Client.Commands = Commands
Client.Selection = Selection

function Client.start()
	Commands.start(Remotes.wait())
	Selection.start()
	Camera.start()
end

return Client
