local getConfig = require("./getConfig")
local rojo = require("@lib/rojo")

local function run(name: string?)
	local config = getConfig()
	local project = rojo.Project.fromName(name or config.run.default)

	project:open()
end

return run
