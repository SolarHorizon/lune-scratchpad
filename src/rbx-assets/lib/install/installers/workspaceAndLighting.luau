local roblox = require("@lune/roblox")

local createExclude = require("../std/createExclude")

local function workspaceAndLighting(
	game: roblox.DataModel,
	options: {
		exclude: createExclude.Options,
	}
)
	local exclude = createExclude(options.exclude)

	local workspace = game:GetService("Workspace")
	local lighting = game:GetService("Lighting")

	for _, child in workspace:GetDescendants() do
		if exclude(child) then
			child:Destroy()
		end
	end

	for _, child in lighting:GetDescendants() do
		if exclude(child) then
			child:Destroy()
		end
	end

	return {
		Workspace = workspace,
		Lighting = lighting,
	}
end

return workspaceAndLighting
