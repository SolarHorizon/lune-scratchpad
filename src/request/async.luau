local Error = require("./Error")
local Future = require("@lib/Future")
local Result = require("@lib/Result")

local sync = require("./sync")

type Error = Error.Error
type Future<T> = Future.Future<T>
type Result<T> = Result.Result<T, Error>

local function requestAsync(fetchParams): Future<Result<string>>
	return Future.new(sync, fetchParams)
end

return requestAsync
