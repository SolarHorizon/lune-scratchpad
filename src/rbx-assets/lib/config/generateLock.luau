local Future = require("@lib/Future")
local Option = require("@lib/Option")
local Result = require("@lib/Result")
local listAssetVersions = require("@lib/rbx-open-cloud/assets/listAssetVersions")

local Error = require("../Error")
local readConfig = require("./readConfig")
local types = require("../types")

local Ok, Err = Result.Ok, Result.Err

type Result<T> = Result.Result<T, Error>
type Future<T> = Future.Future<T>
type Option<T> = Option.Option<T>
type Error = Error.Error
type Config = types.Config
type PlaceConfig = types.PlaceConfig
type PlaceLock = types.PlaceLock
type Lockfile = types.Lockfile
type AssetVersions = listAssetVersions.AssetVersions

local function intoPlaceLock(
	place: PlaceConfig,
	versions: Result<AssetVersions>
): Result<PlaceLock>
	return versions
		:andThen(function(assetVersions: AssetVersions)
			local path = assetVersions.assetVersions[1].path
			local version = tonumber(string.match(path, "^.*/(.+)$"))

			if not version then
				return Err(Error.InvalidPlaceVersionPath(path))
			end

			return Ok(version)
		end)
		:map(function(version: number): typeof(types.PlaceLock)
			return {
				placeId = place.placeId,
				installer = place.installer,
				version = version,
			}
		end)
end

local function createNewLock(apiKey: string, config: Config)
	local futures = {}

	for name, place in config.places do
		futures[name] = listAssetVersions(apiKey, place.placeId)
	end

	local places = {}

	for name, result in Future.awaitAll(futures) do
		local place =
			intoPlaceLock(config.places[name], result :: Result<AssetVersions>)

		if place:isOk() then
			places[name] = place:unwrap()
		else
			return place:mapErr(function(err)
				return Error.GetPlaceVersionError(name, tostring(err))
			end) :: any
		end
	end

	return Ok({
		places = places,
	})
end

local function generateLock(
	apiKey: string,
	projectPath: string?
): Future<Result<Lockfile>>
	return Future.new(function()
		return readConfig(projectPath):andThen(function(config)
			return createNewLock(apiKey, config)
		end)
	end)
end

return generateLock
