local roblox = require("@lune/roblox")

local gt = require("../std/greentea")
local instance = require("../std/instance")
local text = require("../std/text")

type Instance = roblox.Instance

type InstanceTree = {
	[string]: Instance | InstanceTree,
}

local Options = gt.build({
	roots = gt.array(gt.string()),
	recursive = gt.opt(gt.boolean()),
	combineBehavior = gt.opt(
		gt.oneOf(gt.literal("error"), gt.literal("rename"))
	),
	exclude = gt.opt(gt.any()),
})

local function combine(behavior: string?, ...: InstanceTree)
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

local function foldersIn(game: roblox.Instance, options: typeof(Options:type()))
	local success, err = Options:matches(options)

	if not success then
		error(err:formatErr())
	end

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

	local root = {}

	for _, path in options.roots do
		local tree = collectFolders(instance.find(game, path))

		if typeof(tree) ~= "table" then
			warn("Non-folder instance at root", tree.ClassName, tree.Name)
			continue
		end

		root = combine(options.combineBehavior, root, tree)
	end

	return root
end

return foldersIn
