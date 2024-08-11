local Error = require("./Error")
local Result = require("@lib/Result")

type Result<T, E> = Result.Result<T, E>
type Error = Error.Error

local Ok, Err = Result.Ok, Result.Err

local TRUE_LITERALS = { "y", "yes", "t", "true", "on", "1" }
local FALSE_LITERALS = { "n", "no", "f", "false", "off", "0" }

return {
	bool = function(value)
		if value == "true" then
			return Ok(true)
		elseif value == "false" then
			return Ok(false)
		end

		return Err(Error.InvalidArgument(value))
	end,
	boolish = function(value)
		if table.find(TRUE_LITERALS, value) then
			return Ok(true)
		elseif table.find(FALSE_LITERALS, value) then
			return Ok(false)
		else
			return Err(Error.InvalidArgument(value))
		end
	end,
	number = function(value)
		local number = tonumber(value)

		if number then
			return Ok(number)
		end

		return Err(Error.InvalidArgument(value))
	end,
}
