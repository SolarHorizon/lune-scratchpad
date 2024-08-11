local roblox = require("@lune/roblox")

local createExclude = require("../std/createExclude")
local find = require("../std/find")
local sanitize = require("../std/sanitize")

local function childrenOf(
	game: roblox.DataModel,
	options: {
		roots: { [string]: string },
		exclude: createExclude.Options,
	}
)
	local exclude = createExclude(options.exclude)

	local allChildren = {}

	for dirName, path in options.roots do
		local root = find(game, path)

		local children = {}

		for _, instance in root:GetChildren() do
			if exclude(instance) then
				continue
			end

			local name = sanitize(instance.Name)

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
