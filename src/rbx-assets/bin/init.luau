local cli = require("../cli")
local dotenv = require("@lib/dotenv")
local stdio = require("@lune/stdio")

dotenv()

cli.run():match({
	Ok = function()
		return 0
	end,
	Err = function(err)
		stdio.ewrite(tostring(err))
		return 1
	end,
})
