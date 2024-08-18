local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Result = require("@lib/Result")
local efs = require("@lib/efs")
local immutable = require("@lib/immutable")

local Error = require("../Error")
local constants = require("../constants")
local types = require("../types")

type Error = Error.Error
type Result<T> = Result.Result<T, Error>
type Config = types.Config
type PlaceConfig = types.PlaceConfig
type InstallerConfig = types.InstallerConfig
type RawConfig = types.RawConfig
type RawPlaceConfig = types.RawPlaceConfig

local Ok = Result.Ok
local Err = Result.Err
local map = immutable.map
local merge = immutable.merge
local Config = types.Config
local RawConfig = types.RawConfig

local DEFAULT_INSTALLER = {
	script = "@workspaceAndLighting",
}

local PLACE_DEFAULT = {
	output = "./assets",
	installer = DEFAULT_INSTALLER,
}

local FILE_FORMATS: { [string]: any } = {
	toml = "toml",
	yml = "yaml",
	yaml = "yaml",
	json = "json",
}

local FILE = constants.PROG_NAME

local function createInstallerConfig(
	value: (string | InstallerConfig)?,
	defaultInstaller: InstallerConfig?
): InstallerConfig
	if not value then
		return defaultInstaller or DEFAULT_INSTALLER
	end

	if typeof(value) == "string" then
		return { script = value }
	end

	return value
end

local function createPlaceConfig(
	value: RawPlaceConfig,
	defaultInstaller: InstallerConfig?
): PlaceConfig
	return merge(merge(PLACE_DEFAULT, value), {
		installer = createInstallerConfig(value.installer or defaultInstaller),
	})
end

--[=[
	@within rbx-assets

	Gets the rbx-assets config from the `rbx-assets.yml` file found in the given directory.
	If no directory is given, uses the current working directory.
]=]
local function readConfig(projectPath: string?): Result<Config>
	local path = efs.normalizePath(`{projectPath or process.cwd}`)
	local file: string? = nil
	local format: serde.EncodeDecodeFormat

	for ext, fmt in FILE_FORMATS do
		local config = `{path}/{FILE}.{ext}`

		if fs.isFile(config) then
			file = config
			format = fmt
			break
		end
	end

	if not file then
		return Err(Error.NoConfig(`{FILE}`))
	end

	return Result.from(fs.readFile, file)
		:mapErr(function(err)
			return Error.ReadError(FILE, tostring(err))
		end)
		:andThen(function(content)
			return Result.from(serde.decode, format, content)
				:mapErr(function(err)
					return Error.ParseError(FILE):append("\n" .. tostring(err))
				end)
		end)
		:andThen(function(config)
			return Result.fromGtType(RawConfig, config):mapErr(function(err)
				return Error.InvalidConfig(err)
			end)
		end)
		:map(function(config: RawConfig)
			return merge({
				defaultInstaller = DEFAULT_INSTALLER,
				places = map(config.places, function(place)
					return createPlaceConfig(place, config.defaultInstaller)
				end),
			}, config)
		end)
		:andThen(function(config: Config)
			local usedOutputs = {}

			for name, place in config.places do
				if usedOutputs[place.output] then
					return Err(
						Error.ConflictingOutputConfig(
							name,
							usedOutputs[place.output]
						)
					)
				end

				usedOutputs[place.output] = name
			end

			return Ok(config)
		end)
		:andThen(function(config)
			return Result.fromGtType(Config, config):mapErr(function(err)
				return Error.InvalidConfig(err)
			end)
		end)
end

return readConfig
