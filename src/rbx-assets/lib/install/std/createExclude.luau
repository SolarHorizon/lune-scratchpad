local globrex = require("../std/globrex")
local roblox = require("@lune/roblox")

export type Options = {
	isA: { string }?,
	names: { string }?,
}?

type Matcher = (roblox.Instance) -> boolean

local function isA(instance: roblox.Instance, classes: { string })
	for _, class in classes do
		if instance:IsA(class) then
			return true
		end
	end

	return false
end

local function createExcludes(options: Options)
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

return createExcludes
