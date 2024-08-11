local clearLine = require("./clearLine")
local color = require("./color")
local eprint = require("./eprint")
local errPrint = require("./errPrint")
local style = require("./style")
local warn = require("./warn")

--[=[
	@class term
]=]
return {
	--selene:allow(bad_string_escape)
	clear = "\x1b[2K\r",
	clearLine = clearLine,
	color = color,
	eprint = eprint,
	errPrint = errPrint,
	style = style,
	warn = warn,
}
