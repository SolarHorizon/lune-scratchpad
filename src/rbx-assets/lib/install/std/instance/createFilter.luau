local roblox = require("@lune/roblox")

local createMatcher = require("./createMatcher")
local safeDestroy = require("./safeDestroy")

export type Options = createMatcher.Options & {
	recursive: boolean,
}

local function createInstanceFilter(options: Options?)
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

return createInstanceFilter
