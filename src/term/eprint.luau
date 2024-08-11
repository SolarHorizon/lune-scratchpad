local stdio = require("@lune/stdio")

local function eprint(...)
	local str = "\n"

	for i = 1, select("#", ...) do
		str ..= tostring(select(i, ...)) .. " "
	end

	stdio.ewrite(str)
end

return eprint
