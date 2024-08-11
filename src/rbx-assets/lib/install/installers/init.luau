local childrenOf = require("./childrenOf")
local foldersIn = require("./foldersIn")
local workspaceAndLighting = require("./workspaceAndLighting")

return {
	default = workspaceAndLighting,
	workspaceAndLighting = workspaceAndLighting,
	foldersIn = foldersIn,
	childrenOf = childrenOf,
}
