local roblox = require("@lune/roblox")

local createMatcher = require("./createMatcher")
local gt = require("../greentea")
local safeDestroy = require("./safeDestroy")

local Options = gt.build(gt.opt({
	recursive = gt.opt(gt.boolean()),
}))

export type Options = typeof(Options:type())

local function createFilter(options: Options)
	local success, err = Options:matches(options)

	if not success then
		error(err:formatErr())
	end

	local exclude = createMatcher(options)

	if not options then
		return function(root: roblox.Instance)
			return root
		end
	end

	return function(root: roblox.Instance)
		local search: { roblox.Instance } = if options.recursive
			then root:GetDescendants()
			else root:GetChildren()

		for _, child in search do
			if exclude(child) then
				safeDestroy(child)
			end
		end

		return root
	end
end

return createFilter
