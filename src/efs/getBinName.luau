local Result = require("@lib/Result")

local normalizePath = require("./normalizePath")

type Result<T, E> = Result.Result<T, E>

local Ok, Err = Result.Ok, Result.Err

local function trim(str, pattern)
	return string.match(str, `^(.+){pattern}$`) or str
end

--[=[
	@within efs

	Returns the name of the script ran by the user.
]=]
local function getBinName(): Result<string, string>
	local path = string.match(debug.info(2, "s"), '%[string "([^"]*)"%]')

	if not path then
		return Err("Failed to get bin name")
	end

	return Ok(trim(normalizePath(path), "%.luau?"))
end

return getBinName
