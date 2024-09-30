local process = require("@lune/process")

local openers = {
	linux = { "xdg-open" },
	macos = { "open" },
	windows = { "explorer" },
}

--[=[
	@within util
]=]
local function open(file: string, args: { string }?): process.SpawnResult
	local opener = table.clone(openers[process.os])

	if process.env.OPENER then
		opener = { process.env.OPENER }
	end

	local program = table.remove(opener, 1) :: string

	local params = {}

	for _, param in opener do
		table.insert(params, param)
	end

	if args then
		for _, param in args do
			table.insert(params, param)
		end
	end

	table.insert(params, file)

	return process.spawn(program, params)
end

return open
