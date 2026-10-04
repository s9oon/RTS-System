-- The player's selected minions and control groups. This lives only on the client: the server never
-- needs it and other players can't see it. Moving the selection goes through Commands, which the server checks.
--
--   RTS.Client.Selection.select(model)
--   RTS.Client.Selection.saveGroup(3)
--   RTS.Client.Commands.move(RTS.Client.Selection.getSelected(), position)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = require(script.Parent.Parent.shared)

local outlineColor = Color3.fromRGB(255, 255, 0)
local fillTransparency = 0.7
local groupCount = 9

local Selection = {}

local ownedMinions = {} -- [Model] = true, every minion this player owns
local selectedMinions = {} -- [Model] = Highlight
local groups = {} -- [group number] = { [Model] = true }

local changedEvent = Instance.new("BindableEvent")
local changePending = false

-- Fires once after the player's minions, the selection or a group changes, e.g. to update a UI.
Selection.changed = changedEvent.Event

-- Batches changes made in the same frame, e.g. selecting a whole group, into one changed event.
local function notifyChanged()
	if changePending then return end
	changePending = true

	task.defer(function()
		changePending = false
		changedEvent:Fire()
	end)
end

-- Turns a { [Model] = true } set into a list, oldest minion first.
local function toSortedList(set)
	local models = {}
	for model in set do
		table.insert(models, model)
	end
	table.sort(models, function(a, b)
		return a:GetAttribute(Shared.attributes.id) < b:GetAttribute(Shared.attributes.id)
	end)
	return models
end

-- Selecting:
-- Outlines the minion and adds it to the selection. Minions the player doesn't own are ignored.
function Selection.select(model: Model)
	if selectedMinions[model] or not ownedMinions[model] then return end

	local highlight = Instance.new("Highlight")
	highlight.OutlineColor = outlineColor
	highlight.FillColor = outlineColor
	highlight.FillTransparency = fillTransparency
	highlight.Adornee = model
	highlight.Parent = model
	selectedMinions[model] = highlight
	notifyChanged()
end

function Selection.deselect(model: Model)
	local highlight = selectedMinions[model]
	if not highlight then return end

	highlight:Destroy()
	selectedMinions[model] = nil
	notifyChanged()
end

function Selection.toggle(model: Model)
	if selectedMinions[model] then
		Selection.deselect(model)
	else
		Selection.select(model)
	end
end

function Selection.clear()
	for model in selectedMinions do
		Selection.deselect(model)
	end
end

function Selection.selectAll()
	for model in ownedMinions do
		Selection.select(model)
	end
end

function Selection.isSelected(model: Model): boolean
	return selectedMinions[model] ~= nil
end

function Selection.hasSelection(): boolean
	return next(selectedMinions) ~= nil
end

-- Returns the selected minions, oldest first.
function Selection.getSelected(): { Model }
	return toSortedList(selectedMinions)
end

-- Returns every minion the player owns, oldest first.
function Selection.getOwned(): { Model }
	return toSortedList(ownedMinions)
end

-- Control groups:
-- Saves the current selection as this group (1-9). Saving an empty selection clears the group.
function Selection.saveGroup(group: number)
	assert(group >= 1 and group <= groupCount, `[RTS] Groups go from 1 to {groupCount}`)

	local members = {}
	for model in selectedMinions do
		members[model] = true
	end
	groups[group] = if next(members) then members else nil
	notifyChanged()
end

-- Replaces the selection with this group's minions.
function Selection.selectGroup(group: number)
	local members = groups[group]
	if not members then return end

	Selection.clear()
	for model in members do
		Selection.select(model)
	end
end

-- Empties this group, leaving the minions and the selection alone.
function Selection.clearGroup(group: number)
	if not groups[group] then return end

	groups[group] = nil
	notifyChanged()
end

-- Returns this group's minions, oldest first.
function Selection.getGroup(group: number): { Model }
	return toSortedList(groups[group] or {})
end

-- Tracking the player's minions:
-- The server sets the owner attribute before parenting, so it's already there when the minion appears.
local function onMinionAdded(model)
	if model:GetAttribute(Shared.attributes.owner) ~= Players.LocalPlayer.UserId then return end

	ownedMinions[model] = true
	notifyChanged()
end

-- Forgets minions when they're removed, e.g. when they die, including from the selection and groups.
local function onMinionRemoved(model)
	if not ownedMinions[model] then return end

	ownedMinions[model] = nil
	Selection.deselect(model)
	for group, members in groups do
		members[model] = nil
		if not next(members) then
			groups[group] = nil
		end
	end
	notifyChanged()
end

-- Called by Client.start.
function Selection.start()
	local folder = Workspace:WaitForChild(Shared.minionsFolderName)
	folder.ChildAdded:Connect(onMinionAdded)
	folder.ChildRemoved:Connect(onMinionRemoved)
	for _, model in folder:GetChildren() do
		onMinionAdded(model)
	end
end

return Selection
