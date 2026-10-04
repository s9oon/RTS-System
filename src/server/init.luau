-- Server half of the package. Call Server.start() once from a server Script, then define minion types:
--
--   RTS.Server.start()
--   RTS.Server.defineMinion("Knight", { model = ServerStorage.Knight, walkSpeed = 12 })
--   RTS.Server.allowPlayerSpawning("Knight")
--
-- The server owns every minion. Clients can only ask to spawn or move them through the remotes,
-- and every request is checked here, so a player can never control a minion they don't own.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = require(script.Parent.shared)
local Remotes = require(script.Parent.shared.remotes)
local Minion = require(script.minion)

local maxMinionsPerPlayer = 50
local maxMapDistance = 10000 -- Ignore positions further than this from the world origin.
local maxRequestsPerSecond = 10 -- Per player, across all remotes.

local Server = {}

local started = false
local minionsFolder = nil
local definitions = {} -- [name] = { template: Model, walkSpeed: number, animations: { idle: Animation?, walk: Animation? } }
local minionsById = {} -- [id] = Minion
local minionsByOwner = {} -- [Player] = { [Minion] = true }
local nextMinionId = 0
local playerSpawnType = nil -- The minion type players can spawn with the spawn key, or nil if they can't.
local requestCounts = {} -- [Player] = { windowStart: number, count: number }

-- Checks:
local function isValidPosition(position)
	return typeof(position) == "Vector3"
		and position == position -- False when any component is NaN.
		and position.Magnitude < maxMapDistance
end

-- Returns true if the player has sent too many requests in the last second.
local function isRateLimited(player)
	local now = os.clock()
	local entry = requestCounts[player]
	if not entry or now - entry.windowStart >= 1 then
		requestCounts[player] = { windowStart = now, count = 1 }
		return false
	end

	entry.count += 1
	return entry.count > maxRequestsPerSecond
end

local function countOwned(player)
	local count = 0
	for _ in minionsByOwner[player] or {} do
		count += 1
	end
	return count
end

-- Definitions:
-- Accepts an asset id ("rbxassetid://123" or 123) or an Animation, and returns an Animation.
local function toAnimation(value, name)
	if value == nil then return nil end
	if typeof(value) == "Instance" and value:IsA("Animation") then return value end
	if type(value) == "number" then value = "rbxassetid://" .. value end
	if type(value) == "string" then
		local animation = Instance.new("Animation")
		animation.AnimationId = value
		return animation
	end
	error(`[RTS] The "{name}" animation must be an asset id or an Animation`, 3)
end

-- Takes an animation from the model's Animate script, which player avatars and most rigs have.
local function getAnimateAnimation(model, name)
	local animate = model:FindFirstChild("Animate")
	local folder = animate and animate:FindFirstChild(name)
	local animation = folder and folder:FindFirstChildWhichIsA("Animation")
	return animation and animation:Clone()
end

-- Copies the model into the template minions are cloned from, without anything that shouldn't run on a minion.
local function createTemplate(model)
	local wasArchivable = model.Archivable
	model.Archivable = true
	local template = model:Clone()
	model.Archivable = wasArchivable

	for _, descendant in template:GetDescendants() do
		if descendant:IsA("LocalScript") or descendant:IsA("ForceField") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") and descendant.Parent:IsA("Accessory") then
			-- Hats and hair are only visual, so keep them out of physics, touches and raycasts.
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
		end
	end
	return template
end

-- Defines a type of minion that can then be spawned by name. The model can be any model with a Humanoid
-- and a PrimaryPart. Animations are optional and taken from the model's Animate script when left out.
--
--   RTS.Server.defineMinion("Knight", {
--       model = ServerStorage.Knight,
--       walkSpeed = 12,
--       animations = { idle = "rbxassetid://123", walk = "rbxassetid://456" },
--   })
function Server.defineMinion(name: string, definition: { model: Model, walkSpeed: number?, animations: { idle: any, walk: any }? })
	assert(type(name) == "string", "[RTS] defineMinion needs a name")
	assert(not definitions[name], `[RTS] A minion called "{name}" is already defined`)

	local model = definition.model
	assert(typeof(model) == "Instance" and model:IsA("Model"), `[RTS] Minion "{name}" needs a model`)
	assert(model:FindFirstChildOfClass("Humanoid"), `[RTS] Minion "{name}"'s model needs a Humanoid to walk`)
	assert(model.PrimaryPart, `[RTS] Minion "{name}"'s model needs a PrimaryPart, usually its HumanoidRootPart`)

	local animations = definition.animations or {}
	definitions[name] = {
		template = createTemplate(model),
		walkSpeed = definition.walkSpeed or 16,
		animations = {
			idle = toAnimation(animations.idle, "idle") or getAnimateAnimation(model, "idle"),
			walk = toAnimation(animations.walk, "walk") or getAnimateAnimation(model, "walk"),
		},
	}
