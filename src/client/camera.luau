-- Top-down RTS camera: drag to pan, scroll to zoom, and follow a unit.
-- The keys come from keybinds.luau, so games can rebind them.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Keybinds = require(script.Parent.keybinds)
local Selection = require(script.Parent.selection)

local startPosition = Vector3.new(0, 60, 40)
local startLookAt = Vector3.new(0, 0, 0)
local groundHeight = 0 -- Height of the flat plane the pan drags along.
local zoomStep = 5 -- Studs of height changed per scroll wheel tick.
local minHeight = 15
local maxHeight = 150
local followSmoothness = 10 -- How quickly the camera catches up to a followed unit, higher is snappier.

local Camera = {}

local camera = workspace.CurrentCamera
local cameraCFrame = CFrame.lookAt(startPosition, startLookAt)
local dragAnchor = nil -- The ground point grabbed when the pan started, or nil when not panning.
local followTarget = nil -- The model the camera is locked onto, or nil when not following.

-- Returns the point on the ground under the mouse, or nil if the mouse is aimed at the sky.
local function getGroundPointUnderMouse()
	local mousePosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	if ray.Direction.Y >= 0 then return nil end

	local distance = (groundHeight - ray.Origin.Y) / ray.Direction.Y
	return ray.Origin + ray.Direction * distance
end

-- Moves the camera along the direction it's looking, keeping its height within the zoom limits.
local function zoom(ticks)
	local lookVector = cameraCFrame.LookVector
	local height = cameraCFrame.Position.Y - groundHeight
	local newHeight = math.clamp(height - ticks * zoomStep, minHeight, maxHeight)

	local distance = (height - newHeight) / -lookVector.Y
	cameraCFrame += lookVector * distance
end

-- Slides the camera so the grabbed ground point stays under the mouse. Stops once the pan keys are let go.
local function updatePan()
	if not dragAnchor then return end
	if not Keybinds.isHeld("pan") then
		dragAnchor = nil
		return
	end

	local groundPoint = getGroundPointUnderMouse()
	if groundPoint then
		local offset = dragAnchor - groundPoint
		cameraCFrame += Vector3.new(offset.X, 0, offset.Z)
	end
end

-- Slides the camera towards the followed model, keeping the same angle and zoom.
local function updateFollow(deltaTime)
	if followTarget and not followTarget.Parent then
		followTarget = nil -- It was destroyed.
	end
	if not followTarget then return end

	local targetPosition = followTarget:GetPivot().Position
	local lookVector = cameraCFrame.LookVector
	local distance = (targetPosition.Y - cameraCFrame.Position.Y) / lookVector.Y
	local lookAtPoint = cameraCFrame.Position + lookVector * distance

	local offset = targetPosition - lookAtPoint
	local alpha = 1 - math.exp(-followSmoothness * deltaTime)
	cameraCFrame += Vector3.new(offset.X, 0, offset.Z) * alpha
end

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end

	if Keybinds.isPressed(input, "pan") then
		dragAnchor = getGroundPointUnderMouse()
		followTarget = nil -- Panning takes over from following.
	elseif Keybinds.isPressed(input, "follow") then
		-- Locks onto the oldest selected minion, switching straight to it if another one is being followed.
		-- Pressing it again on the minion already being followed, or with nothing selected, unlocks the camera.
		local minion = Selection.getSelected()[1]
		followTarget = if minion == followTarget then nil else minion
	end
end

local function onInputChanged(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoom(input.Position.Z)
	end
end

local function onRenderStep(deltaTime)
	-- Set every frame, since Roblox's default camera scripts can switch it back.
	camera.CameraType = Enum.CameraType.Scriptable

	updateFollow(deltaTime)
	updatePan()
	camera.CFrame = cameraCFrame
end

-- Takes over the player's camera. Called by Client.start.
function Camera.start()
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputChanged:Connect(onInputChanged)
	RunService:BindToRenderStep("RTSCamera", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
end

-- Locks the camera onto a model, or unlocks it when given nil.
function Camera.follow(model: Model?)
	followTarget = model
end

-- Returns the model the camera is locked onto, or nil.
function Camera.getFollowTarget(): Model?
	return followTarget
end

return Camera
