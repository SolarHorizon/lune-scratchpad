local stdio = require("@lune/stdio")

--[=[
	@deprecated v0 -- Use `stdio.write` with `term.clear` instead.
]=]
local function clearLine()
	--selene:allow(bad_string_escape)
	stdio.write("\x1b[2K\r")
end

return clearLine
