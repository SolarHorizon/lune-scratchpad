local roblox = require("@lune/roblox")

local Result = require("@lib/Result")

local Error = require("./Error")

local Ok, Err = Result.Ok, Result.Err

type Error = Error.Error
type Result<T> = Result.Result<T, Error>

local function getAuthCookie(override: string?): Result<string>
	local cookie = override or roblox.getAuthCookie(true)

	if not cookie then
		return Err(Error.MissingAuthCookie())
	end

	return Ok(`.ROBLOSECURITY={cookie}; Domain=.roblox.com`)
end

return getAuthCookie
