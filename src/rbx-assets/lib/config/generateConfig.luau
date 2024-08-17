local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Result = require("@lib/Result")
local efs = require("@lib/efs")

local Error = require("../Error")
local constants = require("../constants")
local types = require("../types")

local Ok = Result.Ok
local Err = Result.Err

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type RawConfig = types.RawConfig

local PLACE_DEFAULT = {
	output = "./maps/default",
	installer = "@workspaceAndLighting",
	placeId = 0,
}

local FILE = constants.PROG_NAME

local DEFAULT_CONFIG = {
	places = {
		default = PLACE_DEFAULT,
	},
}

local function generateConfig(projectPath: string?): Result<RawConfig>
	local path = efs.normalizePath(`{projectPath or process.cwd}`)

	return Result.from(
		fs.writeFile,
		`{path}/{FILE}.yml`,
		serde.encode("yaml", DEFAULT_CONFIG)
	):match({
		Ok = function()
			return Ok(DEFAULT_CONFIG)
		end,
		Err = function(err)
			return Err(Error.ConfigWriteError(`{FILE}.yml`, tostring(err)))
		end,
	})
end

return generateConfig
