-- One minion on the server. Made by RTS.Server.spawnMinion, which returns it so games can control it:
--
--   local knight = RTS.Server.spawnMinion("Knight", player, position)
--   knight:moveTo(target)
--   knight.died:Connect(function() ... end)

local Shared = require(script.Parent.Parent.shared)

local reachedDistance = 4 -- Stop retrying a move once the minion is this close to its target.
local walkThreshold = 0.5 -- Studs per second a minion must move to play its walk animation.
local walkAnimationSpeed = 16 -- The movement speed walk animations are made for, used to keep feet from sliding.

-- Minions only ever stand, walk and fall, so skip the physics checks for everything else.
local unusedHumanoidStates = {
	Enum.HumanoidStateType.Climbing,
	Enum.HumanoidStateType.Swimming,
	Enum.HumanoidStateType.Seated,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Ragdoll,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.Flying,
	Enum.HumanoidStateType.StrafingNoPhysics,
}

local Minion = {}
Minion.__index = Minion

local function loadAnimation(animator, animation, priority)
	if not animation then return nil end

	local track = animator:LoadAnimation(animation)
	track.Priority = priority
	return track
end

-- Internal, games use RTS.Server.spawnMinion instead.
function Minion.new(id: number, owner: Player?, typeName: string, definition, position: Vector3, parent: Instance)
	local model = definition.template:Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")

	local self = setmetatable({}, Minion)
	self.id = id
	self.owner = owner
	self.type = typeName
	self.model = model
	self.humanoid = humanoid
	self.target = nil :: Vector3?
	self._destroyed = false
	self._connections = {}

	-- Fires when the minion's health reaches 0, just before it's destroyed.
	self._diedEvent = Instance.new("BindableEvent")
	self.died = self._diedEvent.Event
	-- Fires when the minion is removed for any reason: dying, destroy() or falling out of the world.
	self._destroyedEvent = Instance.new("BindableEvent")
	self.destroyed = self._destroyedEvent.Event

	model.Name = typeName

	-- Set before parenting so clients see them as soon as the model appears.
	model:SetAttribute(Shared.attributes.id, id)
	model:SetAttribute(Shared.attributes.owner, if owner then owner.UserId else 0)
	model:SetAttribute(Shared.attributes.type, typeName)
	model:PivotTo(CFrame.new(position + Vector3.new(0, model:GetExtentsSize().Y / 2, 0)))
	model.Parent = parent

	-- Keep the physics on the server. Otherwise Roblox can hand it to a nearby player,
	-- who could then teleport or fling the minion however the remotes are checked.
	model.PrimaryPart:SetNetworkOwner(nil)

	humanoid.WalkSpeed = definition.walkSpeed
	for _, state in unusedHumanoidStates do
		humanoid:SetStateEnabled(state, false)
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	self._idleTrack = loadAnimation(animator, definition.animations.idle, Enum.AnimationPriority.Idle)
	self._walkTrack = loadAnimation(animator, definition.animations.walk, Enum.AnimationPriority.Movement)
	if self._idleTrack then
		self._idleTrack:Play()
	end

	-- MoveTo gives up after 8 seconds, so keep walking until the minion gets close to its target.
	table.insert(self._connections, humanoid.MoveToFinished:Connect(function(reached)
		if reached or not self.target then return end

		if (self:getPosition() - self.target).Magnitude > reachedDistance then
			humanoid:MoveTo(self.target)
		end
	end))

	table.insert(self._connections, humanoid.Died:Connect(function()
		self._diedEvent:Fire()
		self:destroy()
	end))

	-- Covers the model being destroyed by something else, e.g. a game script.
	table.insert(self._connections, model.Destroying:Connect(function()
		self:destroy()
	end))

	return self
end

-- Walks to the position, retrying until it gets there or is told to do something else.
function Minion:moveTo(position: Vector3)
	self.target = position
	self.humanoid:MoveTo(position)
end

-- Stops walking where it is.
function Minion:stop()
	self.target = nil
	self.humanoid:MoveTo(self:getPosition())
end

function Minion:getPosition(): Vector3
	return self.model:GetPivot().Position
end

-- Removes the minion and its model. Safe to call more than once.
function Minion:destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, connection in self._connections do
		connection:Disconnect()
	end
	self._destroyedEvent:Fire()
	self.model:Destroy()
end

-- Internal, called every frame by the server to play the walk animation while moving.
function Minion:_updateAnimation()
	local walkTrack = self._walkTrack
	if not walkTrack then return end

	local velocity = self.model.PrimaryPart.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local isWalking = speed > walkThreshold

	if isWalking and not walkTrack.IsPlaying then
		walkTrack:Play()
	elseif not isWalking and walkTrack.IsPlaying then
		walkTrack:Stop()
	end
	if isWalking then
		walkTrack:AdjustSpeed(speed / walkAnimationSpeed)
	end
end

return Minion
