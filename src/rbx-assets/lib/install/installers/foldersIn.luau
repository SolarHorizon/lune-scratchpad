local roblox = require("@lune/roblox")

local instance = require("../std/instance")
local text = require("../std/text")

type Instance = roblox.Instance

type InstanceTree = {
	[string]: Instance | InstanceTree,
}

type CombineBehavior = "error" | "rename"

local function combine(behavior: CombineBehavior?, ...: InstanceTree)
	local new = {}

	local unique = text.createUnique()

	for i = 1, select("#", ...) do
		for name, instance in select(i, ...) do
			if new[name] then
				if behavior == "error" then
					error(
						`Failed to combine trees because name '{name}' was already used.`
					)
				end
			end

			new[unique(name)] = instance
		end
	end

	return new
end

local function foldersIn(
	game: roblox.Instance,
	options: {
		roots: { [string]: { string } },
		recursive: boolean?,
		exclude: instance.FilterOptions?,
		combineBehavior: CombineBehavior?,
	}
)
	assert(
		typeof(options.roots) == "table",
		`Expected 'roots' to be an array of glob paths`
	)

	local function collectFolders(
		root: roblox.Instance,
		recursive: boolean?
	): InstanceTree
		local filter = instance.createFilter(options.exclude)

		local folders: InstanceTree = {}

		for _, child in filter(root):GetChildren() do
			local name = text.sanitize(child.Name)

			if child:IsA("Folder") then
				local exists = folders[name]

				if exists then
					print(
						`Skipping '{name}' because it already exists.`
							.. "Consider renaming any duplicate instances."
					)
					continue
				end

				if recursive then
					folders[name] = collectFolders(child, recursive)
				else
					folders[name] = child
				end
			end
		end

		return folders
	end

	local children = {}

	for name, paths in options.roots do
		local root = {}

		for _, path in paths do
			local tree = collectFolders(instance.find(game, path))

			if typeof(tree) ~= "table" then
				warn("Non-folder instance at root", tree.ClassName, tree.Name)
				continue
			end

			root = combine(options.combineBehavior, root, tree)
		end

		children[name] = root
	end

	return children
end

return foldersIn
