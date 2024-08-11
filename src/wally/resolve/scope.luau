local Result = require("@lib/Result")

local Ok, Err = Result.Ok, Result.Err

type Result<T, E> = Result.Result<T, E>

local function scope(str): Result<string, string>
	local match = string.match(str, "(.+)/")

	if match then
		return Ok(match)
	end

	return Err(`Could not match scope for {str}`)
end

return scope
