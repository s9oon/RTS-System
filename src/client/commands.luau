-- Sends the player's commands to the server. These are only requests: the server checks each one
-- and decides what actually happens, so nothing here can control a minion the player doesn't own.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Keybinds = require(script.Parent.keybinds)
local Selection = require(script.Parent.selection)
local Shared = require(script.Parent.Parent.shared)

local Commands = {}

local remotes = nil
local raycastParams = RaycastParams.new()

-- Returns the point in the world under the mouse, ignoring minions, or nil if the mouse is aimed at the sky.
local function getMouseWorldPosition()
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = Workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, raycastParams)
	return result and result.Position
end

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	if Keybinds.isPressed(input, "spawn") then
		local position = getMouseWorldPosition()
		if position then
			Commands.spawn(position)
		end
	elseif Keybinds.isPressed(input, "setDestination") then
		local position = getMouseWorldPosition()
		if position then
			Commands.setDestination(position)
		end
	end
end

-- Called by Client.start.
function Commands.start(clientRemotes)
	remotes = clientRemotes

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { Workspace:WaitForChild(Shared.minionsFolderName) }

	UserInputService.InputBegan:Connect(onInputBegan)
end

-- Asks the server to spawn a minion. It only happens if the game allows player spawning and the player is under the limit.
function Commands.spawn(position: Vector3)
	remotes.SpawnMinion:FireServer(position)
end

-- Asks the server to move these minion models. The server ignores any the player doesn't own.
function Commands.move(models: { Model }, position: Vector3)
	local ids = {}
	for _, model in models do
		table.insert(ids, model:GetAttribute(Shared.attributes.id))
	end
	remotes.MoveMinions:FireServer(ids, position)
end

-- Moves the selected minions to the position, the same as pressing the setDestination key. Does nothing when nothing is selected.
function Commands.setDestination(position: Vector3)
	if not Selection.hasSelection() then return end

	Commands.move(Selection.getSelected(), position)
end

return Commands
