local process = require("@lune/process")

local openers = {
	linux = { "xdg-open" },
	macos = { "open" },
	windows = { "powershell", "-c", "Start-Process" },
}

--[=[
	@within util
]=]
local function open(file: string): process.SpawnResult
	local opener = openers[process.os]

	if process.env.OPENER then
		opener = { process.env.OPENER }
	end

	local params = { table.insert(opener, 2) }

	table.insert(params, file)

	return process.spawn(opener[1], params)
end

return open
