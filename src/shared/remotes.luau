-- The RemoteEvents clients use to ask the server for things. The server makes them, clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folderName = "RTSRemotes"
local remoteNames = { "SpawnMinion", "MoveMinions" }

local Remotes = {}

-- Server only, called once by Server.start.
function Remotes.create(): { [string]: RemoteEvent }
	local folder = Instance.new("Folder")
	folder.Name = folderName

	local remotes = {}
	for _, name in remoteNames do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remotes[name] = remote
	end

	folder.Parent = ReplicatedStorage
	return remotes
end

-- Client only, waits until the server has made them.
function Remotes.wait(): { [string]: RemoteEvent }
	local folder = ReplicatedStorage:WaitForChild(folderName)

	local remotes = {}
	for _, name in remoteNames do
		remotes[name] = folder:WaitForChild(name)
	end
	return remotes
end

return Remotes
