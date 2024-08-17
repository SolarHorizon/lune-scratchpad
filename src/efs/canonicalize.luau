local Result = require("@lib/Result")
local process = require("@lune/process")

local Error = require("./Error")

local Ok = Result.Ok
local Err = Result.Err

local function canonicalize(path: string, spoofOs: string?)
	if (spoofOs or process.os) ~= "windows" then
		return Result.fromProcess("realpath", { path })
	end

	return Result.fromProcess(
		"powershell.exe",
		{ "-c", `(Resolve-Path -Path {path}).ToString()` }
	)
end

local function getCanonicalPath(path: string, spoofOs: string?)
	return canonicalize(path, spoofOs)
		:mapErr(function(err: process.SpawnResult)
			return Error.PathCanonicalize(path):append(`\n{err.stderr}`)
		end)
		:map(function(result: process.SpawnResult)
			local match = string.match(result.stdout, "(.-)[\r\n]")

			if not match then
				return Err(
					Error.PathCanonicalize(path):append(
						`\nFailed to trim carriage return and/or newline characters`
					)
				)
			end

			return Ok(match)
		end)
		:flatten()
end

return getCanonicalPath
