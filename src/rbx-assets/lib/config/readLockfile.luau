local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Option = require("@lib/Option")
local Result = require("@lib/Result")
local efs = require("@lib/efs")

local Error = require("../Error")
local types = require("../types")

type Option<T> = Option.Option<T>
type Result<T> = Result.Result<T, Error>
type Error = Error.Error
type Lockfile = types.Lockfile

local Ok = Result.Ok
local Some, None = Option.Some, Option.None

local Lockfile = types.Lockfile

local FILE = "rbx-assets.lock"

--[=[
	@within rbx-assets

	Gets the rbx-assets lockfile from the `rbx-assets.lock` file found in the given directory.
	If no directory is given, uses the current working directory.
]=]
local function readLockfile(projectPath: string): Result<Option<Lockfile>>
	local file = efs.normalizePath(`{projectPath}/{FILE}`)

	if not fs.isFile(file) then
		return Ok(None())
	end

	return Result.from(fs.readFile, file)
		:mapErr(function(err)
			return Error.ReadError(FILE, tostring(err))
		end)
		:andThen(function(content)
			return Result.from(serde.decode, "json" :: any, content)
				:mapErr(function(err)
					return Error.ParseError(FILE):append("\n" .. tostring(err))
				end)
		end)
		:andThen(function(lockfile)
			return Result.fromGtType(Lockfile, lockfile):mapErr(function(err)
				return Error.InvalidLockfile(err)
			end)
		end)
		:map(function(lockfile)
			return Some(lockfile)
		end)
end

return readLockfile
