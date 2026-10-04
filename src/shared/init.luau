-- Code used by both the server and client halves.

local Shared = {}

-- The Workspace folder every minion model lives in.
Shared.minionsFolderName = "RTSMinions"

-- Attributes the server sets on every minion model. They only replicate server to client,
-- so the client can read who owns a minion but changing them on the client does nothing.
Shared.attributes = {
	id = "RTSMinionId",
	owner = "RTSOwnerId", -- The owner's UserId, or 0 for minions with no owner.
	type = "RTSMinionType", -- The name it was defined with.
}

return Shared
