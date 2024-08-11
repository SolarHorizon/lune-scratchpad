local Future = require("@lib/Future")
local Result = require("@lib/Result")
local getAuthCookie = require("@lib/rbx-api/getAuthCookie")

local Error = require("../Error")

type Error = Error.Error
type Future<T> = Future.Future<T>
type Result<T> = Result.Result<T, Error>

--[=[
	@within rbx-api

	Wrap a request with an auth cookie
]=]
local function withCookie<T, U...>(
	f: (string, U...) -> Result<T>
): (string?, U...) -> Future<Result<T>>
	return function(override: string?, ...: U...)
		local args: { any } = table.pack(...)
		return Future.new(function()
			return getAuthCookie(override):andThen(function(cookie)
				return f(cookie, table.unpack(args))
			end)
		end)
	end
end

return withCookie
