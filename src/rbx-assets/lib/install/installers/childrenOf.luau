local roblox = require("@lune/roblox")

local instance = require("../std/instance")
local text = require("../std/text")

local function childrenOf(
	game: roblox.DataModel,
	options: {
		roots: { [string]: string },
		exclude: instance.FilterOptions,
	}
)
	local filter = instance.createFilter(options.exclude)

	local allChildren = {}

	for dirName, path in options.roots do
		local root = filter(instance.find(game, path))

		local children = {}

		for _, instance in root:GetChildren() do
			local name = text.sanitize(instance.Name)

			if children[name] then
				print(
					`Skipping '{name}' because it already exists.`
						.. "Consider renaming any duplicate instances."
				)
				continue
			end

			children[name] = instance
		end

		allChildren[dirName] = children
	end

	return allChildren
end

return childrenOf
