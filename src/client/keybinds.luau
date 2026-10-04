-- The keys the RTS camera uses. Games change them by setting a field to a key name:
--
--   RTS.Keybinds.pan = { "LeftControl", "MouseButton1" }
--   RTS.Keybinds.follow = "Space"
--
-- Key names are the names from Enum.KeyCode ("F", "Space", "LeftShift", "One")
-- or Enum.UserInputType for mouse buttons ("MouseButton1" is left click, "MouseButton2" is right click).

local UserInputService = game:GetService("UserInputService")

-- A keybind is one key name, or a list of key names that all have to be held together.
local Keybinds = {
	pan = { "LeftShift", "MouseButton1" }, -- Hold both and drag to move the camera.
	follow = "Space", -- Locks the camera onto the selected unit.
	spawn = "MouseButton2", -- Spawns a minion at the mouse position.
	setDestination = "F", -- Moves the selected minions to the mouse position.
}

-- Turns a key name like "F" or "MouseButton2" into its Enum item. Single letters can be lowercase.
local function toEnum(name)
	if typeof(name) == "EnumItem" then return name end
	if #name == 1 then name = name:upper() end

	local enum = Enum.KeyCode:FromName(name) or Enum.UserInputType:FromName(name)
	if not enum then
		warn(`[RTS] "{name}" isn't a key name, see Enum.KeyCode for the names that work`)
	end
	return enum
end

-- Returns the action's keys as a list of Enum items, so single keys and combinations are handled the same way.
local function getKeys(action)
	local bind = Keybinds[action]
	local names = if type(bind) == "table" then bind else { bind }

	local keys = {}
	for _, name in names do
		table.insert(keys, toEnum(name))
	end
	return keys
end

local function isKeyHeld(key)
	if key.EnumType == Enum.KeyCode then
		return UserInputService:IsKeyDown(key)
	end
	return UserInputService:IsMouseButtonPressed(key)
end

-- Returns true if this input is one of the keys and every other key is already held.
local function completes(input, keys)
	local pressedKey = nil
	for _, key in keys do
		if input.KeyCode == key or input.UserInputType == key then
			pressedKey = key
		end
	end
	if not pressedKey then return false end

	for _, key in keys do
		if key ~= pressedKey and not isKeyHeld(key) then
			return false
		end
	end
	return true
end

-- Returns true if every key in keys is also in otherKeys, and otherKeys has more, e.g. left click is part of Shift + left click.
local function isPartOf(keys, otherKeys)
	if #otherKeys <= #keys then return false end

	for _, key in keys do
		if not table.find(otherKeys, key) then
			return false
		end
	end
	return true
end

-- Returns true if this input completes the action, e.g. Keybinds.isPressed(input, "pan") when left click is pressed while Shift is held.
-- A longer combination wins over a shorter one inside it: with pan = Shift + left click and setDestination = left click,
-- Shift + left click only counts as pan.
function Keybinds.isPressed(input: InputObject, action: string): boolean
	local keys = getKeys(action)
	if not completes(input, keys) then return false end

	for otherAction, bind in Keybinds do
		local isBind = type(bind) == "string" or type(bind) == "table"
		if not isBind or otherAction == action then continue end

		local otherKeys = getKeys(otherAction)
		if isPartOf(keys, otherKeys) and completes(input, otherKeys) then
			return false
		end
	end
	return true
end

-- Returns true if all of the action's keys are held down right now, e.g. Keybinds.isHeld("pan").
function Keybinds.isHeld(action: string): boolean
	local keys = getKeys(action)
	if #keys == 0 then return false end -- Every key name was misspelled.

	for _, key in keys do
		if not isKeyHeld(key) then
			return false
		end
	end
	return true
end

return Keybinds
