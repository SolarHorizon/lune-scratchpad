local stdio = require("@lune/stdio")

local function warn(msg: string)
	stdio.ewrite(
		stdio.color("yellow") .. tostring(msg) .. "\n" .. stdio.color("reset")
	)
end

return warn
