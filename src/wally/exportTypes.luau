local Result = require("@lib/Result")

local fs = require("@lune/fs")

local replaceShims = require("./replaceShims")
local spawn = require("./spawn")

local Ok, Err = Result.Ok, Result.Err
local r = Result.from

type Result<T, E> = Result.Result<T, E>

local function isDir(dir: string)
	return r(fs.isDir, dir):isOkAnd(function(value)
		return value
	end)
end

local function exportTypes(packages, path, options)
	for _, dir in packages do
		if not isDir(dir) then
			continue
		end

		local result = spawn(
			"wally-package-types",
			{ "--sourcemap", `{path}/sourcemap.json`, dir },
			options
		)

		if result:isErr() then
			return Err(result:unwrapErr())
		end
	end

	for _, dir in packages do
		if not isDir(dir) then
			continue
		end

		local result = replaceShims({
			packagesPath = dir,
			projectPath = path,
		})

		if result:isErr() then
			return Err(result:unwrapErr())
		end
	end

	return Ok(true)
end

return exportTypes
