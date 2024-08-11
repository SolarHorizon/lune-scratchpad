local stdio = require("@lune/stdio")

local function errPrint(msg: string?, err: string?)
	local message = "\n"

	if msg then
		message = message .. stdio.color("red") .. msg .. "\n"
	end

	if err then
		message = message .. stdio.color("blue") .. err
	end

	stdio.ewrite(message .. "\n" .. stdio.color("reset"))
end

return errPrint
