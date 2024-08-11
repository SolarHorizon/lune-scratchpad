local net = require("@lune/net")

local Result = require("@lib/Result")

local Error = require("./Error")

local Ok, Err = Result.Ok, Result.Err

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type FetchResponse = net.FetchResponse

local function requestSync(fetchParams): Result<string>
	return Result.from(net.request, fetchParams)
		:andThen(function(response: FetchResponse)
			if not response.ok then
				return Err(
					Error.HttpError(response.statusCode, response.statusMessage)
				)
			end

			return Ok(response.body)
		end)
end

return requestSync
