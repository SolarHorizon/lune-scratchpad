local roblox = require("@lune/roblox")

local createExclude = require("../std/createExclude")
local find = require("../std/find")
local sanitize = require("../std/sanitize")

type InstanceTree = roblox.Instance | {
	[string]: InstanceTree,
}

local function foldersIn(
	game: roblox.Instance,
	options: {
		roots: { [string]: string },
		recursive: boolean?,
		exclude: createExclude.Options,
	}
)
	local function collectFolders(
		root: roblox.Instance,
		recursive: boolean?
	): InstanceTree
		local exclude = createExclude(options.exclude)

		local folders = {}

		for _, instance in root:GetChildren() do
			if exclude(instance) then
				continue
			end

			local name = sanitize(instance.Name)

			if instance:IsA("Folder") then
				local exists = folders[name]

				if exists then
					print(
						`Skipping '{name}' because it already exists.`
							.. "Consider renaming any duplicate instances."
					)
					continue
				end

				if recursive then
					folders[name] = collectFolders(instance, recursive)
				else
					folders[name] = instance
				end
			end
		end

		return folders
	end

	local children = {}

	for name, path in options.roots do
		children[name] = collectFolders(find(game, path))
	end

	return children
end

return foldersIn
