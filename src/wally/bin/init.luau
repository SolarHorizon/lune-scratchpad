local process = require("@lune/process")
local wally = require("@lib/wally")

local createAliases = process.args[1] == "-a"

wally.install({
	pretty = true,
	createAliases = createAliases,
})
