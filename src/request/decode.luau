local Result = require("@lib/Result")
local gt = require("@pkg/greentea")

local Error = require("./Error")

local Ok, Err = Result.Ok, Result.Err

type Error = Error.Error
type Result<T> = Result.Result<T, Error>

local function decode<T>(body: string, decoder: (string) -> T, type: T?): Result<T>
	return Result.from(decoder, body)
		:mapErr(function(err)
			return Error.ParseError(tostring(err)):meta({ body = body })
		end)
		:andThen(function(content)
			if type then
				local ok, err = gt.build(type):matches(content)

				if not ok then
					return Err(Error.MalformedResponse(err:formatErr()))
				end
			end

			return Ok(content)
		end)
end

return decode
