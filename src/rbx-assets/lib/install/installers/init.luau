local childrenOf = require("./childrenOf")
local foldersIn = require("./foldersIn")
local workspaceAndLighting = require("./workspaceAndLighting")

return {
	workspaceAndLighting = workspaceAndLighting,
	foldersIn = foldersIn,
	childrenOf = childrenOf,
}
