local roblox = require("@lune/roblox")

local gt = require("@pkg/greentea")
local instance = require("../std/instance")

local Options = gt.build({
	roots = gt.array(gt.string()),
	exclude = gt.opt(gt.any()) :: instance.FilterOptions,
})

local function selection(root: roblox.Instance, options: typeof(Options:type()))
	local filter =
		instance.createFilter(if options then options.exclude else nil)

	local tree = {}

	for name, path in options.roots do
		tree[name] = filter(instance.find(root, path))
	end

	return tree
end

return selection
