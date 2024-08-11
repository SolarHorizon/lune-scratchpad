local Result = require("@lib/Result")

local Ok, Err = Result.Ok, Result.Err

type Result<T, E> = Result.Result<T, E>

local function name(str): Result<string, string>
	local match = string.match(str, "/(.+)@")

	if match then
		return Ok(match)
	end

	return Err(`Could not match version for {str}`)
end

return name
