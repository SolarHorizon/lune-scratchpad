local Result = require("@lib/Result")

local name = require("./name")
local scope = require("./scope")
local version = require("./version")

local Ok = Result.Ok

type Result<T, E> = Result.Result<T, E>

type PackageInfo<T> = {
	name: T,
	scope: T,
	version: T,
}

local function aggregate(
	map: PackageInfo<Result<string, string>>
): Result<PackageInfo<string>, string>
	local info: PackageInfo<string> = {} :: any

	for key: string, result: Result<string, string> in map :: any do
		if result:isOk() then
			info[key] = result:unwrap()
		else
			return result :: any
		end
	end

	return Ok(info)
end

local function all(str: string): Result<PackageInfo<string>, string>
	return aggregate({
		name = name(str),
		scope = scope(str),
		version = version(str),
	})
end

return all
