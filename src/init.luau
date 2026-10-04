-- Entry point of the package. Games require this module and call start on the half they need.

return {
	Server = require(script.server),
	Client = require(script.client),
	Shared = require(script.shared),
	Keybinds = require(script.client.keybinds),
}
