local stdio = require("@lune/stdio")

local function color(name: stdio.Color)
	return function(str: any)
		return stdio.color(name) .. tostring(str) .. stdio.color("reset")
	end
end

return {
	black = color("black"),
	blue = color("blue"),
	cyan = color("cyan"),
	green = color("green"),
	purple = color("purple"),
	red = color("red"),
	white = color("white"),
	yellow = color("yellow"),
}
