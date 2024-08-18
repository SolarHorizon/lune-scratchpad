local cli = require("../cli")
local dotenv = require("@lib/dotenv")
local stdio = require("@lune/stdio")
local term = require("@lib/term")

dotenv()

cli.run():match({
	Ok = function()
		return 0
	end,
	Err = function(err)
		stdio.ewrite(term.color.red("[ERROR] ") .. tostring(err) .. "\n")
		return 1
	end,
})
