local stdio = require("@lune/stdio")

local function style(name: stdio.Style)
	return function(str: any)
		return stdio.style(name) .. tostring(str) .. stdio.style("reset")
	end
end

return {
	bold = style("bold"),
	dim = style("dim"),
}
