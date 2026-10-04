-- Dev place only, not shipped. Starts the package the same way a game would.

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local RTS = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("RTS"))

RTS.Keybinds.pan = { "LeftShift", "MouseButton1" }
RTS.Keybinds.setDestination = "F" -- Moves the selected minions to the mouse.

RTS.Client.start()

-- Games decide how players select minions. This is a simple example built on RTS.Client.Selection:
-- G toggles the minion under the mouse, H selects all, J deselects all.
local Selection = RTS.Client.Selection
local minionsFolder = Workspace:WaitForChild(RTS.Shared.minionsFolderName)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = { minionsFolder }

-- Returns the minion model under the mouse, or nil.
local function getMinionUnderMouse()
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = Workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, raycastParams)
	if not result then return nil end

	-- The hit is a body part, so climb up to the minion model directly inside the folder.
	local instance = result.Instance
	while instance.Parent ~= minionsFolder do
		instance = instance.Parent
	end
	return instance
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.G then
		local minion = getMinionUnderMouse()
		if minion then
			Selection.toggle(minion)
		end
	elseif input.KeyCode == Enum.KeyCode.H then
		Selection.selectAll()
	elseif input.KeyCode == Enum.KeyCode.J then
		Selection.clear()
	end
end)
