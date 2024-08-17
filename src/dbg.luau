local stdio = require("@lune/stdio")

local function dbg<T...>(...: T...): T...
	print(stdio.color("cyan") .. "[debug]" .. stdio.color("reset"), ...)
	return ...
end

return dbg
