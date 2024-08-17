local stdio = require("@lune/stdio")

local function log(...)
	print(stdio.color("cyan") .. "[debug]" .. stdio.color("reset"), ...)
end

local function dbg<T>(value: T, inspect: ((T) -> ...any)?): T
	if inspect then
		log(inspect(value))
	else
		log(value)
	end

	return value
end

return dbg
