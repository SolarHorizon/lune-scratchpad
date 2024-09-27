local roblox = require("@lune/roblox")

local globrex = require("../text/globrex")
local gt = require("../greentea")

local Options = gt.build(gt.opt({
	isA = gt.opt(gt.array(gt.string())),
	names = gt.opt(gt.array(gt.string())),
}))

export type Options = typeof(Options:type())

type Matcher = (roblox.Instance) -> boolean

local function isA(instance: roblox.Instance, classes: { string })
	for _, class in classes do
		local success, isA = pcall(function()
			return instance:IsA(class)
		end)

		if success and isA then
			return isA
		end
	end

	return false
end

local function createMatcher(options: Options)
	local success, err = Options:matches(options)

	if not success then
		error(err:formatErr())
	end

	local matchers: { [string]: Matcher } = {}

	if options then
		if options.isA then
			function matchers.isA(instance)
				return isA(instance, options.isA)
			end
		end

		if options.names then
			local globs = {}

			for _, name in options.names do
				table.insert(globs, globrex(name))
			end

			function matchers.name(instance)
				for _, glob in globs do
					if glob.regex:isMatch(instance.Name) then
						return true
					end
				end

				return false
			end
		end
	end

	return function(instance)
		for _, match in matchers do
			if match(instance) then
				return true
			end
		end

		return false
	end
end

return createMatcher
