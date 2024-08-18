local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Future = require("@lib/Future")
local Iter = require("@lib/Iter")
local Option = require("@lib/Option")
local Result = require("@lib/Result")
local immutable = require("@lib/immutable")
local listAssetVersions = require("@lib/rbx-open-cloud/assets/listAssetVersions")

local Error = require("../Error")
local constants = require("../constants")
local readConfig = require("./readConfig")
local readLockfile = require("./readLockfile")
local types = require("../types")

local Ok = Result.Ok
local Err = Result.Err
local mergeDeep = immutable.mergeDeep

type AssetVersions = listAssetVersions.AssetVersions
type Config = types.Config
type Error = Error.Error
type Future<T> = Future.Future<T>
type Iter<K, V> = Iter.Iter<K, V>
type Lockfile = types.Lockfile
type Option<T> = Option.Option<T>
type PlaceConfig = types.PlaceConfig
type PlaceLock = types.PlaceLock
type Result<T> = Result.Result<T, Error>

local function placeConfigLock(
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
				output = place.output,
			}
		end)
end

local function createNewLock(
	apiKey: string,
	config: Config,
	places: Option<Iter<any, string>>
): Result<Lockfile>
	local selected = places
		:map(function(iter: Iter<any, string>)
			return iter:fold({}, function(accum, _, name)
				accum[name] = config.places[name]
				return accum
			end)
		end)
		:unwrapOr(config.places)

	local futures = {}

	for name, place in selected do
		futures[name] = listAssetVersions(apiKey, place.placeId)
	end

	local lockedPlaces = {}

	for name, result in Future.awaitAll(futures) do
		local place =
			placeConfigLock(config.places[name], result :: Result<AssetVersions>)

		if place:isOk() then
			lockedPlaces[name] = place:unwrap()
		else
			return place:mapErr(function(err)
				return Error.GetPlaceVersionError(name, tostring(err))
			end) :: any
		end
	end

	return Ok({
		defaultInstaller = config.defaultInstaller,
		places = lockedPlaces,
	})
end

local function mergeLockfile(
	projectPath: string,
	lockfile: Lockfile
): Result<Lockfile>
	return readLockfile(projectPath):map(function(option: Option<Lockfile>)
		return option
			:map(function(old: Lockfile)
				return mergeDeep(old, lockfile)
			end)
			:unwrapOr(lockfile)
	end)
end

local function generateLockfile(
	apiKey: string,
	projectPath: string,
	places: Option<Iter<any, string>>
): Future<Result<Lockfile>>
	return Future.new(function()
		return readConfig(projectPath)
			:andThen(function(config)
				return createNewLock(apiKey, config, places)
			end)
			:andThen(function(lockfile: Lockfile)
				return mergeLockfile(projectPath, lockfile)
			end)
			:inspect(function(lockfile: Lockfile)
				fs.writeFile(constants.LOCKFILE, serde.encode("json", lockfile))
			end)
	end)
end

return generateLockfile