end

-- Lets players spawn this minion type with the spawn key, or stops them when given nil.
function Server.allowPlayerSpawning(name: string?)
	assert(name == nil or definitions[name], `[RTS] No minion called "{name}", define it with RTS.Server.defineMinion first`)
	playerSpawnType = name
end

-- Minions:
-- Spawns a minion of a defined type at the position. The owner can be nil for minions no player controls, e.g. enemies.
function Server.spawnMinion(name: string, owner: Player?, position: Vector3)
	assert(started, "[RTS] Call RTS.Server.start() before spawning minions")
	local definition = definitions[name]
	assert(definition, `[RTS] No minion called "{name}", define it with RTS.Server.defineMinion first`)
	assert(isValidPosition(position), "[RTS] spawnMinion needs a Vector3 position")

	nextMinionId += 1
	local minion = Minion.new(nextMinionId, owner, name, definition, position, minionsFolder)

	minionsById[minion.id] = minion
	if owner then
		minionsByOwner[owner] = minionsByOwner[owner] or {}
		minionsByOwner[owner][minion] = true
	end

	minion.destroyed:Connect(function()
		minionsById[minion.id] = nil
		if owner and minionsByOwner[owner] then
			minionsByOwner[owner][minion] = nil
		end
	end)

	return minion
end

function Server.getMinion(id: number)
	return minionsById[id]
end

-- Returns every minion the player owns, oldest first.
function Server.getMinions(owner: Player)
	local minions = {}
	for minion in minionsByOwner[owner] or {} do
		table.insert(minions, minion)
	end
	table.sort(minions, function(a, b)
		return a.id < b.id
	end)
	return minions
end

-- Remote requests:
-- The player asked to spawn a minion where they clicked.
local function onSpawnRequest(player, position)
	if isRateLimited(player) then return end
	if not playerSpawnType or not isValidPosition(position) then return end
	if countOwned(player) >= maxMinionsPerPlayer then return end

	Server.spawnMinion(playerSpawnType, player, position)
end

-- The player asked to move some minions. Any id that isn't a minion they own is ignored.
local function onMoveRequest(player, minionIds, position)
	if isRateLimited(player) then return end
	if typeof(minionIds) ~= "table" or not isValidPosition(position) then return end

	-- Only read the list part, up to the most minions a player can own, so a huge table can't lag the server.
	for index = 1, math.min(#minionIds, maxMinionsPerPlayer) do
		local id = minionIds[index]
		local minion = type(id) == "number" and minionsById[id]
		if minion and minion.owner == player then
			minion:moveTo(position)
		end
	end
end

local function onPlayerRemoving(player)
	requestCounts[player] = nil
	for minion in minionsByOwner[player] or {} do
		minion:destroy()
	end
	minionsByOwner[player] = nil
end

local function updateAnimations()
	for _, minion in minionsById do
		minion:_updateAnimation()
	end
end

-- Starts the server half. Call once, before defining or spawning minions.
function Server.start()
	assert(RunService:IsServer(), "[RTS] RTS.Server.start must be called from a server Script")
	assert(not started, "[RTS] RTS.Server.start was called more than once")
	started = true

	minionsFolder = Instance.new("Folder")
	minionsFolder.Name = Shared.minionsFolderName
	minionsFolder.Parent = Workspace

	local remotes = Remotes.create()
	remotes.SpawnMinion.OnServerEvent:Connect(onSpawnRequest)
	remotes.MoveMinions.OnServerEvent:Connect(onMoveRequest)

	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RunService.Heartbeat:Connect(updateAnimations)
end

return Server
