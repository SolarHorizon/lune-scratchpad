local Result = require("@lib/Result")
local listAssetVersions = require("@lib/rbx-open-cloud/assets/listAssetVersions")

local Error = require("../Error")
local types = require("../types")

local Ok, Err = Result.Ok, Result.Err

type AssetVersions = listAssetVersions.AssetVersions
type Error = Error.Error
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

return placeConfigLock
