-- Dev place only, not shipped. Starts the package the same way a game would.

local ServerStorage = game:GetService("ServerStorage")

local RTS = require(game:GetService("ReplicatedStorage").Packages.RTS)

RTS.Server.start()

-- demo/models/MyCharacter.rbxmx, put in ServerStorage by dev.project.json.
-- Its idle and walk animations come from the Animate script inside it.
RTS.Server.defineMinion("Minion", { model = ServerStorage.MyCharacter })
RTS.Server.allowPlayerSpawning("Minion")
