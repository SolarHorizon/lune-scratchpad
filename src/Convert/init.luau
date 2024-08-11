--- @class Convert

--- @prop Result ResultConversion
--- @within Convert

--- @prop Option OptionConversion
--- @within Convert

local Option = require("./Option")
local Result = require("./Result")

return {
	Option = Option,
	Result = Result,
}
